#----------------------------StartUp----------------------------------#
# Determine whether  requried libraries are installed, If not, install the libraries
# required to run the script
foo <- function(x) {
  for(i in x) {
    # require returns TRUE invisibly if it was able to load package
    if(! require(i, character.only = TRUE)) {
      # if package was not able to be loaded then re-install
      install.packages(i, dependencies = TRUE)
      # load package after installing
      require(i, character.only = TRUE)
    }
  }
}

# Then install/load packages...
foo(c('tidyverse', 'wdman', 'RSelenium', 'xml2', 'selectr'))

#----------------------------Pipeline----------------------------------#
# using wdman to start a selenium server
selServ <- selenium(
  port = 4444L,
  version = 'latest',
  chromever = '88.0.4324.96', # set this to a chrome version that's available on your machine
)

# using RSelenium to start a chrome on the selenium server
remDr <- remoteDriver(
  remoteServerAddr = 'localhost',
  port = 4444L,
  browserName = 'chrome'
)

# open a new Tag on Chrome
remDr$open()

# navigate to the site you wish to analyze
report_url <- "https://app.powerbi.com/view?r=eyJrIjoiNDZhNjA0MTUtYjRlOS00YjgwLWFjZjItOTBhNGNlZTQyNzM2IiwidCI6ImM0YmUwZDY5LTM2ZjgtNGJhMi1hYTk3LWMxMTM1ZGI1NGYzYyIsImMiOjh9&amp;pageName=ReportSectiond8171dcd4c587890996e"
remDr$navigate(report_url)

#--------------------Suspected Cases by Department Pivot-----------------------#

# fetch the site source in XML
pivot_data_table <- read_html(remDr$getPageSource()[[1]]) %>%
  querySelector("div.pivotTableContainer")

col_headers <- pivot_data_table %>%
  querySelectorAll("div.columnHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

rownames <- pivot_data_table %>%
  querySelectorAll("div.rowHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

pivottable_data <- pivot_data_table %>%
  querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
  map(xml_parent) %>%
  unique() %>%
  map(~ .x %>% querySelectorAll("div.pivotTableCellWrap") %>% map_chr(xml_text)) %>%
  setNames(col_headers) %>%
  bind_cols()

# tadaa
df_final <- tibble(Departmentos = rownames, pivottable_data) %>%
  type_convert(trim_ws = T, na = c(""))

# export as csv
write.csv(df_final, file = "Pivot - Suspected Cases by Department.csv", sep = ",",
          row.names = FALSE, col.names = TRUE)

#--------------------Accumulated Suspected Cases Reported----------------------#

#Right-click on trend chart and choose `show as table`. As of 2021-03-09, do not
#have full solution to pull all rows from table without manually scrolling on page,
#and then rerunning code below each time to capture more rows.

# fetch the site source in XML
pivot_data_table_2 <- read_html(remDr$getPageSource()[[1]]) %>%
  querySelector("#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToScreen > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(4) > transform > div > div:nth-child(3) > div > detail-visual-modern > div > visual-modern > div > div")

#Scroll to desired section of rows. Appears that you can grab up to 30 rows per
#scrape, however one should test by reviewing the number of rows in the rownames_2
#object before proceeding.

col_headers_2 <- pivot_data_table_2 %>%
  querySelectorAll("div.columnHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

rownames_2 <- pivot_data_table_2 %>%
  querySelectorAll("div.pivotTable div.rowHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

pivottable_data_2 <- pivot_data_table_2 %>%
  querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
  map(xml_parent) %>%
  unique() %>%
  map(~ .x %>% querySelectorAll("div.pivotTableCellWrap") %>% map_chr(xml_text)) %>%
  setNames(col_headers_2) %>%
  bind_cols()
