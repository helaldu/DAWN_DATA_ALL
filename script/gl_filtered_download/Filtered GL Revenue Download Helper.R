# Filtered GL Revenue Download Helper
# -----------------------------------
# This helper creates a separate revenue download workflow that keeps only the
# GL Number list requested for the filtered-GL data set. It reuses the base
# DAWN Revenue Download Helper functions but filters level_2_ids before detail
# pages are downloaded.
#
# To change the filter later, edit filtered_gl_codes below.

filtered_gl_codes <- sort(unique(c(
  3001, 3002, 3003, 3004, 3005, 3028, 3029, 3030, 3032, 3033,
  3034, 3035, 3041, 3042, 3043, 3044, 3045, 3046, 3047, 3048,
  3049, 3050, 3051, 3052, 3053, 3055, 3059, 3061, 3062, 3064,
  3066, 3067, 3068, 3069, 3072, 3073, 3074, 3101, 3102, 3103,
  3105, 3107, 3113, 3114, 3115, 3120, 3121, 3129, 3130, 3131,
  3150, 3152, 3161, 3162, 3165, 3168, 3169, 3172, 3173, 3178,
  3181, 3190, 3202, 3203, 3204, 3205, 3206, 3220, 3222, 3240,
  3242, 3243, 3245, 3247, 3254, 3255, 3271, 3274, 3276, 3290,
  3291, 3601, 4102, 4403, 4408, 4409, 4741, 4862, 3031
)))

run_filtered_gl_revenue_download <- function(
    budget_account_list,
    output_file,
    fy_list = c(2000:current_fiscal_year()),
    type_file = "unique_gl_desc_type2.xlsx",
    gl_codes = filtered_gl_codes,
    to_date = format(Sys.Date(), "%m/%d/%Y")) {
  gl_codes <- sort(unique(as.integer(gl_codes)))
  type_lookup <- read_revenue_tracking_types(type_file)

  level_1_ids <- expand_grid(
    budget_account = budget_account_list,
    fiscal_year = fy_list
  ) |>
    pmap_dfr(~ get_level_1_ids(..1, ..2))

  if (nrow(level_1_ids) == 0) {
    stop("No level 1 revenue links found.", call. = FALSE)
  }

  level_2_ids <- level_1_ids |>
    pmap_dfr(~ get_level_2_ids(..1, ..2, ..3)) |>
    mutate(revenue_account_number = as.integer(revenue_account)) |>
    filter(revenue_account_number %in% gl_codes) |>
    select(-revenue_account_number)

  if (nrow(level_2_ids) == 0) {
    stop("No revenue accounts matched the filtered GL list.", call. = FALSE)
  }

  message("Found ", nrow(level_2_ids), " filtered GL revenue account/year records to download.")

  result_df <- level_2_ids |>
    pmap_dfr(~ download_transaction_data(..1, ..2, ..3, ..4, ..5, ..6, to_date))

  revenue_data <- result_df |>
    filter(
      !is.na(`Doc Number`),
      str_trim(`Doc Number`) != "",
      !str_detect(Date, "^Total")
    ) |>
    mutate(
      Date = lubridate::mdy(Date),
      Amount = readr::parse_number(Amount),
      revenue_account = as.integer(revenue_account),
      level_1_id = as.integer(level_1_id),
      level_2_id = as.integer(level_2_id)
    ) |>
    left_join(type_lookup, by = "revenue_account") |>
    select(
      `Doc Number`,
      Date,
      Amount,
      level_1_id,
      level_2_id,
      `GL Number` = revenue_account,
      description,
      Type,
      `BA Number` = ba,
      fy
    ) |>
    arrange(`BA Number`, fy, `GL Number`, Date, `Doc Number`)

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  fwrite(revenue_data, file = output_file)
  message("Saved ", nrow(revenue_data), " filtered GL row(s) to ", output_file)

  invisible(revenue_data)
}
