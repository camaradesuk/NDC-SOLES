# Load Packages
library(DBI)
library(dplyr)
library(readr)
library(caret)

# Load source files
source("/opt/sharedFolder/SSML/create_files_API.R")
source("/opt/sharedFolder/SSML/JT_API_config.R")
source("/opt/sharedFolder/SSML/JT_API_wrap.R")
source("/opt/sharedFolder/SSML/ML_analysis.R")

# NDC-SOLES Database connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("ndc_soles_dbname"),
                 host = Sys.getenv("ndc_soles_host"), 
                 port = 5432,
                 user = Sys.getenv("ndc_soles_user"),
                 password = Sys.getenv("ndc_soles_password"))

# Read in unique records identified from searches
data_search <- dbReadTable(con, "unique_citations") %>%
  select(uid, title, abstract)

# Read in all labelled data
data_labelled <- read.csv("screening/labelled_data/ndc_soles_labelled_data_corrected.csv", stringsAsFactors = F) %>%
  select(uid = ITEM_ID, decision = LABEL)

# Merge labelled data with search data
data_labelled <- merge(data_labelled, data_search, by = "uid")

# Get unscreened records (ones from search without a label)
data_to_screen <- data_search %>%
  filter(!uid %in% data_labelled$uid)

# Format unscreened records for ML
data_to_screen <- data_to_screen %>%
  mutate(TEMP_ID = 1:nrow(data_to_screen),
         LABEL = 99,
         Cat = "") %>%
  select(TITLE = title, ABSTRACT = abstract, LABEL, TEMP_ID, ITEM_ID = uid, Cat) %>%
  mutate(batch = sample(c(1,2,3,4), n(), replace = TRUE, prob = c(0.25, 0.25, 0.25, 0.25)))

# Format labelled records for ML
data_labelled <- data_labelled %>%
  mutate(TEMP_ID = nrow(data_to_screen)+1:nrow(data_labelled),
         Cat = "Train") %>%
  select(TITLE = title, ABSTRACT = abstract, LABEL = decision, TEMP_ID, ITEM_ID = uid, Cat)

# Get optimal training data from k-fold validation
data_training <- read.csv("screening/validation/labelled_data_assigned_iteration.csv", stringsAsFactors = F) %>%
  filter(iteration == 4,
         cat == "Train")

# Filter labelled data to get optimal training data
data_labelled_training <- data_labelled %>%
  filter(ITEM_ID %in% data_training$ITEM_ID)

# Split into batches and run through ML with training data
for (i in 1:4){
  # Merge one batch with labelled data
  batch_data <- rbind(data_to_screen %>% filter(batch == i) %>% select(-batch),
                      data_labelled_training) %>%
    mutate(REVIEW_ID = "ndc-soles")
  
  # Write data for each batch
  write_tsv(batch_data, paste0("screening/output/backlog_data_241007_batch_",i,".tsv"))
  
  # Create iteration filenames
  batch_filenames <- CreateFileNamesForIOEAPI(
    paste0("screening/output/backlog_data_241007_batch_",i,".tsv"),
    paste0("screening/output/backlog_data_241007_batch_",i,"_results.tsv"))
  
  # Send data to ML via API and return results to output folder
  TrainCollection(batch_filenames, projectId = paste0("ndc_soles_backlog_241007_batch_",i))
  
}

# Read in scores
ml_scores <- rbind(read_tsv("screening/output/backlog_data_241007_batch_1_results.tsv"),
                   read_tsv("screening/output/backlog_data_241007_batch_2_results.tsv"),
                   read_tsv("screening/output/backlog_data_241007_batch_3_results.tsv"),
                   read_tsv("screening/output/backlog_data_241007_batch_4_results.tsv")) %>%
  select(-Incl, TEMP_ID = PaperId)

# Process scores with threshold
ml_scores <- merge(ml_scores, data_to_screen, by = "TEMP_ID") %>%
  select(uid= ITEM_ID, score = probabilities) %>%
  mutate(decision = ifelse(score >= 0.39, "include", "exclude")) # input threshold

# combine all data
data_to_write <- rbind(ml_scores %>%
                         mutate(type = "eppi-machine"),
                       data_labelled %>% 
                         mutate(score = LABEL,
                                decision = ifelse(LABEL == 1, "include", "exclude"),
                                type = "labelled") %>%
                         select(uid = ITEM_ID, score, decision, type)) %>%
  mutate(name = "in-vivo",
         cid = 100,
         date = Sys.Date())

# Write data to table
dbWriteTable(con, "study_classification", data_to_write, overwrite = T)
