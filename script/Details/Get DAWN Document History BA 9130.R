script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(script_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (file.exists("DAWN Document History Helper.R")) {
  normalizePath(getwd())
} else if (file.exists(file.path("script", "Details", "DAWN Document History Helper.R"))) {
  normalizePath(file.path(getwd(), "script", "Details"))
} else {
  stop("Could not find DAWN Document History Helper.R. Run this script from the project root or script folder.", call. = FALSE)
}

# Scripts are stored in script/Details, while data files live at the project root.
project_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
data_dir <- file.path(project_dir, "data")

source(file.path(script_dir, "DAWN Document History Helper.R"))

# Edit these values if needed:
# - target_ba_numbers: BA Number(s) to download detail for.
# - target_gl_numbers: GL Number(s) to restrict to. Use NULL for all GLs.
# - target_doc_numbers: specific Doc Number(s). Use NULL for all documents.
# - max_documents_to_download: use a small number for testing, Inf for full run.
run_dawn_document_history_download(
  input_file = file.path(data_dir, "dawn_revenue_accounts_9130_history.csv"),
  output_file = file.path(data_dir, "dawn_document_history_9130_detail.csv"),
  target_ba_numbers = c(9130),
  target_gl_numbers = NULL,
  target_doc_numbers = NULL,
  max_documents_to_download = Inf
)
