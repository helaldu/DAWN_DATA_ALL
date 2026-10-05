script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(script_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (file.exists("DAWN Document History Helper.R")) {
  normalizePath(getwd())
} else if (file.exists(file.path("script", "DAWN Document History Helper.R"))) {
  normalizePath(file.path(getwd(), "script"))
} else {
  stop("Could not find DAWN Document History Helper.R. Run this script from the project root or script folder.", call. = FALSE)
}

project_dir <- if (basename(script_dir) == "script") {
  normalizePath(file.path(script_dir, ".."), mustWork = FALSE)
} else {
  script_dir
}
data_dir <- file.path(project_dir, "data")

source(file.path(script_dir, "DAWN Document History Helper.R"))

# Deeper prc_doc_hist download for BA 9707.
# Keeps regular revenue output separate from document-history detail output.
run_dawn_document_history_download(
  input_file = file.path(data_dir, "dawn_revenue_accounts_9707_history.csv"),
  output_file = file.path(data_dir, "dawn_document_history_9707_detail.csv"),
  target_ba_numbers = c(9707),
  target_gl_numbers = NULL,
  target_doc_numbers = NULL,
  max_documents_to_download = Inf
)
