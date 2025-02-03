# Run ML at Threshold

# Load Packages
library(DBI)
library(dplyr)
library(readr)
library(caret)

run_ml_at_threshold <- function(con, project_name="ndc-soles", classifier_name="in-vivo", 
                    screening_decisions, unscreened_set, threshold){
  
  # Create directories
  dir.create("screening", showWarnings = F)
  dir.create("screening/output", showWarnings = F)
  
  # Load ML files
  source("/opt/sharedFolder/SSML/create_files_API.R")
  source("/opt/sharedFolder/SSML/JT_API_config.R")
  source("/opt/sharedFolder/SSML/JT_API_wrap.R")
  source("/opt/sharedFolder/SSML/ML_analysis.R")
  
  # Set date
  date <- format(Sys.Date(), "%y%m%d")
  
  # Merge labelled and unlabelled data
  ml_data <- rbind(screening_decisions, unscreened_set) %>%
    mutate(TEMP_ID = 1:nrow(ml_data))
  
  # Write unscreened data to tsv
  write_tsv(ml_data, paste0("screening/output/ml_run_",date,".tsv"))
  
  # Create ML filenames
  ml_filenames <- CreateFileNamesForIOEAPI(
    paste0("screening/output/ml_run_",date,".tsv"),
    paste0("screening/output/ml_run_",date,"_results.tsv")
  )
  
  # Send data to ML via API and return results to output folder
  TrainCollection(ml_filenames, projectId = paste0("ndc_soles_run_ml_",date))
  
  # Read in scores and process those above threshold
  
  ml_scores <- read_tsv(paste0("screening/output/ml_run_",date,"_results.tsv")) %>%
    select(-Incl, TEMP_ID = PaperId) %>%
    left_join(ml_data, by = "TEMP_ID") %>%
    select(uid = ITEM_ID, score = probabilities) %>%
    mutate(decision = ifelse(score >= threshold, "include", "exclude")) %>%
    mutate(type = "eppi-machine",
           name = classifier_name,
           cid = date,
           date = Sys.Date())
  
  # Write data to table
  dbWriteTable(con, "study_classification", ml_scores, append = T)
  
  
}