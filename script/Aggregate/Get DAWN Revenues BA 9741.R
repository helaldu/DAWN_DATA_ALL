script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(script_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (file.exists("DAWN Revenue Download Helper.R")) {
  normalizePath(getwd())
} else if (file.exists(file.path("script", "Aggregate", "DAWN Revenue Download Helper.R"))) {
  normalizePath(file.path(getwd(), "script", "Aggregate"))
} else {
  stop("Could not find DAWN Revenue Download Helper.R. Run this script from the project root or script folder.", call. = FALSE)
}
# Scripts are stored in script/Aggregate, while data and lookup files live at the project root.
project_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
data_dir <- file.path(project_dir, "data")

source(file.path(script_dir, "DAWN Revenue Download Helper.R"))

# Edit these values if needed:
# - budget_account_list: budget account(s) to download.
# - fy_list: fiscal years to include.
# - output_file: CSV file that will be written.
run_dawn_revenue_download(
  budget_account_list = c(9741),
  fy_list = c(2000:current_fiscal_year()),
  output_file = file.path(data_dir, "dawn_revenue_accounts_9741_history.csv"),
  type_file = file.path(project_dir, "unique_gl_desc_type2.xlsx")
)
