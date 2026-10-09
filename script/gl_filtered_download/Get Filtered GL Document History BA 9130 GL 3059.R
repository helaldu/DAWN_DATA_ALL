# Download deeper DAWN document-history detail for BA 9130 / GL 3059
# ------------------------------------------------------------------
# Use this script when you only need the line-level prc_doc_hist detail for
# GL 3059 under BA 9130. It reads the filtered revenue CSV and writes a separate
# detail CSV so the all-BA detailed output and the targeted check can coexist.
#
# To reuse for another BA/GL pair, change target_ba_numbers, target_gl_numbers,
# and the output file name below.

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(script_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (file.exists("Filtered GL Document History Helper.R")) {
  normalizePath(getwd())
} else if (file.exists(file.path("script", "gl_filtered_download", "Filtered GL Document History Helper.R"))) {
  normalizePath(file.path(getwd(), "script", "gl_filtered_download"))
} else {
  stop("Could not find Filtered GL Document History Helper.R. Run this script from the project root or filtered script folder.", call. = FALSE)
}

project_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
aggregate_script_dir <- file.path(project_dir, "script", "Aggregate")
detail_script_dir <- file.path(project_dir, "script", "Details")
data_dir <- file.path(project_dir, "data_filtered_gl")

source(file.path(detail_script_dir, "DAWN Document History Helper.R"))
source(file.path(script_dir, "Filtered GL Revenue Download Helper.R"))
source(file.path(script_dir, "Filtered GL Document History Helper.R"))

run_filtered_gl_document_history_download(
  input_file = file.path(data_dir, "filtered_gl_revenue_accounts_history.csv"),
  output_file = file.path(data_dir, "filtered_gl_document_history_9130_3059.csv"),
  target_ba_numbers = 9130,
  gl_codes = 3059,
  max_documents_to_download = Inf
)