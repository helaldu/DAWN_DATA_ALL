script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(script_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (file.exists("Filtered GL Revenue Download Helper.R")) {
  normalizePath(getwd())
} else if (file.exists(file.path("script", "gl_filtered_download", "Filtered GL Revenue Download Helper.R"))) {
  normalizePath(file.path(getwd(), "script", "gl_filtered_download"))
} else {
  stop("Could not find Filtered GL Revenue Download Helper.R. Run this script from the project root or filtered script folder.", call. = FALSE)
}

project_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
base_script_dir <- file.path(project_dir, "script")
data_dir <- file.path(project_dir, "data_filtered_gl")

source(file.path(base_script_dir, "DAWN Revenue Download Helper.R"))
source(file.path(script_dir, "Filtered GL Revenue Download Helper.R"))

# Edit here if you want a smaller/larger BA set.
budget_account_list <- c(9010, 9040, 9050, 9090, 9130, 9360, 9600, 9705, 9707, 9741, 9748, 9752, 9999)

run_filtered_gl_revenue_download(
  budget_account_list = budget_account_list,
  fy_list = c(2000:current_fiscal_year()),
  output_file = file.path(data_dir, "filtered_gl_revenue_accounts_history.csv"),
  type_file = file.path(project_dir, "unique_gl_desc_type2.xlsx")
)
