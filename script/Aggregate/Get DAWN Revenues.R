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

# Scripts are stored in script/Aggregate, while data and lookup files live at the project root.
project_dir <- normalizePath(file.path(script_dir, "..", ".."), mustWork = FALSE)
data_dir <- file.path(project_dir, "data")

source(file.path(script_dir, "DAWN Revenue Download Helper.R"))

# Edit this list if budget accounts need to be added or removed.
budget_account_list <- c(9010, 9040, 9050, 9090, 9130, 9360, 9600, 9705, 9707, 9741, 9748, 9752, 9999)

run_dawn_revenue_download(
  budget_account_list = budget_account_list,
  fy_list = c(2000:current_fiscal_year()),
  output_file = file.path(data_dir, "all_revenue_accounts_history.csv"),
  type_file = file.path(project_dir, "unique_gl_desc_type2.xlsx")
)