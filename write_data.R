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
  filter(doi %in% included_with_metadata$doi) %>%
  collect()

dataframes_for_app[["pdfs"]] <- pdfs

# Create open access table
oa_tag <- included_small %>%
  left_join(dbReadTable(con, "oa_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  select(-is_oa) %>%
  mutate(is_oa = ifelse(is.na(oa_status)|oa_status == "Unknown", "unknown", 
                        ifelse(oa_status == "closed", "closed", "open"))) %>%
  mutate(oa_status = ifelse(is.na(oa_status)|oa_status == "Unknown", "unknown", oa_status)) %>%
  filter(!is.na(year))

dataframes_for_app[["oa_tag"]] <- oa_tag

# Create transparency table with open data
transparency <- included_small %>%
  left_join(dbReadTable(con, "open_data_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  mutate(is_open_data = case_when(
    is_open_data == TRUE ~ "available",
    is_open_data == FALSE ~ "not available",
    is.na(is_open_data) ~ "unknown"
  ),
  is_open_code = case_when(
    is_open_code == TRUE ~ "available",
    is_open_code == FALSE ~ "not available",
    is.na(is_open_code) ~ "unknown"
  )) %>%
  filter(!is.na(year))

dataframes_for_app[["transparency"]] <- transparency

# Create risk of bias table
rob <- included_small %>%
  left_join(dbReadTable(con, "rob_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  mutate(is_blind = ifelse(is.na(is_blind), "unknown", is_blind),
         is_exclusion = ifelse(is.na(is_exclusion), "unknown", is_exclusion),
         is_interest = ifelse(is.na(is_interest), "unknown", is_interest),
         is_random = ifelse(is.na(is_random), "unknown", is_random),
         is_welfare = ifelse(is.na(is_welfare), "unknown", is_welfare)) %>%
  filter(!is.na(year))

dataframes_for_app[["rob"]] <- rob

# Bring in dictionary and tagged table for joining to create pico ontology full
names <- tbl(con, "pico_dictionary") %>%
  select(id, name) %>%  
  collect() 

pico_tagged <- tbl(con, "pico_tag") %>%
  select(-string) %>% 
  arrange(regex_id) %>% 
  distinct() %>%
  collect()

pico_ontology_full <- tbl(con, "pico_ontology") %>%
  collect() %>% 
  arrange(regex_id) %>%
  select(-name) %>%
  left_join(names, by = c("regex_id" = "id")) %>%
  inner_join(pico_tagged, relationship = "many-to-many", by = c("regex_id")) %>%
  left_join(included_small, by = "uid") %>%
  mutate(year = ifelse(is.na(year), "Unknown", year)) %>%
  filter(!year == "Unknown") %>%
  distinct()

pico_gene_uid <- pico_ontology_full %>% filter(type == "model" & method == "tiab") %>%
  select(-method) %>% distinct()
pico_species_uid <- pico_ontology_full %>% filter(type == "species" & method == "tiab") %>%
  select(-method) %>% distinct()

pico_model_species <- rbind(pico_gene_uid, pico_species_uid) %>%
  filter(uid %in% pico_gene_uid$uid) %>%
  filter(uid %in% pico_species_uid$uid) %>%
  distinct()
pico_sex_outcome <- pico_ontology_full %>%
  filter(type == "sex" | type == "outcome") %>%
  filter(uid %in% pico_gene_uid$uid) %>%
  filter(uid %in% pico_species_uid$uid) %>%
  select(-method) %>%
  distinct()

pico_ontology_full <- rbind(pico_model_species, pico_sex_outcome) %>%
  distinct()


# Included studies uids - used to full join with tagged elements to create "Unknown"
# pico tags when the studies are yet to be tagged
included_with_metadata_uid <- included_with_metadata %>% 
  select(uid)

# Create sex table from pico_ontology_full
sex_tagging <- pico_ontology_full %>%
  filter(type %in% c("sex"),
         uid %in% included_with_metadata$uid) %>%
  select(-doi) %>%
  distinct()

dataframes_for_app[["sex_tagging"]] <- sex_tagging


sex_df <- sex_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Sex", name),
         regex_id = ifelse(name == "Unknown Sex", 9999993, name),
         main_category = ifelse(is.na(main_category), "Unknown", main_category)
         
  )

# Changes data in these columns to title case
#interventions_df["name"] <- as.data.frame(sapply(interventions_df["name"], toTitleCase))
#interventions_df["main_category"] <- as.data.frame(sapply(interventions_df["main_category"], toTitleCase))

dataframes_for_app[["sex_df"]] <- sex_df

model_tagging <- pico_ontology_full %>%
  filter(type %in% c("model"),
         uid %in% included_with_metadata$uid) %>%
  select(-doi) %>% 
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
         uid %in% included_with_metadata$uid) %>%
  select(-doi) %>% 
  distinct()

dataframes_for_app[["species_tagging"]] <- species_tagging

species_df <- species_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Species", name),
         regex_id = ifelse(name == "Unknown Species", 9999992, name), 
         main_category = ifelse(name == "Unknown Species", "Unknown", main_category)
  )

dataframes_for_app[["species_df"]] <- species_df

# Create outcome table from pico_ontology_full
outcome_tagging <- pico_ontology_full %>%
  filter(type %in% c("outcome"),
         uid %in% included_with_metadata$uid) %>%
  select(-doi) %>%
  distinct()

dataframes_for_app[["outcome_tagging"]] <- outcome_tagging


outcome_df <- outcome_tagging %>% 
  full_join(included_with_metadata_uid, by = "uid", relationship = "many-to-many") %>% 
  mutate(name = ifelse(is.na(name), "Unknown Outcome", name),
         regex_id = ifelse(name == "Unknown Outcome", 9999994, name),
         main_category = ifelse(is.na(main_category), "Unknown", main_category)
         
  )

# Changes data in these columns to title case
outcome_df["name"] <- as.data.frame(sapply(outcome_df["name"], toTitleCase))
#outcome_df["main_category"] <- as.data.frame(sapply(outcome_df["main_category"], toTitleCase))

dataframes_for_app[["outcome_df"]] <- outcome_df


sex_df_small <- sex_df %>%
  select(name, uid) %>%
  filter(!name == "Unknown Sex") %>%
  rename(sex = name) %>%
  distinct()

sex_df_small <- aggregate(sex ~ uid, sex_df_small, FUN = paste, collapse = "; ")

dataframes_for_app[["sex_df_small"]] <- sex_df_small

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
pico <- sex_df_small %>%
  full_join(model_df_small) %>%
  full_join(outcome_df_small) %>%
  full_join(species_df_small) %>%
  full_join(included_small) %>%
  select(-doi, -year)

dataframes_for_app[["pico"]] <- pico


data_for_bubble <- included_with_metadata_uid %>% 
  left_join(species_df[, c("uid","name")], by ="uid", relationship = "many-to-many") %>%
  rename(species = name) %>% 
  left_join(outcome_df[, c("uid", "name")], by = "uid", relationship = "many-to-many") %>%
  rename(outcome = name) %>% 
  left_join(model_df[, c("uid", "name")], by = "uid", relationship = "many-to-many") %>% 
  rename(model = name)

dataframes_for_app[["data_for_bubble"]] <- data_for_bubble

# Create funder tag table
funder_tag <- included_small %>%
  left_join(dbReadTable(con, "funder_grant_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  mutate(funder_name = ifelse(is.na(funder_name), "Unknown", funder_name),
         award_id = ifelse(is.na(award_id), "Unknown", funder_name)) %>%
  filter(!is.na(year)) %>%
  select(uid, year, funder_name) %>%
  distinct()

dataframes_for_app[["funder_tag"]] <- funder_tag

# Create institution tag table
institution_tag <- included_small %>%
  left_join(dbReadTable(con, "institution_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  mutate(institution_id = ifelse(is.na(institution_id), "Unknown", institution_id),
         name = ifelse(is.na(name), "Unknown", name),
         ror = ifelse(is.na(ror), "Unknown", ror),
         institution_country_code = ifelse(is.na(institution_country_code), "Unknown", institution_country_code),
         type = ifelse(is.na(type), "Unknown", type)) %>%
  left_join(dbReadTable(con, "ror_coords"), by = "ror") %>%
  mutate(latitude = as.numeric(latitude),
         longitude = as.numeric(longitude)) %>%
  mutate(lat = latitude,
         long = longitude) %>%
  left_join(dbReadTable(con, "country_code"), by = "institution_country_code") %>%
  filter(!is.na(year))

dataframes_for_app[["institution_tag"]] <- institution_tag

# Create retraction tag table
retraction_tag <- included_small %>%
  left_join(dbReadTable(con, "retraction_tag"), by = "doi", relationship == "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  mutate(is_retracted = case_when(
    is_retracted == TRUE ~ "Retracted",
    is_retracted == FALSE ~ "Not retracted",
    is.na(is_retracted) ~ "Unknown"
  )) %>%
  filter(!is.na(year))

dataframes_for_app[["retraction_tag"]] <- retraction_tag

# Create discipline tag table
discipline_tag <- included_small %>%
  left_join(dbReadTable(con, "discipline_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  filter(!is.na(year)) %>%
  mutate(main_discipline = ifelse(is.na(main_discipline), "Unknown", main_discipline),
         score = ifelse(is.na(score), "Unknown", score),
         level = ifelse(is.na(level), "Unknown", level))

dataframes_for_app[["discipline_tag"]] <- discipline_tag

# Create article type tag table
article_tag <- included_small %>%
  left_join(dbReadTable(con, "article_type"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  filter(!is.na(year)) %>%
  select(-is_paratext, -type) %>%
  mutate(language = ifelse(is.na(language), "Unknown", language))
  

dataframes_for_app[["article_tag"]] <- article_tag

# Create citation count tag table
citation_count_tag <- included_small %>%
  left_join(dbReadTable(con, "citation_count_tag"), by = "doi", relationship = "many-to-many") %>%
  mutate(year = as.numeric(year)) %>%
  filter(!is.na(year))

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
                 "create_theme.R",
                 "ui_tab_database.R",
                 "ui_tab_funder.R",
                 "ui_tab_location.R",
                 "create_theme.R",
                 "fst_files/",
                 "www/"),
    account = "camarades",
    appName  = "NDC-SOLES",
    logLevel = "verbose",
    launch.browser = T, 
    forceUpdate = T)
})
