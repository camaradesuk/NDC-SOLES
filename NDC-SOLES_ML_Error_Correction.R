# NDC-SOLES ML DEVELOPMENT =====================================================

# SET UP =======================================================================

# Libraries
library(soles)
library(dplyr)
library(readr)
library(DBI)
library(purrr)
library(tidyr)
library(parallel)

# Create Directories
dir.create("screening", showWarnings = F)
dir.create("screening/output", showWarnings = F)

# Source Functions
# These are not shared with code
source("/opt/sharedFolder/JTML/syrfIoeHelper.R")
source("/opt/sharedFolder/JTML/ioeAPI.R")
source("/opt/sharedFolder/JTML/analysis.R")
source("/opt/sharedFolder/JTML/jtapiConfigure.R")

# Set Variables
project_name="ndc-soles"
classifier_name="in_vivo"
date <- format(Sys.Date(), "%d%m%y")

# INITIAL PERFORMANCE ==========================================================

# Create data folder
dataFolder <- "screening/error_correction/performance_initial"
outputFilenames <- CreateMLFilenames(paste0(dataFolder, project_name), 
                                     date)

# Read in labelled data
labelled_data <- read.csv("screening/labelled_data/ndc_soles_labelled_data.csv", 
                          stringsAsFactors = F) %>%
  mutate(REVIEW_ID = "NDC-SOLES",
         Cat = NA) %>%
  select(ITEM_ID = uid, REVIEW_ID, Cat, TITLE = title, ABSTRACT = abstract,
         KEYWORDS = keywords, LABEL = decision)

# Format screening decisions
allDecisions <- WriteFilesForIOE(labelled_data, outputFilenames)

# Write files for ML
ifilenames <- CreateFileNamesForIOEAPI(outputFilenames$Records, 
                                       outputFilenames$Decisions, 
                                       outputFilenames$Vectors, 
                                       outputFilenames$Results)

# Train ML
TrainCollection(ifilenames, gsub("[-]", "", paste0(project_name, 
                                                   "_", date)))

# Analyse results
analysisResult <- FindBestPerformance(outputFilenames$Results, 
                                      outputFilenames$TestDecisions, 
                                      outputFilenames$Analysis)

# Get threshold
threshold <- analysisResult[which(
  as.logical(analysisResult[,"Chosen"])), "Threshold"][[1]]

# Output performance
performance <- as.data.frame(analysisResult)
performance <- performance %>% filter(Chosen == 1)
performance <- performance %>% mutate(cid = 101) %>% select(-Chosen) %>% 
  rename(balanced_accuracy = Balanced.Accuracy)
names(performance) <- tolower(names(performance))
write.csv(performance, "screening/error_correction/performance_initial/performance.csv", 
          row.names = F)

# ERROR CORRECTION =============================================================

# Read in results
results <- read.csv(paste0("screening/output/performance_initial/",
                           project_name,date,"_result.csv"), 
                    stringsAsFactors = F, header = F) %>%
  rename(score = V1, ITEM_ID = V2, project_name = V3)

# Combine with screening decisions 
results <- merge(labelled_data, results, by = "ITEM_ID") %>%
  select(ITEM_ID, LABEL, score, TITLE, ABSTRACT) %>%
  mutate(difference = abs(LABEL - score))

# Get 100 records with biggest difference
difference <- results %>%
  arrange(desc(difference)) %>%
  head(100)

# Format for SyRF
syrf_error <- difference %>% mutate(Authors = NA, PublicationName = NA,
                                    AlternateName = NA, Url = NA, 
                                    AuthorAddress = NA, Year = 0,
                                    Doi = NA, ReferenceType = NA,
                                    PdfRelativePath = NA) %>%
  select(Title = TITLE, Authors, PublicationName, AlternateName, 
         Abstract = ABSTRACT, Url, AuthorAddress, Year, Doi, ReferenceType, 
         Keywords = LABEL, PdfRelativePath, CustomId = ITEM_ID)

# Write csv
write.csv(syrf_error, "screening/labelled_data/syrf_errorcorrection.csv", row.names = F)


# RETRAIN ML ===================================================================

# Create data folder
dataFolder <- "screening/output/performance_corrected/"
outputFilenames <- CreateMLFilenames(paste0(dataFolder, project_name), 
                                     date)

# Read in SyRF corrected decisions
syrf_errorcorrection <- read.csv("screening/labelled_data/syrf_errorcorrection_complete.csv", 
                                 stringsAsFactors = F) %>%
  rename(LABEL_CORRECTED = LABEL) %>%
  merge(syrf_screening, by = "ITEM_ID", all = T) %>%
  filter(!is.na(LABEL_CORRECTED)) %>%
  select(-LABEL) %>%
  rename(LABEL = LABEL_CORRECTED)

# Combine with other decisions
labelled_corrected <- rbind(syrf_errorcorrection, labelled_data %>% 
                          filter(!ITEM_ID %in% syrf_errorcorrection$ITEM_ID))

# Write csv
write.csv(syrf_corrected, "screening/labelled_data/ndc_soles_labelled_data_corrected.csv", 
          row.names = F)

# Format screening decisions
allDecisions <- WriteFilesForIOE(syrf_corrected, outputFilenames)

# Write files for ML
ifilenames <- CreateFileNamesForIOEAPI(outputFilenames$Records, 
                                       outputFilenames$Decisions, 
                                       outputFilenames$Vectors, 
                                       outputFilenames$Results)

# Train ML
TrainCollection(ifilenames, gsub("[-]", "", paste0(project_name, 
                                                   "_", date)))

# Analyse results
analysisResult <- FindBestPerformance(outputFilenames$Results, 
                                      outputFilenames$TestDecisions, 
                                      outputFilenames$Analysis)

# Get threshold
threshold <- analysisResult[which(
  as.logical(analysisResult[,"Chosen"])), "Threshold"][[1]]

# Output performance
performance <- as.data.frame(analysisResult)
performance <- performance %>% filter(Chosen == 1)
performance <- performance %>% mutate(cid = 101) %>% select(-Chosen) %>% 
  rename(balanced_accuracy = Balanced.Accuracy)
names(performance) <- tolower(names(performance))
write.csv(performance, "screening/output/performance_corrected/performance.csv", 
          row.names = F)
