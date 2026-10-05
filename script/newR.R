# Install required packages if you don't have them:
install.packages(c("httr", "rvest", "dplyr"))

library(httr)
library(rvest)
library(dplyr)

# 1. Define URL and Parameters
url <- "http://dawn12.state.nv.us:7778/pls/prodsw/bsr_rev_det"
query_params <- list(
  pm_level1_id = "31499",
  pm_level2_id = "95492",
  pm_level3_id = "",
  pm_from_date = "01/01/2000",
  pm_to_date = format(Sys.Date(), "%m/%d/%Y")
)

budget_account_list <- c(9010, 9040, 9050, 9090, 9130, 9360, 9600, 9705, 9707, 9741, 9748, 9752, 9999)

# 2. Fetch the page response
print("Fetching data...")
response <- GET(
  url, 
  query = query_params, 
  add_headers(`User-Agent` = "Mozilla/5.0")
)

# 3. Parse HTML and extract tables
if (status_code(response) == 200) {
  html_content <- content(response, as = "text", encoding = "UTF-8")
  
  # Read all tables on the page
  tables <- html_content %>% read_html() %>% html_table(fill = TRUE)
  
  if (length(tables) > 0) {
    # Extract the first table
    df <- tables[[1]]
    print("Data extracted successfully!")
    print(head(df))
    
    # 4. Save to CSV
    output_dir <- if (dir.exists("data")) "data" else file.path("..", "data")
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    write.csv(df, file.path(output_dir, "nevada_revenue_data.csv"), row.names = FALSE)
    print("Saved data to 'nevada_revenue_data.csv'")
  } else {
    print("No tables found on this page.")
  }
} else {
  print(paste("Failed to fetch data. HTTP Status:", status_code(response)))
}
