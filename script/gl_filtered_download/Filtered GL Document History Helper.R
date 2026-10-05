# Filtered GL Document History Helper
# -----------------------------------
# Runs the deeper prc_doc_hist download for the same filtered GL list used by
# Filtered GL Revenue Download Helper.R.

run_filtered_gl_document_history_download <- function(
    input_file,
    output_file,
    target_ba_numbers = NULL,
    gl_codes = filtered_gl_codes,
    target_doc_numbers = NULL,
    max_documents_to_download = Inf) {
  run_dawn_document_history_download(
    input_file = input_file,
    output_file = output_file,
    target_ba_numbers = target_ba_numbers,
    target_gl_numbers = sort(unique(as.integer(gl_codes))),
    target_doc_numbers = target_doc_numbers,
    max_documents_to_download = max_documents_to_download
  )
}
