# NDC-SOLES Regexes ############################################################

# This code is used retrieve full texts, and test and validate regexes for 
# NDC-SOLES.

# Load R Packages and Connect to Database ######################################

# GitHub R packages
library(soles)

# Cran R packages
library(DBI)
library(dplyr)
library(stringr)
library(rcrossref)
library(europepmc)

library(xml2)
library(tidypmc)
library(readtext)
library(quanteda)
library(tidyr)

# Set database connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("ndc_soles_dbname"),
                 host = Sys.getenv("ndc_soles_host"), 
                 port = 5432,
                 user = Sys.getenv("ndc_soles_user"),
                 password = Sys.getenv("ndc_soles_password"))

# Get included studies
inc <- tbl(con, "study_classification") %>% filter(decision == "include") %>%
  left_join(tbl(con, "unique_citations"), by = "uid") %>%
  collect()

# Get PDF full texts ###########################################################

# PDF retrieval SOLES function
# Note that the SOLES AutoAnnotation function was used to convert PDFs to TXT
get_ft(con, path="full_texts")

# Get XML full texts ###########################################################

# Get data with DOI
doi <- inc %>% filter(!is.na(doi)) %>%
  select(uid, doi)

# Transform to vector
doi <- doi$doi

# Make sure vector values are unique
doi <- unique(doi)

# Initiate results dataframe
pmcid <- data.frame()

# Use crossref to get PMCID from DOI
for (i in 1:length(doi)){
  # Get the PMID from Crossref
  tryCatch(result <- rcrossref::id_converter(doi[1]))
  # Get the results from the list
  result_df <- result$records
  # Check retrieved
  if("status" %in% colnames(result_df)){
    result_error <- data.frame(pmcid = NA, pmid = NA, doi = doi[i])
    pmcid <- rbind(pmcid, result_error)
  }else{
    # Bind to results to the existing dataframe
    result_df <- result_df %>% select(pmcid, pmid, doi)
    pmcid <- rbind(pmcid, result_df)
  }
  # Sleep for 2 seconds
  Sys.sleep(2)
}

# Save data 
dbWriteTable(con, "xml_texts", pmcid)

# Make vector
pmcid <- pmcid$pmcid

# Create folder for XML
dir.create("xml_texts")

# Retrieve XML full texts
for (i in 1:length(pmcid)){
  # Try to download XML
  tryCatch({
    xml_result <- europepmc::epmc_ftxt(ext_id = pmcid[i])
    # Save as file if it exists
    xml2::write_xml(xml_result, paste0("xml_texts/",pmcid[i],".xml"))
    # Remove from environment
    rm(xml_result)
    # Print message
    print(paste("Downloaded XML file for pmcid:", pmcid[i]))
  }, error = function(e) {
    # Print a message if there's an error
    print(paste("Error occurred for pmcid:", pmcid[i]))
  })
  # Sleep for 6 seconds
  Sys.sleep(6)
}

# Add data to xml db table
xml_files <- list.files("xml_texts", full.names = T)
xml <- data.frame(path = xml_files, pmcid = xml_files)
xml$pmcid <- gsub("xml_texts/", "", xml$pmcid)
xml$pmcid <- gsub("\\.xml", "", xml$pmcid)
pmcid <- left_join(pmcid, xml, by = "pmcid")

# Save data
dbWriteTable(con, "xml_texts", pmcid, overwrite = T)

# Find records with XML, PDF and TXT ###########################################

# Filter to find records with all texts
# 4643 in total
text_files <- dbReadTable(con, "full_texts") %>%
  filter(!is.na(path)) %>%
  mutate(pdf_path = str_replace(path, ".txt", ".pdf"),
         txt_path = str_replace(path, ".pdf", ".txt")) %>%
  select(-path) %>%
  left_join(pmcid, by = "doi") %>%
  rename(xml_path = path) %>%
  filter(pdf_path %in% list.files("full_texts", pattern = ".pdf", full.names = T),
         txt_path %in% list.files("full_texts", pattern = ".txt", full.names = T),
         xml_path %in% list.files("xml_texts", pattern = ".xml", full.names = T))

# Get a sample of 400 records (2 sets of 200)
sample_400 <- sample_n(text_files, size = 400, replace = F)

# Format data
sample_400_syrf <- sample_400 %>%
  left_join(inc, by = "doi") %>%
  mutate(AlternateName = NA,
         ReferenceType = "Article",
         PdfRelativePath = paste0(uid,".pdf")) %>%
  select(Title = title, Authors = author, PublicationName = journal, AlternateName, 
         Abstract = abstract, Url = url, AuthorAddress = author_affiliation,
         Year = year, Doi = doi, ReferenceType, Keywords = keywords, PdfRelativePath,
         CustomId = uid, xml_path, txt_path, pdf_path)

# Save data
write.csv(sample_400_syrf, "regex/sample_400_regex_validation.csv", row.names = F)

# Clean Annotated Data #########################################################

# Read in annotations from SyRF
dat_annotated <- read.csv("regex/sample_400_regex_annotation.csv", 
                          stringsAsFactors = F, na.strings = "") %>%
  rename(CustomId = uid) %>%
  left_join(sample_400_syrf, by = "CustomId") %>%
  rename(uid = CustomId, title = Title, abstract = Abstract, doi = Doi) %>%
  select(-Authors, -PublicationName, -AlternateName, -Url, -AuthorAddress
         , -Year, -ReferenceType, -Keywords, -PdfRelativePath) %>%
  mutate(relevance_reason = ifelse(!is.na(gene_not_listed), 
                                   "Animal Study Genetic Model Not Listed", relevance))

# Clean data
unique(dat_annotated$relevance_reason)
dat_annotated$relevance_reason <- gsub("No \\(not genetic model\\)", 
                                       "Animal Study Not Genetic Model",
                                       dat_annotated$relevance_reason)
dat_annotated$relevance_reason <- gsub("No \\(not animal study\\)", 
                                       "Not Animal Study",
                                       dat_annotated$relevance_reason)
dat_annotated$relevance_reason <- gsub("No \\(not primary research\\)", 
                                       "Not Primary Research",
                                       dat_annotated$relevance_reason)
dat_annotated$relevance_reason <- gsub("Yes", "Relevant",
                                       dat_annotated$relevance_reason)
unique(dat_annotated$relevance)
dat_annotated <- dat_annotated %>% 
  mutate(relevance = ifelse(relevance_reason == "Relevant", "Yes", "No"))
dat_annotated[306, "relevance_reason"] <- "Not Primary Research" # Fixes error
dat_annotated[306, "gene_not_listed"] <- NA # Fixes error
dat_annotated[237, "model_gene"] <- "SHANK3" # Fixes typo
dat_annotated[74, "model_gene"] <- "SHANK2; TBR1" # Fixes typo

# Test data cleaning
dat_annotated$tests <- gsub("Forced Swimming Test", "Forced Swim Test",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("Gait Analysis ", "Gait Analysis",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("Limb Clasping", "Limb Grasping",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("New Object Recognition", "Novel Object Recognition",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("Open Field Text", "Open Field Test",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("OtherElectrophysiology", "Other Electrophysiology",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("Reciprocal Interaction Task", "Reciprocal Interaction Test",
                            dat_annotated$tests)
dat_annotated$tests <- gsub("Dark Light Transition Test", "Light Dark Transition Test",
                            dat_annotated$tests)

# Format sex
dat_annotated$sex <- gsub("Male and female", "Male; Female", dat_annotated$sex)
dat_annotated$sex <- gsub(" only", "", dat_annotated$sex)

# Format species
dat_annotated$species <- gsub("Fruit fly", "Fruitfly", dat_annotated$species)

# Prepare for Analysis of Pilot Regexes ########################################

# 400 records in total
# A) 105 / 400 : Relevant (Genetic Models on List)
# B) 109 / 400 : Genetic Model Not on List
# C)  55 / 400 : Not Genetic Model
# D) 117 / 400 : Not Animal Study
# E)  14 / 400 : Not Primary Research

#Shuffle rows
dat_annotated <- dat_annotated[sample(1:nrow(dat_annotated)), ]

# Stratified split into two groups, even number included in each
dat_annotated_1 <- rbind(filter(dat_annotated, relevance_reason == "Relevant") %>%
                         head(52) %>%
                         mutate(set = 1),
                       filter(dat_annotated, relevance_reason != "Relevant") %>%
                         head(148) %>%
                         mutate(set = 1))
dat_annotated <- rbind(dat_annotated %>% filter(!uid %in% dat_annotated_1$uid) %>%
                         mutate(set = 2),
                       dat_annotated_1)

# set 1: 1 = 52 0 = 148
# set 2: 1 = 53 0 = 147

# Run Regexes on Set 1 #########################################################

# Filter set
dat_set_1 <- dat_annotated %>% filter(set == 1)

# Create empty dataframes 
set_1_tiab <- data_frame()
set_1_xml <- data.frame()
set_1_txt <- data.frame()
set_1_pdf <- data.frame()

# Read in XML
for (i in 1:nrow(dat_set_1)){
  xml <- xml2::read_xml(dat_set_1$xml_path[i])
  xml <- tidypmc::pmc_text(xml) %>%
    mutate(uid = dat_set_1$uid[i])
  set_1_xml <- rbind(set_1_xml, xml)
}

# Read in TXT
for (i in 1:nrow(dat_set_1)){
  txt <- readtext::readtext(dat_set_1$txt_path[i]) %>% mutate(doc_id = dat_set_1$uid[i])
  set_1_txt <- rbind(set_1_txt, txt)
}

# Read in PDF (using readtext/pdftools PDF to TXT)
for (i in 1:nrow(dat_set_1)){
  pdf <- readtext::readtext(dat_set_1$pdf_path[i]) %>% mutate(doc_id = dat_set_1$uid[i])
  set_1_pdf <- rbind(set_1_pdf, pdf)
}

# Get title and abstract text
set_1_tiab <- dat_set_1 %>% select(uid, title, abstract)
set_1_tiab$text <- paste(set_1_tiab$title, set_1_tiab$abstract, sep = ". ")
set_1_tiab$text <- gsub("\\.\\.|\\. \\.", ".", set_1_tiab$text)
set_1_tiab <- set_1_tiab %>% select(uid, text)

# Create empty dataframes
set_1_tiab_result <- data.frame()
set_1_xml_result <- data.frame()
set_1_txt_result <- data.frame()
set_1_pdf_result <- data.frame()

# Read in regexes
regex_dictionary <- read.csv("regex/ndc_regexes_pilot.csv",
                             stringsAsFactors = F)

# Run regexes on XML
for (i in 1:nrow(regex_dictionary)){
  try(xml_match <- tidypmc::separate_text(set_1_xml, regex_dictionary$regex[i]))
  if(!is.null(xml_match)){
    xml_match <- xml_match %>%
      mutate(name = regex_dictionary$name[i],
             type = regex_dictionary$type[i])
    set_1_xml_result <- rbind(set_1_xml_result, xml_match)
  }
}

# Subset XML methods section
set_1_xml_result_methods <- set_1_xml_result %>%
  filter(stringr::str_detect(section, regex("\\bmethod|\\bprocedure|\\bmaterial", ignore_case = TRUE)))

# Run regex on TXT
txt_corpus <- quanteda::corpus(set_1_txt)
txt_tokens <- quanteda::tokens(txt_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary)){
  try(txt_match <- quanteda::kwic(txt_tokens, regex_dictionary$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(txt_match)){
    txt_match <- as.data.frame(txt_match)
    txt_match$pattern <- as.character(txt_match$pattern)
    txt_match <- txt_match %>%
      mutate(name = regex_dictionary$name[i],
             type = regex_dictionary$type[i],
             match = stringr::str_extract(txt_match$keyword, txt_match$pattern))
    set_1_txt_result <- rbind(set_1_txt_result, txt_match)
  }
}

# Run regex on PDF
pdf_corpus <- quanteda::corpus(set_1_pdf)
pdf_tokens <- quanteda::tokens(pdf_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary)){
  try(pdf_match <- quanteda::kwic(pdf_tokens, regex_dictionary$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(pdf_match)){
    pdf_match <- as.data.frame(pdf_match)
    pdf_match$pattern <- as.character(pdf_match$pattern)
    pdf_match <- pdf_match %>%
      mutate(name = regex_dictionary$name[i],
             type = regex_dictionary$type[i],
             match = stringr::str_extract(pdf_match$keyword, pdf_match$pattern))
    set_1_pdf_result <- rbind(set_1_pdf_result, pdf_match)
  }
}

# Run regex on tiab
tiab_corpus <- quanteda::corpus(set_1_tiab$text, docnames = set_1_tiab$uid)
tiab_tokens <- quanteda::tokens(tiab_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary)){
  try(tiab_match <- quanteda::kwic(tiab_tokens, regex_dictionary$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(tiab_match)){
    tiab_match <- as.data.frame(tiab_match)
    tiab_match$pattern <- as.character(tiab_match$pattern)
    tiab_match <- tiab_match %>%
      mutate(name = regex_dictionary$name[i],
             type = regex_dictionary$type[i],
             match = stringr::str_extract(tiab_match$keyword, tiab_match$pattern))
    set_1_tiab_result <- rbind(set_1_tiab_result, tiab_match)
  }
}

# Format results
set_1_results <- rbind(rbind(set_1_pdf_result %>% mutate(format = "pdf"),
                       set_1_txt_result %>% mutate(format = "txt"),
                       set_1_tiab_result %>% mutate(format = "tiab")) %>%
  mutate(section = NA,
         paragraph = NA) %>%
  select(match, section, paragraph, sentence = from, text = keyword, 
         uid = docname, name, type, format),
  mutate(set_1_xml_result, format = "xml"),
  mutate(set_1_xml_result_methods, format = "xml_methods"))

# Note records without methods
no_methods <- dat_set_1 %>% filter(!uid %in% set_1_xml_result_methods$uid)

# Save results
write.csv(set_1_results, "regex/output/set_1_initial/set_1_results.csv", row.names = F)


# Analyse Set 1 Initial Results ################################################

# Count matches
set_1_results_counted <- set_1_results %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_1_results_collected <- set_1_results_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  left_join(dat_set_1, by = "uid")

# Fix male and female tag
set_1_results$name <- gsub("Both sexes", "Male; Female", set_1_results$name)
set_1_results <- set_1_results %>%
  separate_rows(name, sep = "; ")

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_1_results_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_1, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_1, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_1, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_1, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_1_results_long <- rbind(set_1_results_long, df)
}

# Merge with regex data
# Get long format
set_1_results_long <- set_1_results_long %>%
  full_join(select(set_1_results, c(uid, name, format, type, match)), 
                            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_1_results_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_1_results_long <- set_1_results_long %>%
  mutate(metric = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & matched == "No", "TN", 
                         ifelse(annotation == "Yes" & matched == "Yes", "TP", 
                                ifelse(annotation == "Yes" & matched == "No", "FN", "FP")))) %>%
  distinct()
  
# Get metrics at annotation level
set_1_results_metrics_annotation <- set_1_results_long %>%
  select(type, format, metric) %>%
  group_by(type, format) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type), names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = 2 * ((precision * recall) / (precision + recall)),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))
  
# Get metrics at publication level
set_1_results_metrics_publication <- set_1_results_long %>%
  # pivot wider for comparison
  pivot_wider(id_cols = uid, names_from = c(format, type), values_from = metric,
              values_fn = ~paste(., collapse = "; ")) %>%
  replace(is.na(.), "TN") %>%
  # clean metrics to assign each paper only one value
  # If any of the regexes got a FN, change to FN
  mutate(across(everything(), ~ ifelse(str_detect(., "FN"), "FN", .))) %>%
  # If any of the regexes got a FP, change to FP
  mutate(across(everything(), ~ ifelse(str_detect(., "FP"), "FP", .))) %>%
  # If there were multiple TP, change to TP
  mutate(across(everything(), ~ ifelse(str_detect(., "TP"), "TP", .))) %>%
  # Pivot longer again for counting
  pivot_longer(!uid, names_to = "format", values_to = "metric") %>%
  # Count confusion matrix
  count(format, metric) %>%
  filter(!str_detect(format, "^No")) %>%
  pivot_wider(id_cols = format, names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  select(format, TP, TN, FP, FN) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Get false negatives for update
set_1_results_long_FN <- set_1_results_long %>%
  filter(metric == "FN")

# Write data
write.csv(set_1_results_collected, "regex/output/set_1_initial/set_1_results_collected.csv", row.names = F)
write.csv(set_1_results_counted, "regex/output/set_1_initial/set_1_results_counted.csv", row.names = F)
write.csv(set_1_results_long, "regex/output/set_1_initial/set_1_results_long.csv", row.names = F)
write.csv(set_1_results_metrics_annotation, "regex/output/set_1_initial/set_1_results_metrics_annotation.csv", row.names = F)
write.csv(set_1_results_metrics_publication, "regex/output/set_1_initial/set_1_results_metrics_publication.csv", row.names = F)
write.csv(set_1_results_long_FN, "regex/output/set_1_initial/set_1_results_long_FN.csv", row.names = F)

# Run Updated Regexes on Set 1 #################################################

# Create empty dataframes
set_1_tiab_result_update <- data.frame()
set_1_xml_result_update <- data.frame()
set_1_txt_result_update <- data.frame()
set_1_pdf_result_update <- data.frame()

# Read in regexes
regex_dictionary_update <- read.csv("regex/ndc_regexes_update.csv",
                             stringsAsFactors = F)

# Run regexes on XML
for (i in 1:nrow(regex_dictionary_update)){
  try(xml_match <- tidypmc::separate_text(set_1_xml, regex_dictionary_update$regex[i]))
  if(!is.null(xml_match)){
    xml_match <- xml_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i])
    set_1_xml_result_update <- rbind(set_1_xml_result_update, xml_match)
  }
}

# Subset XML methods section
set_1_xml_result_update_methods <- set_1_xml_result_update %>%
  filter(stringr::str_detect(section, regex("\\bmethod|\\bprocedure|\\bmaterial", ignore_case = TRUE)))

# Run regex on TXT
txt_corpus <- quanteda::corpus(set_1_txt)
txt_tokens <- quanteda::tokens(txt_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary_update)){
  try(txt_match <- quanteda::kwic(txt_tokens, regex_dictionary_update$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(txt_match)){
    txt_match <- as.data.frame(txt_match)
    txt_match$pattern <- as.character(txt_match$pattern)
    txt_match <- txt_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i],
             match = stringr::str_extract(txt_match$keyword, txt_match$pattern))
    set_1_txt_result_update <- rbind(set_1_txt_result_update, txt_match)
  }
}

# Run regex on PDF
pdf_corpus <- quanteda::corpus(set_1_pdf)
pdf_tokens <- quanteda::tokens(pdf_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary_update)){
  try(pdf_match <- quanteda::kwic(pdf_tokens, regex_dictionary_update$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(pdf_match)){
    pdf_match <- as.data.frame(pdf_match)
    pdf_match$pattern <- as.character(pdf_match$pattern)
    pdf_match <- pdf_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i],
             match = stringr::str_extract(pdf_match$keyword, pdf_match$pattern))
    set_1_pdf_result_update <- rbind(set_1_pdf_result_update, pdf_match)
  }
}

# Run regex on tiab
tiab_corpus <- quanteda::corpus(set_1_tiab$text, docnames = set_1_tiab$uid)
tiab_tokens <- quanteda::tokens(tiab_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary_update)){
  try(tiab_match <- quanteda::kwic(tiab_tokens, regex_dictionary_update$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(tiab_match)){
    tiab_match <- as.data.frame(tiab_match)
    tiab_match$pattern <- as.character(tiab_match$pattern)
    tiab_match <- tiab_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i],
             match = stringr::str_extract(tiab_match$keyword, tiab_match$pattern))
    set_1_tiab_result_update <- rbind(set_1_tiab_result_update, tiab_match)
  }
}

# Format results
set_1_results_update <- rbind(rbind(set_1_pdf_result_update %>% mutate(format = "pdf"),
                             set_1_txt_result_update %>% mutate(format = "txt"),
                             set_1_tiab_result_update %>% mutate(format = "tiab")) %>%
                         mutate(section = NA,
                                paragraph = NA) %>%
                         select(match, section, paragraph, sentence = from, text = keyword, 
                                uid = docname, name, type, format),
                       mutate(set_1_xml_result_update, format = "xml"),
                       mutate(set_1_xml_result_update_methods, format = "xml_methods"))

# Note records without methods
no_methods_update <- dat_set_1 %>% filter(!uid %in% set_1_xml_result_update_methods$uid)

# Save results
write.csv(set_1_results_update, "regex/output/set_1_update/set_1_results_update.csv", row.names = F)

# Analyse Set 1 Update Results #################################################

# Count matches
set_1_results_update_counted <- set_1_results_update %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_1_results_update_collected <- set_1_results_update_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  left_join(dat_set_1, by = "uid")

# Fix male and female tag
set_1_results_update$name <- gsub("Both sexes", "Male; Female", set_1_results_update$name)
set_1_results_update <- set_1_results_update %>%
  separate_rows(name, sep = "; ")


# Fix fear conditioning annotation
dat_set_1$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_1$tests)

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_1_results_update_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_1, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_1, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_1, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_1, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_1_results_update_long <- rbind(set_1_results_update_long, df)
}

# Merge with regex data
# Get long format
set_1_results_update_long <- set_1_results_update_long %>%
  full_join(select(set_1_results_update, c(uid, name, format, type, match)), 
            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_1_results_update_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_1_results_update_long <- set_1_results_update_long %>%
  mutate(metric_1 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n == 0, "TN", 
                         ifelse(annotation == "Yes" & n >= 1, "TP", 
                                ifelse(annotation == "Yes" & n == 0, "FN", "FP"))),
         metric_2 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 1, "TN", 
                           ifelse(annotation == "Yes" & n >= 2, "TP", 
                                  ifelse(annotation == "Yes" & n <= 1, "FN", "FP"))),
         metric_3 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 2, "TN", 
                           ifelse(annotation == "Yes" & n >= 3, "TP", 
                                  ifelse(annotation == "Yes" & n <= 2, "FN", "FP"))),
         metric_4 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 3, "TN", 
                           ifelse(annotation == "Yes" & n >= 4, "TP", 
                                  ifelse(annotation == "Yes" & n <= 3, "FN", "FP"))),
         metric_5 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 4, "TN", 
                           ifelse(annotation == "Yes" & n >= 5, "TP", 
                                  ifelse(annotation == "Yes" & n <= 4, "FN", "FP")))) %>%
  distinct()

# Get metrics at annotation level
set_1_results_update_metrics_annotation <- rbind(
  select(set_1_results_update_long, c(type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_1_results_update_long, c(type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_1_results_update_long, c(type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_1_results_update_long, c(type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_1_results_update_long, c(type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  group_by(type, format, threshold) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type, threshold), 
              names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Get metrics at publication level 
set_1_results_update_metrics_publication <- rbind(
  select(set_1_results_update_long, c(uid, type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_1_results_update_long, c(uid, type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_1_results_update_long, c(uid, type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_1_results_update_long, c(uid, type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_1_results_update_long, c(uid, type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  # pivot wider for comparison
  pivot_wider(id_cols = uid, names_from = c(format, type, threshold), 
              values_from = metric,
              values_fn = ~paste(., collapse = "; ")) %>%
  replace(is.na(.), "TN") %>%
  # clean metrics to assign each paper only one value
  # If any of the regexes got a FN, change to FN
  mutate(across(everything(), ~ ifelse(str_detect(., "FN"), "FN", .))) %>%
  # If any of the regexes got a FP, change to FP
  mutate(across(everything(), ~ ifelse(str_detect(., "FP"), "FP", .))) %>%
  # If there were multiple TP, change to TP
  mutate(across(everything(), ~ ifelse(str_detect(., "TP"), "TP", .))) %>%
  # Pivot longer again for counting
  pivot_longer(!uid, names_to = "format", values_to = "metric") %>%
  # Count confusion matrix
  count(format, metric) %>%
  filter(!str_detect(format, "^No")) %>%
  pivot_wider(id_cols = format, names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  select(format, TP, TN, FP, FN) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Write data
write.csv(set_1_results_update_collected, "regex/output/set_1_update/set_1_results_update_collected.csv", row.names = F)
write.csv(set_1_results_update_counted, "regex/output/set_1_update/set_1_results_update_counted.csv", row.names = F)
write.csv(set_1_results_update_long, "regex/output/set_1_update/set_1_results_update_long.csv", row.names = F)
write.csv(set_1_results_update_metrics_annotation, "regex/output/set_1_update/set_1_results_update_metrics_annotation.csv", row.names = F)
write.csv(set_1_results_update_metrics_publication, "regex/output/set_1_update/set_1_results_update_metrics_publication.csv", row.names = F)

# Test Gene / Species Filtering (Sentence)######################################

# Subset results
set_1_results_update_gene <- set_1_results_update %>%
  filter(type == "Model Gene") %>%
  mutate(doc_id = as.character(1:n())) 

# Subset species regexes
regex_dictionary_update_species <- regex_dictionary_update %>%
  filter(type == "Animal Species")

# Run regex
set_1_results_update_gene_corpus <- quanteda::corpus(set_1_results_update_gene$text, 
                                           docnames = set_1_results_update_gene$doc_id)

set_1_results_update_gene_tokens <- quanteda::tokens(set_1_results_update_gene_corpus, 
                                                     what = "sentence")
set_1_gene_species_result_update <- data.frame()
for (i in 1:nrow(regex_dictionary_update_species)){
  try(gene_species_match <- quanteda::kwic(set_1_results_update_gene_tokens, 
                                           regex_dictionary_update_species$regex[i], 
                                           window = 1, valuetype = "regex"))
  if(!is.null(gene_species_match)){
    gene_species_match <- as.data.frame(gene_species_match)
    gene_species_match$pattern <- as.character(gene_species_match$pattern)
    gene_species_match <- gene_species_match %>%
      mutate(name = regex_dictionary_update_species$name[i],
             type = regex_dictionary_update_species$type[i],
             match = stringr::str_extract(gene_species_match$keyword, gene_species_match$pattern))
    set_1_gene_species_result_update <- rbind(set_1_gene_species_result_update, gene_species_match)
  }
}

# Format result
set_1_gene_species_result_update <- set_1_gene_species_result_update %>%
  mutate(section = NA, paragraph = NA) %>%
  select(doc_id = docname, match, section, paragraph, sentence = from, text = keyword, name, type) %>%
  left_join(select(set_1_results_update_gene, c(doc_id, uid, format)), by = "doc_id")

# Merge all results together
set_1_results_update_gene_species <- rbind(set_1_results_update_gene %>%
                                             filter(doc_id %in% set_1_gene_species_result_update$doc_id) %>%
                                             select(-doc_id),
                                           set_1_gene_species_result_update %>%
                                             select(-doc_id),
                                           set_1_results_update %>%
                                             filter(type != "Model Gene") %>%
                                             filter(type != "Animal Species"))

# Save result
write.csv(set_1_results_update_gene_species, "regex/output/set_1_update_gene_species/set_1_results_update_gene_species.csv", row.names = F)

# Count matches
set_1_results_update_gene_species_counted <- set_1_results_update_gene_species %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_1_results_update_gene_species_collected <- set_1_results_update_gene_species_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  full_join(dat_set_1, by = "uid")

# Fix male and female tag
set_1_results_update_gene_species$name <- gsub("Both sexes", "Male; Female", set_1_results_update_gene_species$name)
set_1_results_update_gene_species <- set_1_results_update_gene_species %>%
  separate_rows(name, sep = "; ")


# Fix fear conditioning annotation
dat_set_1$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_1$tests)

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_1_results_update_gene_species_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_1, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_1, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_1, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_1, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_1_results_update_gene_species_long <- rbind(set_1_results_update_gene_species_long, df)
}

# Merge with regex data
# Get long format
set_1_results_update_gene_species_long <- set_1_results_update_gene_species_long %>%
  full_join(select(set_1_results_update_gene_species, c(uid, name, format, type, match)), 
            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_1_results_update_gene_species_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_1_results_update_gene_species_long <- set_1_results_update_gene_species_long %>%
  mutate(metric_1 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n == 0, "TN", 
                           ifelse(annotation == "Yes" & n >= 1, "TP", 
                                  ifelse(annotation == "Yes" & n == 0, "FN", "FP"))),
         metric_2 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 1, "TN", 
                           ifelse(annotation == "Yes" & n >= 2, "TP", 
                                  ifelse(annotation == "Yes" & n <= 1, "FN", "FP"))),
         metric_3 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 2, "TN", 
                           ifelse(annotation == "Yes" & n >= 3, "TP", 
                                  ifelse(annotation == "Yes" & n <= 2, "FN", "FP"))),
         metric_4 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 3, "TN", 
                           ifelse(annotation == "Yes" & n >= 4, "TP", 
                                  ifelse(annotation == "Yes" & n <= 3, "FN", "FP"))),
         metric_5 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 4, "TN", 
                           ifelse(annotation == "Yes" & n >= 5, "TP", 
                                  ifelse(annotation == "Yes" & n <= 4, "FN", "FP")))) %>%
  distinct()

# Get metrics at annotation level
set_1_results_update_gene_species_metrics_annotation <- rbind(
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  group_by(type, format, threshold) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type, threshold), 
              names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Write data
write.csv(set_1_results_update_gene_species_collected, "regex/output/set_1_update_gene_species/set_1_results_update_gene_species_collected.csv", row.names = F)
write.csv(set_1_results_update_gene_species_counted, "regex/output/set_1_update_gene_species/set_1_results_update_gene_species_counted.csv", row.names = F)
write.csv(set_1_results_update_gene_species_long, "regex/output/set_1_update_gene_species/set_1_results_update_gene_species_long.csv", row.names = F)
write.csv(set_1_results_update_gene_species_metrics_annotation, "regex/output/set_1_update_gene_species/set_1_results_update_gene_species_metrics_annotation.csv", row.names = F)

# Test Gene / Species Filtering (Same Format) ##################################

# Remove gene model matches where there is no animal species match in same format
# Remove animal species matches where there is no gene model match in same format

set_1_results_update_uid <- set_1_results_update %>% 
  filter(type == "Model Gene") %>% select(uid, type, format) %>% distinct() %>% 
  full_join(set_1_results_update %>% filter(type == "Animal Species") %>% 
                select(uid, type, format) %>% 
              distinct(), by = c("uid", "format")) %>% 
  filter(!is.na(type.x)) %>% filter(!is.na(type.y))
set_1_results_update_uid_tiab <- set_1_results_update_uid %>% filter(format == "tiab")
set_1_results_update_uid_pdf <- set_1_results_update_uid %>% filter(format == "pdf")
set_1_results_update_uid_txt <- set_1_results_update_uid %>% filter(format == "txt")
set_1_results_update_uid_xml <- set_1_results_update_uid %>% filter(format == "xml")
set_1_results_update_uid_xml_methods <- set_1_results_update_uid %>% filter(format == "xml_methods")

# Merge all results together
set_1_results_update_gene_species <- rbind(set_1_results_update %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "tiab") %>%
                                             filter(uid %in% set_1_results_update_uid_tiab$uid),
                                           set_1_results_update %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "pdf") %>%
                                             filter(uid %in% set_1_results_update_uid_pdf$uid),
                                           set_1_results_update %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "txt") %>%
                                             filter(uid %in% set_1_results_update_uid_txt$uid),
                                           set_1_results_update %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "xml") %>%
                                             filter(uid %in% set_1_results_update_uid_xml$uid),
                                           set_1_results_update %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "xml_methods") %>%
                                             filter(uid %in% set_1_results_update_uid_xml_methods$uid),
                                           set_1_results_update %>%
                                             filter(type != "Model Gene") %>%
                                             filter(type != "Animal Species"))

# Save result
write.csv(set_1_results_update_gene_species, "regex/output/set_1_update_gene_species_format/set_1_results_update_gene_species.csv", row.names = F)

# Count matches
set_1_results_update_gene_species_counted <- set_1_results_update_gene_species %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_1_results_update_gene_species_collected <- set_1_results_update_gene_species_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  full_join(dat_set_1, by = "uid")

# Fix male and female tag
set_1_results_update_gene_species$name <- gsub("Both sexes", "Male; Female", set_1_results_update_gene_species$name)
set_1_results_update_gene_species <- set_1_results_update_gene_species %>%
  separate_rows(name, sep = "; ")


# Fix fear conditioning annotation
dat_set_1$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_1$tests)

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_1_results_update_gene_species_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_1, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_1, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_1, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_1, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_1_results_update_gene_species_long <- rbind(set_1_results_update_gene_species_long, df)
}

# Merge with regex data
# Get long format
set_1_results_update_gene_species_long <- set_1_results_update_gene_species_long %>%
  full_join(select(set_1_results_update_gene_species, c(uid, name, format, type, match)), 
            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_1_results_update_gene_species_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_1_results_update_gene_species_long <- set_1_results_update_gene_species_long %>%
  mutate(metric_1 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n == 0, "TN", 
                           ifelse(annotation == "Yes" & n >= 1, "TP", 
                                  ifelse(annotation == "Yes" & n == 0, "FN", "FP"))),
         metric_2 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 1, "TN", 
                           ifelse(annotation == "Yes" & n >= 2, "TP", 
                                  ifelse(annotation == "Yes" & n <= 1, "FN", "FP"))),
         metric_3 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 2, "TN", 
                           ifelse(annotation == "Yes" & n >= 3, "TP", 
                                  ifelse(annotation == "Yes" & n <= 2, "FN", "FP"))),
         metric_4 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 3, "TN", 
                           ifelse(annotation == "Yes" & n >= 4, "TP", 
                                  ifelse(annotation == "Yes" & n <= 3, "FN", "FP"))),
         metric_5 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 4, "TN", 
                           ifelse(annotation == "Yes" & n >= 5, "TP", 
                                  ifelse(annotation == "Yes" & n <= 4, "FN", "FP")))) %>%
  distinct()

# Get metrics at annotation level
set_1_results_update_gene_species_metrics_annotation <- rbind(
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_1_results_update_gene_species_long, c(type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  group_by(type, format, threshold) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type, threshold), 
              names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Write data
write.csv(set_1_results_update_gene_species_collected, "regex/output/set_1_update_gene_species_format/set_1_results_update_gene_species_collected.csv", row.names = F)
write.csv(set_1_results_update_gene_species_counted, "regex/output/set_1_update_gene_species_format/set_1_results_update_gene_species_counted.csv", row.names = F)
write.csv(set_1_results_update_gene_species_long, "regex/output/set_1_update_gene_species_format/set_1_results_update_gene_species_long.csv", row.names = F)
write.csv(set_1_results_update_gene_species_metrics_annotation, "regex/output/set_1_update_gene_species_format/set_1_results_update_gene_species_metrics_annotation.csv", row.names = F)



# Test Gene / Species Filtering (Format) On Other Regexes ######################

# Merge all results together
set_1_results_update_gene_species_filter <- rbind(set_1_results_update %>%
                                                    filter(type == "Model Gene" | type == "Animal Species") %>%
                                                    filter(format == "tiab") %>%
                                                    filter(uid %in% set_1_results_update_uid_tiab$uid),
                                                  set_1_results_update %>%
                                                    filter(type == "Model Gene" | type == "Animal Species") %>%
                                                    filter(format == "pdf") %>%
                                                    filter(uid %in% set_1_results_update_uid_pdf$uid),
                                                  set_1_results_update %>%
                                                    filter(type == "Model Gene" | type == "Animal Species") %>%
                                                    filter(format == "txt") %>%
                                                    filter(uid %in% set_1_results_update_uid_txt$uid),
                                                  set_1_results_update %>%
                                                    filter(type == "Model Gene" | type == "Animal Species") %>%
                                                    filter(format == "xml") %>%
                                                    filter(uid %in% set_1_results_update_uid_xml$uid),
                                                  set_1_results_update %>%
                                                    filter(type == "Model Gene" | type == "Animal Species") %>%
                                                    filter(format == "xml_methods") %>%
                                                    filter(uid %in% set_1_results_update_uid_xml_methods$uid),
                                                  set_1_results_update %>%
                                                    filter(type != "Model Gene") %>%
                                                    filter(type != "Animal Species") %>%
                                                    filter(uid %in% set_1_results_update_uid_tiab$uid))
# Save result
write.csv(set_1_results_update_gene_species_filter, "regex/output/set_1_update_gene_species_filter/set_1_results_update_gene_species_filter.csv", row.names = F)

# Count matches
set_1_results_update_gene_species_filter_counted <- set_1_results_update_gene_species_filter %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_1_results_update_gene_species_filter_collected <- set_1_results_update_gene_species_filter_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  full_join(dat_set_1, by = "uid")

# Fix male and female tag
set_1_results_update_gene_species_filter$name <- gsub("Both sexes", "Male; Female", set_1_results_update_gene_species_filter$name)
set_1_results_update_gene_species_filter <- set_1_results_update_gene_species_filter %>%
  separate_rows(name, sep = "; ")


# Fix fear conditioning annotation
dat_set_1$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_1$tests)

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_1_results_update_gene_species_filter_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_1, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_1, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_1, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_1, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_1_results_update_gene_species_filter_long <- rbind(set_1_results_update_gene_species_filter_long, df)
}

# Merge with regex data
# Get long format
set_1_results_update_gene_species_filter_long <- set_1_results_update_gene_species_filter_long %>%
  full_join(select(set_1_results_update_gene_species_filter, c(uid, name, format, type, match)), 
            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_1_results_update_gene_species_filter_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_1_results_update_gene_species_filter_long <- set_1_results_update_gene_species_filter_long %>%
  mutate(metric_1 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n == 0, "TN", 
                           ifelse(annotation == "Yes" & n >= 1, "TP", 
                                  ifelse(annotation == "Yes" & n == 0, "FN", "FP"))),
         metric_2 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 1, "TN", 
                           ifelse(annotation == "Yes" & n >= 2, "TP", 
                                  ifelse(annotation == "Yes" & n <= 1, "FN", "FP"))),
         metric_3 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 2, "TN", 
                           ifelse(annotation == "Yes" & n >= 3, "TP", 
                                  ifelse(annotation == "Yes" & n <= 2, "FN", "FP"))),
         metric_4 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 3, "TN", 
                           ifelse(annotation == "Yes" & n >= 4, "TP", 
                                  ifelse(annotation == "Yes" & n <= 3, "FN", "FP"))),
         metric_5 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 4, "TN", 
                           ifelse(annotation == "Yes" & n >= 5, "TP", 
                                  ifelse(annotation == "Yes" & n <= 4, "FN", "FP")))) %>%
  distinct()

# Get metrics at annotation level
set_1_results_update_gene_species_filter_metrics_annotation <- rbind(
  select(set_1_results_update_gene_species_filter_long, c(type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_1_results_update_gene_species_filter_long, c(type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_1_results_update_gene_species_filter_long, c(type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_1_results_update_gene_species_filter_long, c(type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_1_results_update_gene_species_filter_long, c(type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  group_by(type, format, threshold) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type, threshold), 
              names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Write data
write.csv(set_1_results_update_gene_species_filter_collected, "regex/output/set_1_update_gene_species_filter/set_1_results_update_gene_species_filter_collected.csv", row.names = F)
write.csv(set_1_results_update_gene_species_filter_counted, "regex/output/set_1_update_gene_species_filter/set_1_results_update_gene_species_filter_counted.csv", row.names = F)
write.csv(set_1_results_update_gene_species_filter_long, "regex/output/set_1_update_gene_species_filter/set_1_results_update_gene_species_filter_long.csv", row.names = F)
write.csv(set_1_results_update_gene_species_filter_metrics_annotation, "regex/output/set_1_update_gene_species_filter/set_1_results_update_gene_species_filter_metrics_annotation.csv", row.names = F)


# Test Animal Sex Filtering ####################################################

# Subset results
set_1_results_update_sex <- set_1_results_update %>%
  filter(type == "Animal Sex") %>%
  mutate(doc_id = as.character(1:n())) 

# Subset species regexes
regex_dictionary_update_sex <- "(?i)(was|were|we) (only )?(included|analy(s|z)ed|used|conducted|assessed|generated)"

# Run regex
set_1_results_update_sex_corpus <- quanteda::corpus(set_1_results_update_sex$text, 
                                                     docnames = set_1_results_update_sex$doc_id)

set_1_results_update_sex_tokens <- quanteda::tokens(set_1_results_update_sex_corpus, 
                                                     what = "sentence")
set_1_sex_result_update <- data.frame()
for (i in 1:length(regex_dictionary_update_sex)){
  try(sex_match <- quanteda::kwic(set_1_results_update_sex_tokens, 
                                           regex_dictionary_update_sex, 
                                           window = 1, valuetype = "regex"))
  if(!is.null(sex_match)){
    sex_match <- as.data.frame(sex_match)
    sex_match$pattern <- as.character(sex_match$pattern)
    sex_match <- sex_match %>%
      mutate(name = NA,
             type = NA,
             match = stringr::str_extract(sex_match$keyword, sex_match$pattern))
    set_1_sex_result_update <- rbind(set_1_sex_result_update, sex_match)
  }
}

# Merge all results together
set_1_results_update_sex <- rbind(set_1_results_update_sex %>%
                                             filter(doc_id %in% set_1_sex_result_update$docname) %>%
                                             select(-doc_id),
                                           set_1_results_update %>%
                                             filter(type != "Animal Sex"))

# Save result
write.csv(set_1_results_update_sex, "regex/output/set_1_update_sex/set_1_results_update_sex.csv", row.names = F)

# Count matches
set_1_results_update_sex_counted <- set_1_results_update_sex %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_1_results_update_sex_collected <- set_1_results_update_sex_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  full_join(dat_set_1, by = "uid")

# Fix male and female tag
set_1_results_update_sex$name <- gsub("Both sexes", "Male; Female", set_1_results_update_sex$name)
set_1_results_update_sex <- set_1_results_update_sex %>%
  separate_rows(name, sep = "; ")


# Fix fear conditioning annotation
dat_set_1$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_1$tests)

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_1_results_update_sex_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_1, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_1, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_1, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_1, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_1_results_update_sex_long <- rbind(set_1_results_update_sex_long, df)
}

# Merge with regex data
# Get long format
set_1_results_update_sex_long <- set_1_results_update_sex_long %>%
  full_join(select(set_1_results_update_sex, c(uid, name, format, type, match)), 
            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_1_results_update_sex_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_1_results_update_sex_long <- set_1_results_update_sex_long %>%
  mutate(metric_1 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n == 0, "TN", 
                           ifelse(annotation == "Yes" & n >= 1, "TP", 
                                  ifelse(annotation == "Yes" & n == 0, "FN", "FP"))),
         metric_2 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 1, "TN", 
                           ifelse(annotation == "Yes" & n >= 2, "TP", 
                                  ifelse(annotation == "Yes" & n <= 1, "FN", "FP"))),
         metric_3 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 2, "TN", 
                           ifelse(annotation == "Yes" & n >= 3, "TP", 
                                  ifelse(annotation == "Yes" & n <= 2, "FN", "FP"))),
         metric_4 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 3, "TN", 
                           ifelse(annotation == "Yes" & n >= 4, "TP", 
                                  ifelse(annotation == "Yes" & n <= 3, "FN", "FP"))),
         metric_5 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 4, "TN", 
                           ifelse(annotation == "Yes" & n >= 5, "TP", 
                                  ifelse(annotation == "Yes" & n <= 4, "FN", "FP")))) %>%
  distinct()

# Get metrics at annotation level
set_1_results_update_sex_metrics_annotation <- rbind(
  select(set_1_results_update_sex_long, c(type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_1_results_update_sex_long, c(type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_1_results_update_sex_long, c(type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_1_results_update_sex_long, c(type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_1_results_update_sex_long, c(type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  group_by(type, format, threshold) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type, threshold), 
              names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Write data
write.csv(set_1_results_update_sex_collected, "regex/output/set_1_update_sex/set_1_results_update_sex_collected.csv", row.names = F)
write.csv(set_1_results_update_sex_counted, "regex/output/set_1_update_sex/set_1_results_update_sex_counted.csv", row.names = F)
write.csv(set_1_results_update_sex_long, "regex/output/set_1_update_sex/set_1_results_update_sex_long.csv", row.names = F)
write.csv(set_1_results_update_sex_metrics_annotation, "regex/output/set_1_update_sex/set_1_results_update_sex_metrics_annotation.csv", row.names = F)

# Run Regexes on Set 2 #########################################################

# Get dat set 2
dat_set_2 <- dat_annotated %>% filter(set == 2)

# Fix fear conditioning annotation
dat_set_2$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_2$tests)

# Create empty dataframes 
set_2_tiab <- data_frame()
set_2_xml <- data.frame()
set_2_txt <- data.frame()
set_2_pdf <- data.frame()

# Read in XML
for (i in 1:nrow(dat_set_2)){
  xml <- xml2::read_xml(dat_set_2$xml_path[i])
  xml <- tidypmc::pmc_text(xml) %>%
    mutate(uid = dat_set_2$uid[i])
  set_2_xml <- rbind(set_2_xml, xml)
}

# Read in TXT
for (i in 1:nrow(dat_set_2)){
  txt <- readtext::readtext(dat_set_2$txt_path[i]) %>% mutate(doc_id = dat_set_2$uid[i])
  set_2_txt <- rbind(set_2_txt, txt)
}

# Read in PDF (using readtext/pdftools PDF to TXT)
for (i in 1:nrow(dat_set_2)){
  pdf <- readtext::readtext(dat_set_2$pdf_path[i]) %>% mutate(doc_id = dat_set_2$uid[i])
  set_2_pdf <- rbind(set_2_pdf, pdf)
}

# Get title and abstract text
set_2_tiab <- dat_set_2 %>% select(uid, title, abstract)
set_2_tiab$text <- paste(set_2_tiab$title, set_2_tiab$abstract, sep = ". ")
set_2_tiab$text <- gsub("\\.\\.|\\. \\.", ".", set_2_tiab$text)
set_2_tiab <- set_2_tiab %>% select(uid, text)

# Create empty dataframes
set_2_tiab_result <- data.frame()
set_2_xml_result <- data.frame()
set_2_txt_result <- data.frame()
set_2_pdf_result <- data.frame()

# Run regexes on XML
for (i in 1:nrow(regex_dictionary_update)){
  try(xml_match <- tidypmc::separate_text(set_2_xml, regex_dictionary_update$regex[i]))
  if(!is.null(xml_match)){
    xml_match <- xml_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i])
    set_2_xml_result <- rbind(set_2_xml_result, xml_match)
  }
}

# Subset XML methods section
set_2_xml_result_methods <- set_2_xml_result %>%
  filter(stringr::str_detect(section, regex("\\bmethod|\\bprocedure|\\bmaterial", ignore_case = TRUE)))

# Run regex on TXT
txt_corpus <- quanteda::corpus(set_2_txt)
txt_tokens <- quanteda::tokens(txt_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary_update)){
  try(txt_match <- quanteda::kwic(txt_tokens, regex_dictionary_update$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(txt_match)){
    txt_match <- as.data.frame(txt_match)
    txt_match$pattern <- as.character(txt_match$pattern)
    txt_match <- txt_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i],
             match = stringr::str_extract(txt_match$keyword, txt_match$pattern))
    set_2_txt_result <- rbind(set_2_txt_result, txt_match)
  }
}

# Run regex on PDF
pdf_corpus <- quanteda::corpus(set_2_pdf)
pdf_tokens <- quanteda::tokens(pdf_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary_update)){
  try(pdf_match <- quanteda::kwic(pdf_tokens, regex_dictionary_update$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(pdf_match)){
    pdf_match <- as.data.frame(pdf_match)
    pdf_match$pattern <- as.character(pdf_match$pattern)
    pdf_match <- pdf_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i],
             match = stringr::str_extract(pdf_match$keyword, pdf_match$pattern))
    set_2_pdf_result <- rbind(set_2_pdf_result, pdf_match)
  }
}

# Run regex on tiab
tiab_corpus <- quanteda::corpus(set_2_tiab$text, docnames = set_2_tiab$uid)
tiab_tokens <- quanteda::tokens(tiab_corpus, what = "sentence")
for (i in 1:nrow(regex_dictionary_update)){
  try(tiab_match <- quanteda::kwic(tiab_tokens, regex_dictionary_update$regex[i], window = 1, valuetype = "regex"))
  if(!is.null(tiab_match)){
    tiab_match <- as.data.frame(tiab_match)
    tiab_match$pattern <- as.character(tiab_match$pattern)
    tiab_match <- tiab_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i],
             match = stringr::str_extract(tiab_match$keyword, tiab_match$pattern))
    set_2_tiab_result <- rbind(set_2_tiab_result, tiab_match)
  }
}

# Format results
set_2_results <- rbind(rbind(set_2_pdf_result %>% mutate(format = "pdf"),
                             set_2_txt_result %>% mutate(format = "txt"),
                             set_2_tiab_result %>% mutate(format = "tiab")) %>%
                         mutate(section = NA,
                                paragraph = NA) %>%
                         select(match, section, paragraph, sentence = from, text = keyword, 
                                uid = docname, name, type, format),
                       mutate(set_2_xml_result, format = "xml"),
                       mutate(set_2_xml_result_methods, format = "xml_methods"))

# Note records without methods
no_methods <- dat_set_2 %>% filter(!uid %in% set_2_xml_result_methods$uid)

# Save results
write.csv(set_2_results, "regex/output/set_2_update/set_2_results_update.csv", row.names = F)

# Remove gene model matches where there is no animal species match in same format
# Remove animal species matches where there is no gene model match in same format

set_2_results_uid <- set_2_results %>% 
  filter(type == "Model Gene") %>% select(uid, type, format) %>% distinct() %>% 
  full_join(set_2_results %>% filter(type == "Animal Species") %>% 
              select(uid, type, format) %>% 
              distinct(), by = c("uid", "format")) %>% 
  filter(!is.na(type.x)) %>% filter(!is.na(type.y))
set_2_results_uid_tiab <- set_2_results_uid %>% filter(format == "tiab")
set_2_results_uid_pdf <- set_2_results_uid %>% filter(format == "pdf")
set_2_results_uid_txt <- set_2_results_uid %>% filter(format == "txt")
set_2_results_uid_xml <- set_2_results_uid %>% filter(format == "xml")
set_2_results_uid_xml_methods <- set_2_results_uid %>% filter(format == "xml_methods")

# Merge all results together
set_2_results_gene_species_filter <- rbind(set_2_results %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "tiab") %>%
                                             filter(uid %in% set_2_results_uid_tiab$uid),
                                           set_2_results %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "pdf") %>%
                                             filter(uid %in% set_2_results_uid_pdf$uid),
                                           set_2_results %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "txt") %>%
                                             filter(uid %in% set_2_results_uid_txt$uid),
                                           set_2_results %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "xml") %>%
                                             filter(uid %in% set_2_results_uid_xml$uid),
                                           set_2_results %>%
                                             filter(type == "Model Gene" | type == "Animal Species") %>%
                                             filter(format == "xml_methods") %>%
                                             filter(uid %in% set_2_results_uid_xml_methods$uid),
                                           set_2_results %>%
                                             filter(type != "Model Gene") %>%
                                             filter(type != "Animal Species") %>%
                                             filter(uid %in% set_2_results_uid_tiab$uid))

# Save result
write.csv(set_2_results_gene_species_filter, "regex/output/set_2_update/set_2_results_update_gene_species.csv", row.names = F)

# Analyse Set 2 Update Results #################################################

# Count matches
set_2_results_counted <- set_2_results_gene_species_filter %>%
  select(uid, format, type, name) %>%
  group_by(uid, format, type) %>%
  count(name)

# Collect matches
set_2_results_collected <- set_2_results_counted %>%
  select(-n) %>%
  group_by(uid, format, type) %>%
  tidyr::pivot_wider(id_cols = uid, names_from = c(type, format), values_from = name,
                     values_fn = ~paste(., collapse = "; ")) %>%
  full_join(dat_set_2, by = "uid")

# Fix male and female tag
set_2_results_gene_species_filter$name <- gsub("Both sexes", "Male; Female", set_2_results_gene_species_filter$name)
set_2_results_gene_species_filter <- set_2_results_gene_species_filter %>%
  separate_rows(name, sep = "; ")


# Fix fear conditioning annotation
dat_set_2$tests <- gsub("Contextual or Cue Fear Conditioning|Delayed Fear Conditioning",
                        "Fear Conditioning", dat_set_2$tests)

# Get long format for matching
# make sure there is a format for each
format <- c("tiab", "txt", "pdf", "xml", "xml_methods")
set_2_results_long <- data.frame()
for(i in 1:5){
  df <- rbind(select(dat_set_2, c(uid, name = model_gene)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Model Gene"), 
              select(dat_set_2, c(uid, name = species)) %>%
                mutate(type = "Animal Species"), 
              select(dat_set_2, c(uid, name = sex)) %>%
                separate_rows(name, sep="; ") %>%
                mutate(type = "Animal Sex"), 
              select(dat_set_2, c(uid, name = tests)) %>% 
                separate_rows(name, sep="; ") %>%
                mutate(type = "Experimental Test")) %>%
    mutate(annotation = "Yes") %>%
    replace(is.na(.), "Paper Not Relevant") %>%
    mutate(format = format[i])
  set_2_results_long <- rbind(set_2_results_long, df)
}

# Merge with regex data
# Get long format
set_2_results_long <- set_2_results_long %>%
  full_join(select(set_2_results_gene_species_filter, c(uid, name, format, type, match)), 
            by = c("uid", "name", "type", "format")) %>%
  distinct() %>%
  # Make annotation yes / no
  mutate_at(vars(annotation), ~replace_na(., "No")) %>%
  # add column to deal with no regex matches
  mutate(matched = ifelse(is.na(match), "No", "Yes")) %>%
  select(-match) %>%
  distinct() %>%
  left_join(set_2_results_counted, by = c("uid", "name", "type", "format")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

# Fix instances where regex is not matched
set_2_results_long <- set_2_results_long %>%
  mutate(metric_1 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n == 0, "TN", 
                           ifelse(annotation == "Yes" & n >= 1, "TP", 
                                  ifelse(annotation == "Yes" & n == 0, "FN", "FP"))),
         metric_2 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 1, "TN", 
                           ifelse(annotation == "Yes" & n >= 2, "TP", 
                                  ifelse(annotation == "Yes" & n <= 1, "FN", "FP"))),
         metric_3 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 2, "TN", 
                           ifelse(annotation == "Yes" & n >= 3, "TP", 
                                  ifelse(annotation == "Yes" & n <= 2, "FN", "FP"))),
         metric_4 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 3, "TN", 
                           ifelse(annotation == "Yes" & n >= 4, "TP", 
                                  ifelse(annotation == "Yes" & n <= 3, "FN", "FP"))),
         metric_5 = ifelse(str_detect(name, "Paper Not Relevant|Not reported|None") & n <= 4, "TN", 
                           ifelse(annotation == "Yes" & n >= 5, "TP", 
                                  ifelse(annotation == "Yes" & n <= 4, "FN", "FP")))) %>%
  distinct()

# Get metrics at annotation level
set_2_results_metrics_annotation <- rbind(
  select(set_2_results_long, c(type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_2_results_long, c(type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_2_results_long, c(type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_2_results_long, c(type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_2_results_long, c(type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  group_by(type, format, threshold) %>%
  count(metric) %>%
  pivot_wider(id_cols = c(format, type, threshold), 
              names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Get metrics at publication level 
set_2_results_metrics_publication <- rbind(
  select(set_2_results_long, c(uid, type, format, metric = metric_1)) %>%
    mutate(threshold = 1),
  select(set_2_results_long, c(uid, type, format, metric = metric_2)) %>%
    mutate(threshold = 2),
  select(set_2_results_long, c(uid, type, format, metric = metric_3)) %>%
    mutate(threshold = 3),
  select(set_2_results_long, c(uid, type, format, metric = metric_4)) %>%
    mutate(threshold = 4),
  select(set_2_results_long, c(uid, type, format, metric = metric_5)) %>%
    mutate(threshold = 5)
) %>%
  # pivot wider for comparison
  pivot_wider(id_cols = uid, names_from = c(format, type, threshold), 
              values_from = metric,
              values_fn = ~paste(., collapse = "; ")) %>%
  replace(is.na(.), "TN") %>%
  # clean metrics to assign each paper only one value
  # If any of the regexes got a FN, change to FN
  mutate(across(everything(), ~ ifelse(str_detect(., "FN"), "FN", .))) %>%
  # If any of the regexes got a FP, change to FP
  mutate(across(everything(), ~ ifelse(str_detect(., "FP"), "FP", .))) %>%
  # If there were multiple TP, change to TP
  mutate(across(everything(), ~ ifelse(str_detect(., "TP"), "TP", .))) %>%
  # Pivot longer again for counting
  pivot_longer(!uid, names_to = "format", values_to = "metric") %>%
  # Count confusion matrix
  count(format, metric) %>%
  filter(!str_detect(format, "^No")) %>%
  pivot_wider(id_cols = format, names_from = metric, values_from = n) %>%
  replace(is.na(.), 0) %>%
  select(format, TP, TN, FP, FN) %>%
  mutate(recall = TP / (TP + FN),
         specificity = TN / (TN + FP),
         precision = TP / (TP + FP),
         F1 = (2 * precision * recall) / (precision + recall),
         F2 = (1 + 2^2) * ((precision * recall) / ((2^2 * precision) + recall)))

# Write data
write.csv(set_2_results_collected, "regex/output/set_2_update/set_2_results_update_collected.csv", row.names = F)
write.csv(set_2_results_counted, "regex/output/set_2_update/set_2_results_update_counted.csv", row.names = F)
write.csv(set_2_results_long, "regex/output/set_2_update/set_2_results_update_long.csv", row.names = F)
write.csv(set_2_results_metrics_annotation, "regex/output/set_2_update/set_2_results_update_metrics_annotation.csv", row.names = F)
write.csv(set_2_results_metrics_publication, "regex/output/set_2_update/set_2_results_update_metrics_publication.csv", row.names = F)
