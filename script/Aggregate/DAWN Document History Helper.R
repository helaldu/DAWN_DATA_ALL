# DAWN Document History Helper
# ----------------------------
# This helper downloads deeper line-level document history from DAWN pages like:
#   prc_doc_hist?list_trans_code=JVD&list_trans_agency=130&list_trans_number=MBT2601%2DC2&list_option=1
#
# It is designed to run after a revenue-account CSV has been downloaded.
# Input rows must include at least:
#   Doc Number, BA Number, GL Number
#
# Output rows include the original transaction identifiers plus DAWN's document
# history detail columns such as Appr, BS/Obj/Rev, Line #/Desc, and Amount.

required_packages <- c("rvest", "data.table", "stringr", "purrr")
missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]

if (length(missing_packages) > 0) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    ". Install them first, then rerun this script.",
    call. = FALSE
  )
}

library(rvest)
library(data.table)
library(stringr)
library(purrr)

parse_doc_number <- function(doc_number) {
  doc_number <- str_squish(as.character(doc_number))
  parts <- str_split(doc_number, "\\s+", n = 3, simplify = TRUE)

  if (ncol(parts) < 3 || any(parts[1, 1:3] == "")) {
    return(data.table(
      trans_code = NA_character_,
      trans_agency = NA_character_,
      trans_number = NA_character_
    ))
  }

  data.table(
    trans_code = parts[1, 1],
    trans_agency = parts[1, 2],
    trans_number = parts[1, 3]
  )
}

parse_currency <- function(value) {
  value <- str_squish(as.character(value))
  value[value == ""] <- NA_character_
  as.numeric(str_replace_all(value, "[^0-9.-]", ""))
}

download_document_history_one <- function(trans_code, trans_agency, trans_number) {
  if (any(is.na(c(trans_code, trans_agency, trans_number)))) {
    return(NULL)
  }

  url <- paste0(
    "http://dawn12.state.nv.us:7778/pls/prodsw/prc_doc_hist?",
    "list_trans_code=", URLencode(trans_code, reserved = TRUE),
    "&list_trans_agency=", URLencode(trans_agency, reserved = TRUE),
    "&list_trans_number=", URLencode(trans_number, reserved = TRUE),
    "&list_option=1"
  )

  tryCatch(
    {
      tables <- read_html(url) |>
        html_table(fill = TRUE)

      detail_tables <- keep(
        tables,
        ~ all(c("AcctType", "PostingCD", "Fund", "Appr", "BS/Obj/Rev", "Amount") %in% names(.x))
      )

      if (length(detail_tables) == 0) {
        stop("No document-history detail table found")
      }

      detail_data <- as.data.table(detail_tables[[1]])
      detail_data <- detail_data[
        !is.na(AcctType) &
          str_trim(AcctType) != "" &
          AcctType != "Total Amount"
      ]

      detail_data[
        ,
        `:=`(
          trans_code = trans_code,
          trans_agency = trans_agency,
          trans_number = trans_number,
          detail_amount = parse_currency(Amount),
          source_url = url
        )
      ]

      detail_data
    },
    error = function(e) {
      message(
        "Error downloading document history for ",
        trans_code, " ", trans_agency, " ", trans_number,
        ": ", conditionMessage(e)
      )
      NULL
    }
  )
}

run_dawn_document_history_download <- function(
    input_file,
    output_file,
    target_ba_numbers = NULL,
    target_gl_numbers = NULL,
    target_doc_numbers = NULL,
    max_documents_to_download = Inf) {
  if (!file.exists(input_file)) {
    stop("Input revenue file not found: ", input_file, call. = FALSE)
  }

  transactions <- fread(input_file)

  required_columns <- c("Doc Number", "BA Number", "GL Number")
  missing_columns <- setdiff(required_columns, names(transactions))

  if (length(missing_columns) > 0) {
    stop(
      "Input file is missing expected column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.null(target_ba_numbers)) {
    transactions <- transactions[`BA Number` %in% target_ba_numbers]
  }

  if (!is.null(target_gl_numbers)) {
    transactions <- transactions[`GL Number` %in% target_gl_numbers]
  }

  if (!is.null(target_doc_numbers)) {
    transactions <- transactions[`Doc Number` %in% target_doc_numbers]
  }

  transactions <- unique(transactions, by = "Doc Number")

  if (is.finite(max_documents_to_download)) {
    transactions <- head(transactions, max_documents_to_download)
  }

  if (nrow(transactions) == 0) {
    stop("No transactions matched the selected BA/GL/doc filters.", call. = FALSE)
  }

  doc_parts <- rbindlist(lapply(transactions[["Doc Number"]], parse_doc_number))
  transactions <- cbind(transactions, doc_parts)
  transactions <- transactions[!is.na(trans_code) & !is.na(trans_agency) & !is.na(trans_number)]

  message("Downloading document history for ", nrow(transactions), " unique document(s).")

  detail_data <- pmap_dfr(
    list(
      transactions[["trans_code"]],
      transactions[["trans_agency"]],
      transactions[["trans_number"]]
    ),
    ~ download_document_history_one(..1, ..2, ..3)
  ) |>
    as.data.table()

  if (nrow(detail_data) == 0) {
    stop("No document-history detail rows were downloaded.", call. = FALSE)
  }

  document_keys <- transactions[
    ,
    .(
      `Doc Number`,
      `BA Number`,
      `GL Number`,
      source_transaction_date = Date,
      source_transaction_amount = Amount,
      source_description = description,
      source_type = Type,
      source_fy = fy,
      trans_code,
      trans_agency,
      trans_number
    )
  ]

  detail_data <- merge(
    detail_data,
    document_keys,
    by = c("trans_code", "trans_agency", "trans_number"),
    all.x = TRUE
  )

  setcolorder(
    detail_data,
    c(
      "Doc Number",
      "BA Number",
      "GL Number",
      "source_transaction_date",
      "source_transaction_amount",
      "source_description",
      "source_type",
      "source_fy",
      "trans_code",
      "trans_agency",
      "trans_number",
      "AcctType",
      "Event Type",
      "PostingCD",
      "Fund",
      "Dept/Act/SubAct",
      "Appr",
      "Reporting",
      "BS/Obj/Rev",
      "Sub",
      "Task",
      "Function",
      "RptCat",
      "Ref Doc/Line",
      "Line #/Desc",
      "Comments/Invoice",
      "Amount",
      "detail_amount",
      "source_url"
    )
  )

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  fwrite(detail_data, output_file)
  message("Saved ", nrow(detail_data), " detail row(s) to ", output_file)

  invisible(detail_data)
}
