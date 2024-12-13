# Additional deduplication

# libraries
library(DBI)
library(dplyr)
library(ASySD)

# DB connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("ndc_soles_dbname"),
                 host = Sys.getenv("ndc_soles_host"), 
                 port = 5432,
                 user = Sys.getenv("ndc_soles_user"),
                 password = Sys.getenv("ndc_soles_password"))

# get data
dat <- dbReadTable(con, "unique_citations")

# Format for asysd
dat$isbn <- dat$issn 
dat$label <- dat$date
dat$record_id <- dat$uid

# run asysd
result <- dedup_citations(dat)

# Get results
result_auto <- result$unique
result_manual <- result$manual_dedup

# Save result
write.csv(dat, "deduplication/ndc_soles_data_to_dedup_2024.csv", row.names = F)
write.csv(result_auto, "deduplication/ndc_soles_auto_2024.csv", row.names = F)

# write manual for review 
write.csv(result_manual, "deduplication/ndc_soles_manual_2024.csv", row.names = F)

# Read in completed manual dedup
result_manual <- read.csv("deduplication/ndc_soles_manual_2024.csv", stringsAsFactors = F) %>%
  filter(duplicate == "yes")

result_auto_manual <- result_auto %>%
  filter(!duplicate_id %in% result_manual$duplicate_id.x)

# Check uids are in labelled (incase lost)
labelled_dat <- read.csv("screening/labelled_data/ndc_soles_labelled_data_corrected.csv", stringsAsFactors = F)
check_labels <- result_auto_manual %>%
  filter(uid %in% labelled_dat$ITEM_ID)
missing <- labelled_dat %>%
  filter(!ITEM_ID %in% check_labels$uid)

# fix missing labels
result_auto_manual$uid <- gsub("^pubmed-31816153$", "wos-000522632400012", result_auto_manual$uid)
result_auto_manual$uid <- gsub("^scopus-84990070551$", "pubmed-27706422", result_auto_manual$uid)
result_auto_manual$uid <- gsub("^pubmed-22715430$", "scopus-84863088665", result_auto_manual$uid)
result_auto_manual$uid <- gsub("^pubmed-15492507$", "wos-000225591100010", result_auto_manual$uid)
result_auto_manual$uid <- gsub("^pubmed-28325749$", "wos-000401127800018", result_auto_manual$uid)
result_auto_manual$uid <- gsub("^pubmed-35584673$", "wos-000803187600008", result_auto_manual$uid)

# format result
result_auto_manual_fixed <- result_auto_manual %>%
  select(uid, source, author, year, journal, doi, title, pages, volume, abstract, isbn, keywords, secondarytitle,
         url, date, issn, pmid, ptype, author_country, number, author_affiliation)

# Check for additional duplicated DOIs or PMID
dat_dup <- result_auto_manual_fixed[duplicated(result_auto_manual_fixed$doi),]

# Fix extra duplicates (DOI = 4; PMID = 3)
result_auto_manual_fixed <- result_auto_manual_fixed %>%
  filter(uid != "wos-000185050000016" & 
           uid != "wos-001109810400015" &
           uid != "wos-001285438700008" &
           uid != "scopus-85029531474" &
           uid != "scopus-0033981451" &
           uid != "scopus-37649014363" &
           uid != "scopus-77449134798")

# Overwrite dataset
dbWriteTable(con, "unique_citations", result_auto_manual_fixed, overwrite = T)
