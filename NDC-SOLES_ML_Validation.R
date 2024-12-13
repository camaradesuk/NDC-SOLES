# Machine Learning K-fold Validation

# Load required R packages =====================================================
require(dplyr)
require(tidyr)
require(stringr)
require(readr)
require(caret)

# Load source files ============================================================
source("/opt/sharedFolder/SSML/create_files_API.R")
source("/opt/sharedFolder/SSML/JT_API_config.R")
source("/opt/sharedFolder/SSML/JT_API_wrap.R")
source("/opt/sharedFolder/SSML/ML_analysis.R")

# Read in labelled data ========================================================
labelled_data <- read.csv("screening/labelled_data/ndc_soles_labelled_data_corrected.csv", 
                          stringsAsFactors = F)

# 2,482 labelled records (627 included and 1,857 excluded); 25% inclusion rate

# Define K folds ===============================================================
# Assign sets (folds) to labelled data
labelled_data_assigned <- rbind(filter(labelled_data, LABEL == 1) %>%
                                  mutate(set = sample(c(1,2,3,4,5,6), n(),
                                                      replace = TRUE, 
                                                      prob = c(0.16, 0.16, 0.16, 0.16, 0.16, 0.2))),
                                filter(labelled_data, LABEL == 0) %>%
                                  mutate(set = sample(c(1,2,3,4,5,6), n(),
                                                      replace = TRUE, 
                                                      prob = c(0.16, 0.16, 0.16, 0.16, 0.16, 0.2))))


# Create a summary table detailing how many records, with each decision, are
# in each set
labelled_data_assigned_summary <- labelled_data_assigned %>%
  select(set, LABEL) %>%
  group_by(set, LABEL) %>%
  count() %>%
  pivot_wider(id_cols = set, 
              names_from = LABEL, 
              names_glue = "LABEL_{LABEL}_n", # names columns "LABEL_1_n" and "LABEL_0_n"
              values_from = n) %>%
  mutate(total_n = LABEL_0_n + LABEL_1_n)

# Save the files
write.csv(labelled_data_assigned, "screening/validation/labelled_data_assigned.csv", row.names = F)
write.csv(labelled_data_assigned_summary, "screening/validation/labelled_data_assigned_summary.csv", row.names = F)

# Prepare data for each iteration ==============================================

# In each iteration, set 6 is always the validation set. Four of the five 
# remaining sets are allocated to train and one is allocated to calibrate. 
# The calibration set changes in each iteration.
# We're binding the 5 iterations together and assigning a iteration label (1-5) 
# in the iteration column.

# Create an empty dataframe to store results
labelled_data_assigned_iteration <- data.frame(matrix(nrow = 0, 
                                                      ncol = length(labelled_data_assigned)))

# Assign colum names
colnames(labelled_data_assigned_iteration) <- colnames(labelled_data_assigned)

# Create vector containing test set number
test_n <- 5

# Loop over 5 iterations
for (i in 1:5){
  # Assign train, calibrate, validate and iteration number
  dat <- labelled_data_assigned %>%
    mutate(cat = ifelse(set == 6, "Validate",
                        ifelse(set == test_n, "Calibrate", "Train")),
           iteration = i)
  # Change which set number becomes the calibration set
  test_n <- test_n - 1
  # Append the iteration data to the full dataframe
  labelled_data_assigned_iteration <- rbind(labelled_data_assigned_iteration,
                                            dat)
}

# Assign a temporary ID for ML
labelled_data_assigned_iteration$TEMP_ID <- 1:nrow(labelled_data_assigned_iteration)

# Save the file
write.csv(labelled_data_assigned_iteration, 
          "screening/validation/labelled_data_assigned_iteration.csv", 
          row.names = F)

# Prepare each fold to go through ML ===========================================

# When passing data into the ML, only the training set should be labelled with
# 1 or 0. The Calibration and validation set should be given 99 labels (e.g. 
# unknown).

#Format data to be run through ML
labelled_data_assigned_iteration_processed <- labelled_data_assigned_iteration %>%
  mutate(LABEL = ifelse(cat != "Train", 99, LABEL),
         REVIEW_ID = "ndc_soles") %>%
  select(REVIEW_ID, ITEM_ID, TITLE, ABSTRACT, LABEL, TEMP_ID, iteration) %>%
  mutate(TITLE = str_squish(TITLE),
         ABSTRACT = str_squish(ABSTRACT))

# Set up for ML and run ML =====================================================

# Loop through iterations
for (i in 1:5){
  # Write data for each iteration
  write_tsv(filter(labelled_data_assigned_iteration_processed, iteration == i) %>%
              select(-iteration), paste0("screening/validation/labelled_data_iteration_",i,".tsv"))
  
  # Create iteration filenames
  iteration_filenames <- CreateFileNamesForIOEAPI(
    paste0("screening/validation/labelled_data_iteration_",i,".tsv"),
    paste0("screening/validation/output/labelled_data_iteration_",i,"_results.tsv"))
  
  # Send data to ML via API and return results to output folder
  TrainCollection(iteration_filenames, projectId = paste0("ndc_soles_validation_iteration_",i))
}

# Process scores from ML =======================================================

# Read in scores
ml_scores <- rbind(read_tsv("screening/validation/output/labelled_data_iteration_1_results.tsv") %>%
                     mutate(iteration = 1),
                   read_tsv("screening/validation/output/labelled_data_iteration_2_results.tsv") %>%
                     mutate(iteration = 2),
                   read_tsv("screening/validation/output/labelled_data_iteration_3_results.tsv") %>%
                     mutate(iteration = 3),
                   read_tsv("screening/validation/output/labelled_data_iteration_4_results.tsv") %>%
                     mutate(iteration = 4),
                   read_tsv("screening/validation/output/labelled_data_iteration_5_results.tsv") %>%
                     mutate(iteration = 5)) %>%
  select(-Incl, TEMP_ID = PaperId)

# match with input data
ml_results <- merge(labelled_data_assigned_iteration, ml_scores, 
                    by = c("TEMP_ID", "iteration"), all = T) %>%
  select(iteration, uid = ITEM_ID, decision = LABEL, set, cat, score = probabilities)

# Calculate performance at each threshold ======================================

# Create a dataframe with just calibration data for analysis
ml_results_calibrate <- ml_results %>%
  filter(cat == "Calibrate") %>%
  mutate(decision = factor(decision))

# Assign 1 or 0 to each score at each threshold from 0.01 to 1 (0.01 increments)
for(i in seq(0.01,1,by=0.01)){
  col <- paste("Threshold", i, sep= "_")
  ml_results_calibrate[[col]] <- as.factor(ifelse(ml_results_calibrate$score >= i, 1, 0))
}

# Create vectors containing names of all columns relevant to regex tiab screening
cols <- colnames(select(ml_results_calibrate,contains("Threshold_")))

# Create empty dataframe for results
results <- data.frame(matrix(nrow = 0, ncol = 8))

# Loop over iterations
for (i in 1:5){
  # Get the calibration set data for the iteration
  iteration_calibration <- filter(ml_results_calibrate, iteration == i)
  # Calculate the results for the iteration across all thresholds
  result <- data.frame(iteration = i,
                       threshold = seq(0.01,1, by = 0.01),
                       recall = lapply(iteration_calibration[cols],
                                       sensitivity,
                                       reference = iteration_calibration$decision,
                                       positive = 1) %>%
                         unlist() %>%
                         unname(),
                       specificity = lapply(iteration_calibration[cols],
                                            specificity,
                                            reference = iteration_calibration$decision,
                                            negative = 0) %>%
                         unlist() %>%
                         unname(),
                       tp = lapply(iteration_calibration[cols],
                                   function(x){x$tpos <- nrow(iteration_calibration %>%
                                                                filter(x == 1 & decision == 1))}) %>%
                         unlist() %>%
                         unname(),
                       tn = lapply(iteration_calibration[cols],
                                   function(x){x$tneg <- nrow(iteration_calibration %>%
                                                                filter(x == 0 & decision == 0))}) %>%
                         unlist() %>%
                         unname(),
                       fp = lapply(iteration_calibration[cols],
                                   function(x){x$fpos <- nrow(iteration_calibration %>%
                                                                filter(x == 1 & decision == 0))}) %>%
                         unlist() %>%
                         unname(),
                       fn = lapply(iteration_calibration[cols],
                                   function(x){x$fneg <- nrow(iteration_calibration %>%
                                                                filter(x == 0 & decision == 1))}) %>%
                         unlist() %>%
                         unname()) %>%
    mutate(precision = tp / (tp + fp),
           f1 = (2 * precision * recall)/(precision + recall))

  # Combine with full dataset
  results <- rbind(results, result)
}

# Get performance at 95% recall for each fold
results_best <- rbind(tail(results %>% filter(iteration == 1) %>% filter(recall >= 0.95), 1),
                      tail(results %>% filter(iteration == 2) %>% filter(recall >= 0.95), 1),
                      tail(results %>% filter(iteration == 3) %>% filter(recall >= 0.95), 1),
                      tail(results %>% filter(iteration == 4) %>% filter(recall >= 0.95), 1),
                      tail(results %>% filter(iteration == 5) %>% filter(recall >= 0.95), 1))

# Get ml scores for validation =================================================
# Create empty dataframe for results
ml_results_validate <- data.frame(matrix(nrow = 0, ncol = 4))

for (i in 1:5){
  val <- ml_results %>%
    filter(cat == "Validate") %>%
    filter(iteration == i) %>%
    mutate(ml_decision = ifelse(score >= results_best$threshold[results_best$iteration == i], 1, 0)) %>%
    mutate(decision = factor(decision)) %>%
    mutate(ml_decision = factor(ml_decision))
  
  ml_results_validate <- rbind(ml_results_validate, val)
}

# Create empty dataframe for validation results
results_val <- data.frame(matrix(nrow = 0, ncol = 7))

# Loop over iterations
for (i in 1:5){
  # Get validation set data for iteration
  iteration_validate <- ml_results_validate %>% filter(iteration == i)
  # Calculate results for validation in each iteration
  result_val <- data.frame(iteration = i,
                           recall = sensitivity(iteration_validate$ml_decision,
                                                reference = iteration_validate$decision,
                                                positive = 1),
                           specificity = specificity(iteration_validate$ml_decision,
                                                     reference = iteration_validate$decision,
                                                     negative = 0),
                           tp = nrow(filter(iteration_validate, decision == 1 & ml_decision == 1)),
                           tn = nrow(filter(iteration_validate, decision == 0 & ml_decision == 0)),
                           fp = nrow(filter(iteration_validate, decision == 0 & ml_decision == 1)),
                           fn = nrow(filter(iteration_validate, decision == 1 & ml_decision == 0))) %>%
    mutate(precision = tp / (tp + fp),
           f1 = (2 * precision * recall)/(precision + recall))
  
  results_val <- rbind(results_val, result_val)
}

write.csv(ml_scores, "screening/validation/output/ml_scores.csv", row.names = F)
write.csv(results, "screening/validation/output/result_calibrate.csv", row.names = F)
write.csv(results_best, "screening/validation/output/result_calibrate_best.csv", row.names = F)
write.csv(results_val, "screening/validation/output/result_validate.csv", row.names = F)
