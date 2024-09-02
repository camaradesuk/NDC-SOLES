# GitHub R packages
library(soles)

# Cran R packages
library(DBI)
library(dplyr)
library(readr)
library(openalexR)
library(parallel)
library(tools)
library(fst)

# Set database connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("ndc_soles_dbname"),
                 host = Sys.getenv("ndc_soles_host"), 
                 port = 5432,
                 user = Sys.getenv("ndc_soles_user"),
                 password = Sys.getenv("ndc_soles_password"))

# Create empty list
dataframes_for_app <- list()

# Create unique_citations table
unique_citations <- tbl(con, "unique_citations") %>% 
  select(date, uid, title, journal, year, doi, uid, url, author, abstract, keywords, isbn)

#create included tbl
included_with_metadata <- tbl(con, "study_classification")  %>%
  select(uid, decision) %>%
  filter(decision == "include") %>%
  left_join(unique_citations, by = "uid") %>%
  mutate(year = as.numeric(year)) %>% 
  collect()

# Add to list
dataframes_for_app[["included_with_metadata"]] <- included_with_metadata

# Create small df
included_small <- included_with_metadata %>% 
  select(uid, doi, year)

# Gather data for included_per_year_plot
n_included_per_year_plot_data <- unique_citations %>%
  select(uid, year) %>%
  collect() %>%
  mutate(is_included = ifelse(uid %in% included_with_metadata$uid, "included", "excluded")) %>%
  select(year, is_included) %>%
  mutate(year = as.numeric(year)) %>% 
  filter(!year == "")

dataframes_for_app[["n_included_per_year_plot_data"]] <- n_included_per_year_plot_data

# Arrange dates
include_by_date <- included_with_metadata %>%
  distinct() %>%
  group_by(date) %>%
  count() %>%
  mutate(date = lubridate::dmy(date)) %>%
  arrange(desc(date)) %>%
  ungroup()

dataframes_for_app[["include_by_date"]] <- include_by_date


# Create pdfs df using full texts
pdfs <- tbl(con, "full_texts") %>%
  select(status, doi) %>%
  collect()

dataframes_for_app[["pdfs"]] <- pdfs

# Create open access table
oa_tag <- tbl(con, "oa_tag") %>%
  collect() %>%
  # Duplicate DOIs - conference abstracts
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  filter(!is.na(is_oa)) %>%
  mutate(year = as.numeric(year))

dataframes_for_app[["oa_tag"]] <- oa_tag

# Create transparency table with open data
transparency <- tbl(con, "open_data_tag") %>%
  collect() %>%
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  filter(!is.na(year)) %>%
  filter(year != "")

transparency[is.na(transparency)] <- "unknown"

dataframes_for_app[["transparency"]] <- transparency

# Create risk of bias table with open data
rob <- tbl(con, "rob_tag") %>%
  collect() %>%
  left_join(included_small, by = "doi") %>%
  mutate(year = as.numeric(year)) %>%
  filter(!is.na(year)) %>%
  filter(year != "")

dataframes_for_app[["rob"]] <- rob

# Bring in dictionary and tagged table for joining to create pico ontology full
names <- tbl(con, "pico_dictionary") %>%
  select(id, name) %>%  
  collect() 

pico_tagged <- tbl(con, "pico_tag") %>%
  select(-strings) %>% 
  arrange(regex_id) %>% 
  collect()

pico_ontology_full <- tbl(con, "pico_ontology") %>%
  collect() %>% 
  arrange(regex_id) %>%
  left_join(names, by = c("regex_id" = "id")) %>%
  inner_join(pico_tagged, relationship = "many-to-many", by = c("regex_id")) %>%
  left_join(included_small, by = "uid") %>%
  mutate(year = ifelse(is.na(year), "Unknown", year),
         frequency = as.numeric(frequency)) %>%
  filter(!year == "Unknown") %>%
  distinct()

# Included studies uids - used to full join with tagged elements to create "Unknown"
# pico tags when the studies are yet to be tagged
included_with_metadata_uid <- included_with_metadata %>% 
  select(uid)

# Create interventions table from pico_ontology_full
interventions_tagging <- pico_ontology_full %>%
  filter(type %in% c("drug", "intervention"),
         method %in% c("tiabkw_regex", "fulltext_regex"),
         uid %in% included_with_metadata$uid) %>%
  filter(!(method == "fulltext_regex" & frequency < 3)) %>%
  select(-doi) %>%
  distinct()

dataframes_for_app[["interventions_tagging"]] <- interventions_tagging


interventions_df <- interventions_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Intervention", name),
         regex_id = ifelse(name == "Unknown Intervention", 9999993, name),
         main_category = ifelse(is.na(main_category), "Unknown", main_category)
         
  )

# Changes data in these columns to title case
#interventions_df["name"] <- as.data.frame(sapply(interventions_df["name"], toTitleCase))
#interventions_df["main_category"] <- as.data.frame(sapply(interventions_df["main_category"], toTitleCase))

dataframes_for_app[["interventions_df"]] <- interventions_df

model_tagging <- pico_ontology_full %>%
  filter(type %in% c("model"),
         method %in% c("tiabkw_regex", "fulltext_regex"),
         uid %in% included_with_metadata$uid) %>%
  filter(!(method == "fulltext_regex" & frequency < 3)) %>%
  select(-method, -frequency, -doi) %>% 
  distinct()

dataframes_for_app[["model_tagging"]] <- model_tagging

model_df <- model_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Model", name),
         regex_id = ifelse(name == "Unknown Model", 9999991, name), 
         main_category = ifelse(name == "Unknown Model", "Unknown", main_category)
  )

dataframes_for_app[["model_df"]] <- model_df

species_tagging <- pico_ontology_full %>%
  filter(type %in% c("species"),
         method %in% c("tiabkw_regex", "fulltext_regex"),
         uid %in% included_with_metadata$uid) %>%
  filter(!(method == "fulltext_regex" & frequency < 3)) %>%
  select(-method, -frequency, -doi) %>% 
  distinct()

dataframes_for_app[["species_tagging"]] <- species_tagging

species_df <- species_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Species", name),
         regex_id = ifelse(name == "Unknown Species", 9999994, name), 
         main_category = ifelse(name == "Unknown Species", "Unknown", main_category)
  )

dataframes_for_app[["species_df"]] <- species_df

# Create outcome table from pico_ontology_full
outcome_tagging <- pico_ontology_full %>%
  filter(type %in% c("outcome"),
         method %in% c("tiabkw_regex", "fulltext_regex"),
         uid %in% included_with_metadata$uid) %>%
  filter(!(method == "fulltext_regex" & frequency < 3)) %>%
  select(-doi) %>%
  distinct()

dataframes_for_app[["outcome_tagging"]] <- outcome_tagging


outcome_df <- outcome_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Outcome", name),
         regex_id = ifelse(name == "Unknown Outcome", 9999992, name),
         main_category = ifelse(is.na(main_category), "Unknown", main_category)
         
  )

# Changes data in these columns to title case
outcome_df["name"] <- as.data.frame(sapply(outcome_df["name"], toTitleCase))
#outcome_df["main_category"] <- as.data.frame(sapply(outcome_df["main_category"], toTitleCase))

dataframes_for_app[["outcome_df"]] <- outcome_df


interventions_df_small <- interventions_df %>%
  select(name, uid) %>%
  filter(!name == "Unknown Intervention") %>%
  rename(intervention = name) %>%
  distinct()

interventions_df_small <- aggregate(intervention ~ uid, interventions_df_small, FUN = paste, collapse = "; ")

dataframes_for_app[["interventions_df_small"]] <- interventions_df_small

outcome_df_small <- outcome_df %>%
  select(name, uid) %>%
  filter(!name == "Unknown Outcome") %>%
  rename(outcome = name) %>%
  distinct()

outcome_df_small <- aggregate(outcome ~ uid, outcome_df_small, FUN = paste, collapse = "; ")

dataframes_for_app[["outcome_df_small"]] <- outcome_df_small

model_df_small <- model_df %>%
  select(name, uid) %>%
  filter(!name == "Unknown Model") %>%
  rename("model" = "name") %>%
  distinct()

model_df_small <- aggregate(model ~ uid, model_df_small, FUN = paste, collapse = "; ")

dataframes_for_app[["model_df_small"]] <- model_df_small

species_df_small <- species_df %>%
  select(name, uid) %>%
  filter(!name == "Unknown Species") %>%
  rename("species" = "name") %>%
  distinct()

species_df_small <- aggregate(species ~ uid, species_df_small, FUN = paste, collapse = "; ")

dataframes_for_app[["species_df_small"]] <- species_df_small

# Create pico df using aggregated data
pico <- interventions_df_small %>%
  full_join(model_df_small) %>%
  full_join(outcome_df_small) %>%
  full_join(species_df_small) 

dataframes_for_app[["pico"]] <- pico


data_for_bubble <- included_with_metadata_uid %>% 
  left_join(interventions_df[, c("uid","name")], by ="uid", relationship = "many-to-many") %>%
  rename(intervention = name) %>% 
  left_join(outcome_df[, c("uid", "name")], by = "uid", relationship = "many-to-many") %>%
  rename(outcome = name) %>% 
  left_join(model_df[, c("uid", "name")], by = "uid", relationship = "many-to-many") %>% 
  rename(model = name)

dataframes_for_app[["data_for_bubble"]] <- data_for_bubble

# Create funder tag table
funder_tag <- tbl(con, "funder_grant_tag") %>%
  collect() %>%
  # Duplicate DOIs - more than one funder
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year))

dataframes_for_app[["funder_tag"]] <- funder_tag

# Create institution tag table
institution_tag <- tbl(con, "institution_tag") %>%
  collect() %>%
  # Duplicate DOIs - more than one institution
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year))

ror_coords <- tbl(con, "ror_coords")

institution_tag <- merge(institution_tag, ror_coords, by = "ror", all = TRUE)

country_codes <- dbReadTable(con, "country_code")

institution_tag <- merge(institution_tag, country_codes, by = "institution_country_code", all.x = TRUE)

institution_tag[is.na(institution_tag)] <- "Unknown"

dataframes_for_app[["institution_tag"]] <- institution_tag

# Create retraction tag table
retraction_tag <- tbl(con, "retraction_tag") %>%
  collect() %>%
  # Duplicate DOIs
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year))

dataframes_for_app[["retraction_tag"]] <- retraction_tag

# Create discipline tag table
discipline_tag <- tbl(con, "discipline_tag") %>%
  collect() %>%
  # Duplicate DOIs
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year))

dataframes_for_app[["discipline_tag"]] <- discipline_tag

# Create article type tag table
article_tag <- tbl(con, "article_type") %>%
  collect() %>%
  # Duplicate DOIs
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year))

dataframes_for_app[["article_tag"]] <- article_tag

# Create citation count tag table
citation_count_tag <- tbl(con, "citation_count_tag") %>%
  collect() %>%
  # Duplicate DOIs
  left_join(included_small, by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year))

dataframes_for_app[["citation_count_tag"]] <- citation_count_tag


## WRITE TO FST
## =============================================================================

# Create folder for fst_files if it does not exist
fst_files_written <- 0
if (!file.exists("deploy_app/fst_files")) {
  dir.create("deploy_app/fst_files")
}

# Write all of the dataframes required to fst files
for (name in names(dataframes_for_app)) {
  dataframe <- dataframes_for_app[[name]]
  write_fst(dataframe, paste0("deploy_app/fst_files/", name, ".fst"))
  fst_files_written <- fst_files_written + 1
}

app_deploy <- try({
  rsconnect::deployApp(
    appDir = "deploy_app",
    appFiles = c("app.R",
                 "modules.R",
                 "ui_tab_evidence_map.R",
                 "ui_tab_rob.R",
                 "ui_tab_workflow.R",
                 "ui_tab_openresearch.R",
                 "ui_tab_about.R",
                 "ui_included_studies.R",
                 "ui_tab_home.R",
                 "ui_sidebar.R",
                 "ui_tab_model_trends.R",
                 "ui_tab_outcome_trends.R",
                 "ui_tab_int_trends.R",
                 "create_theme.R",
                 "ui_tab_database.R",
                 "ui_tab_funder.R",
                 "create_theme.R",
                 "fst_files/",
                 "www/"),
    account = "camarades",
    appName  = "NDC-SOLES",
    logLevel = "verbose",
    launch.browser = T, 
    forceUpdate = T)
})
