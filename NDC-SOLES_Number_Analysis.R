# NDC-SOLES_Number_Analysis

# GitHub R packages
library(soles)

# CRAN R packages
library(dplyr)
library(DBI)

# Set database connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("ndc_soles_dbname"),
                 host = Sys.getenv("ndc_soles_host"), 
                 port = 5432,
                 user = Sys.getenv("ndc_soles_user"),
                 password = Sys.getenv("ndc_soles_password"))

# Read in database
dat <- tbl(con, "unique_citations") %>%
  collect() %>%
  mutate(date = as.Date(date, format = "%d%m%y")) %>%
  filter(date <= "2024-10-04")

# Get included records
inc <- dbReadTable(con, "study_classification") %>%
  filter(decision == "include") %>%
  filter(uid %in% dat$uid)
dat <- dat %>% filter(uid %in% inc$uid)
rm(inc)

# Number missing doi
dat_no_doi <- nrow(dat %>% filter(is.na(doi)))

# Number with full text
dat_ft_pdf <- nrow(tbl(con, "full_texts") %>% 
                     filter(doi %in% dat$doi) %>% 
                     filter(!is.na(path)) %>% 
                     collect())
dat_ft_xml <- nrow(tbl(con, "xml_texts") %>% 
                     filter(doi %in% dat$doi) %>% 
                     filter(!is.na(path)) %>% 
                     collect())

# Select pico data
pico_tag_all <- tbl(con, "pico_tag") %>%
  select(-string) %>%
  filter(uid %in% dat$uid) %>%
  distinct() %>%
  left_join(tbl(con, "pico_ontology"), by = "regex_id") %>%
  collect()
# Get uids where model and species in tiab
pico_model <- pico_tag_all %>% filter(type == "model" & method == "tiab") %>%
  select(-method) %>%
  distinct()
pico_species <- pico_tag_all %>% filter(type == "species" & method == "tiab") %>%
  select(-method) %>%
  distinct()
#Filter uids
pico_model_species <- rbind(pico_model, pico_species) %>%
  filter(uid %in% pico_model$uid) %>%
  filter(uid %in% pico_species$uid) %>%
  distinct()
pico_sex_outcome <- pico_tag_all %>%
  filter(type == "sex" | type == "outcome") %>%
  filter(uid %in% pico_model$uid) %>%
  filter(uid %in% pico_species$uid) %>%
  select(-method) %>%
  distinct()
# Bind together
pico_tag <- rbind(pico_model_species, pico_sex_outcome)
rm(pico_model_species, pico_sex_outcome)
# Count tags
pico_tag_count <- pico_tag %>%
  count(name, type) %>%
  distinct()
pico_count_model <- pico_tag_count %>% filter(type == "model")
pico_count_species <- pico_tag_count %>% filter(type == "species")
pico_count_sex <- pico_tag_count %>% filter(type == "sex")
pico_count_outcome <- pico_tag_count %>% filter(type == "outcome")
# Count records
pico_record_count <- pico_tag %>%
  select(uid, type) %>%
  distinct() %>%
  count(type)

# get retraction data
retraction_tag <- dbReadTable(con, "retraction_tag") %>%
  filter(doi %in% dat$doi) %>%
  filter(is_retracted == TRUE)

# get article type data
article_type_tag <- dbReadTable(con, "article_type") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi") %>%
  select(uid, language) %>%
  count(language)

# get author institution data
institution_tag <- dbReadTable(con, "institution_tag") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi") %>%
  left_join(dbReadTable(con, "country_code"), by = "institution_country_code")
institution_tag_unique <- length(unique(institution_tag$name)) - 1 # minus 1 for NA
country_tag_unique <- length(unique(institution_tag$country)) - 1 # minus 1 for NA
institution_continent_count <- institution_tag %>%
  select(uid, continent) %>%
  count(continent)
institution_uk_count <- institution_tag %>%
  select(uid, country) %>%
  count(country) %>%
  filter(country == "United Kingdom")
institution_type_count <- institution_tag %>%
  select(uid, type) %>%
  count(type)

# Get funder data
funder_tag <- dbReadTable(con, "funder_grant_tag") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi") %>%
  filter(funder_name != "Unknown")
funder_record_unique <- length(unique(funder_tag$uid))
funder_unique <- length(unique(funder_tag$funder_name))
funder_top <- funder_tag %>%
  select(uid, funder_name) %>%
  distinct() %>% # lack of distinct made numbers wrong, check app
  count(funder_name)

# Get OpenAlex discipline data
discipline_tag <- dbReadTable(con, "discipline_tag") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi") %>%
  filter(main_discipline != "Unknown") %>%
  filter(score >= 0.4)
discipline_tag_unique <- length(unique(discipline_tag$uid))

# Get open access data
openaccess_tag <- dbReadTable(con, "oa_tag") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi") %>%
  filter(oa_status != "Unknown")
openaccess_count <- openaccess_tag %>%
  select(uid, oa_status) %>%
  count(oa_status)

# Get oddpub data
opendata_tag <- dbReadTable(con, "open_data_tag") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi")
dat_opendata <- nrow(opendata_tag %>% filter(is_open_data == TRUE))
dat_opencode <- nrow(opendata_tag %>% filter(is_open_code == TRUE))
dat_opendata_only <- nrow(opendata_tag %>% 
                            filter(is_open_data == TRUE & is_open_code == FALSE))
dat_opencode_only <- nrow(opendata_tag %>% 
                            filter(is_open_code == TRUE & is_open_data == FALSE))
dat_opendataandcode <- nrow(opendata_tag %>% 
                              filter(is_open_data == TRUE & is_open_code == TRUE))
dat_opendataorcode <- nrow(opendata_tag %>% 
                             filter(is_open_data == TRUE | is_open_code == TRUE))

# Get rob data
rob_tag <- dbReadTable(con, "rob_tag") %>%
  filter(doi %in% dat$doi) %>%
  left_join(dat, by = "doi") %>%
  filter(is_blind != "unknown")
rob_atleastone <- nrow(rob_tag %>% filter(is_blind == "reported" | 
                                            is_random == "reported" |
                                            is_exclusion == "reported" | 
                                            is_interest == "reported" |
                                            is_welfare == "reported"))
rob_random <- nrow(rob_tag %>% filter(is_random == "reported"))
rob_blind <- nrow(rob_tag %>% filter(is_blind == "reported"))
rob_exclusion <- nrow(rob_tag %>% filter(is_exclusion == "reported"))
rob_interest <- nrow(rob_tag %>% filter(is_interest == "reported"))
rob_welfare <- nrow(rob_tag %>% filter(is_welfare == "reported"))
rob_none <- nrow(rob_tag %>% filter(is_blind == "not reported" & 
                                      is_random == "not reported" &
                                      is_exclusion == "not reported" & 
                                      is_interest == "not reported" &
                                      is_welfare == "not reported"))
