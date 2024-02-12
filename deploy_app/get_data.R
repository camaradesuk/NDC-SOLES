# Connect to database
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("stroke_soles_dbname"),
                 host = Sys.getenv("stroke_soles_host"),
                 port = 5432,
                 user = Sys.getenv("stroke_soles_user"),
                 password = Sys.getenv("stroke_soles_password"))

# refer to unique citations table
unique_citations_smaller <- tbl(con, "unique_citations") %>% select(date, uid, title, journal, year, doi, uid, url, author, abstract, keywords)
unique_citations_year <- tbl(con, "unique_citations") %>% select(uid, year)

# from machine screen table - get counts of included studies per date and load all included studies
included <- tbl(con, "study_classification")  %>% select(uid, decision) %>% filter(decision=="include")

included_with_metadata <- unique_citations_smaller %>%
  inner_join(included, by="uid") %>%
  left_join(tbl(con, "oa_tag"), by = "doi") %>%
  left_join(tbl(con, "open_data_tag"), by = "doi") %>%
  left_join(tbl(con, "rob_tag"), by = "doi") %>%
  left_join(tbl(con, "full_texts"), by = "doi") %>%
  collect()
included_with_metadata_small <- included_with_metadata %>% select(uid, year)
included_with_metadata$year <- as.numeric(included_with_metadata$year)

included_with_metadata$is_oa <- gsub("TRUE", "open", included_with_metadata$is_oa)
included_with_metadata$is_oa <- gsub("FALSE", "closed", included_with_metadata$is_oa)
included_with_metadata$is_open_data <- gsub("TRUE|true", "open", included_with_metadata$is_open_data)
included_with_metadata$is_open_data <- gsub("FALSE|false", "closed", included_with_metadata$is_open_data)
included_with_metadata$is_open_code <- gsub("TRUE|true", "open", included_with_metadata$is_open_code)
included_with_metadata$is_open_code <- gsub("FALSE|false", "closed", included_with_metadata$is_open_code)

include_by_date <- included_with_metadata %>%
  distinct() %>%
  group_by(date) %>%
  count() %>%
  mutate(date = lubridate::dmy(date)) %>%
  arrange(desc(date)) %>%
  ungroup()

# get latest search date - based on latest included studies
latest_date <- include_by_date$date[1]

# load metadata for tables
metadata <- tbl(con, "unique_citations") %>% select(title, year, doi, uid, url, author)

# Load model data
tagged_model <- tbl(con, "pico_tag") %>% 
  left_join(tbl(con, "pico_ontology"), by = "id") %>% 
  collect() %>% 
  left_join(included_with_metadata_small, by = "uid", relationship = "many-to-many") %>%
  select(uid, name = id, type = type.x, main_category, sub_category, year) %>%
  arrange(sub_category)
tagged_model$year <- as.numeric(tagged_model$year)


status = data.frame(tag = c("full_text", "risk of bias", "open_access", "open_data", "model_gene", "model_species", "intervention", "outcome"),
                    complete = c(nrow(included_with_metadata[included_with_metadata$status == "found", ]),
                                 nrow(included_with_metadata[!is.na(included_with_metadata$is_random), ]),
                                 nrow(included_with_metadata[!is.na(included_with_metadata$is_oa), ]),
                                 nrow(included_with_metadata[!is.na(included_with_metadata$is_open_data), ]),
                                 nrow(unique(tagged_model %>% filter(type == "model" & main_category == "gene") %>% select(uid))),
                                 nrow(unique(tagged_model %>% filter(type == "model" & main_category == "species") %>% select(uid))),
                                 nrow(unique(tagged_model %>% filter(type == "intervention") %>% select(uid))),
                                 nrow(unique(tagged_model %>% filter(type == "outcome") %>% select(uid)))))

status$percent <- ceiling((status$complete/nrow(included_with_metadata))*100)
