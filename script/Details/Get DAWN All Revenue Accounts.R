script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(script_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (file.exists("DAWN Revenue Download Helper.R")) {
  normalizePath(getwd())
} else if (file.exists(file.path("script", "Aggregate", "DAWN Revenue Download Helper.R"))) {
  normalizePath(file.path(getwd(), "script", "Aggregate"))
} else {
  stop("Could not find DAWN Revenue Download Helper.R. Run this script from the project root or script/Aggregate folder.", call. = FALSE)
}
# Scripts are stored in script/Details, while data files live at the project root.
project_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
data_dir <- file.path(project_dir, "data")

source(file.path(project_dir, "script", "Aggregate", "DAWN Revenue Download Helper.R"))

# Example script for downloading a selected GL range.
# Remove revenue_account_min and revenue_account_max to download every revenue
# account listed by DAWN for the selected budget account(s).
run_dawn_revenue_download(
  budget_account_list = c(9130),
  fy_list = c(2000:current_fiscal_year()),
  revenue_account_min = 3001,
  revenue_account_max = 3271,
  output_file = file.path(data_dir, "all_revenue_accounts_history.csv"),
  type_file = file.path(project_dir, "unique_gl_desc_type2.xlsx")
)
