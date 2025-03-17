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

# Get regex dictionary
regex_dictionary_update <- read.csv("regex/ndc_regexes_update.csv",
                                    stringsAsFactors = F)

# Get included studies
inc <- tbl(con, "study_classification") %>% filter(decision == "include") %>%
  left_join(tbl(con, "unique_citations"), by = "uid") %>%
  collect() %>%
  select(uid, doi, title, abstract)

# Combine title and abstract text
inc$text <- paste(inc$title, inc$abstract, sep = ". ")
inc$text <- gsub("\\.\\.|\\. \\.", ".", inc$text)
inc <- inc %>% select(uid, doi, text)

# Create empty dataframes
inc_tiab_result <- data.frame()
inc_xml_result <- data.frame()
inc_pdf_result <- data.frame()

# Run regex on tiab
tiab_corpus <- quanteda::corpus(inc$text, docnames = inc$uid)
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
    inc_tiab_result <- rbind(inc_tiab_result, tiab_match)
  }
}

# Get xml full texts
xml_text <- dbReadTable(con, "xml_texts") %>%
  select(doi, path) %>%
  filter(!is.na(path))

# Read in XML
xml_texts <- data.frame()
for (i in 1:nrow(xml_text)){
  xml <- xml2::read_xml(xml_text$path[i])
  xml <- tidypmc::pmc_text(xml) %>%
    mutate(doc_id = xml_text$doi[i])
  xml_texts <- rbind(xml_texts, xml)
}

# Run regexes on XML
for (i in 1:nrow(regex_dictionary_update)){
  try(xml_match <- tidypmc::separate_text(xml_texts, regex_dictionary_update$regex[i]))
  if(!is.null(xml_match)){
    xml_match <- xml_match %>%
      mutate(name = regex_dictionary_update$name[i],
             type = regex_dictionary_update$type[i])
    inc_xml_result <- rbind(inc_xml_result, xml_match)
  }
}

# Get pdf full texts
pdf_text <- dbReadTable(con, "full_texts") %>%
  select(doi, path) %>%
  filter(!is.na(path)) %>%
  filter(doi %in% inc$doi)
pdf_text$path <- gsub("\\.txt", ".pdf", pdf_text$path)
pdf_folder <- list.files("full_texts", pattern = ".pdf", full.names = T)
pdf_text <- pdf_text %>%
  filter(path %in% pdf_folder)

# Read in pdf to text
pdf_texts <- data.frame()
for (i in 1:nrow(pdf_text)){
  try(pdf <- readtext::readtext(pdf_text$path[i]) %>% mutate(doc_id = pdf_text$doi[i]))
  pdf_texts <- rbind(pdf_texts, pdf)
}

# Run regex on PDF
pdf_corpus <- quanteda::corpus(pdf_texts)
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
    inc_pdf_result <- rbind(inc_pdf_result, pdf_match)
  }
}

# Read in regex ontology
regex_ontology <- dbReadTable(con, "pico_ontology") %>%
  select(name, regex_id)

# Format data
inc_tiab_result <- inc_tiab_result %>%
  left_join(regex_ontology, by = "name") %>%
  mutate(method = "tiab") %>%
  select(uid = docname, regex_id, string = keyword, method)

inc_xml_result <- inc_xml_result %>%
  left_join(regex_ontology, by = "name") %>%
  mutate(method = "fultltext_xml") %>%
  select(uid = doc_id, regex_id, string = text, method)

inc_pdf_result <- inc_pdf_result %>%
  left_join(regex_ontology, by = "name") %>%
  mutate(method = "fultltext_pdf") %>%
  select(uid = docname, regex_id, string = keyword, method)

# Combine data
inc_results <- rbind(inc_tiab_result, inc_xml_result, inc_pdf_result)

# Write to database
dbWriteTable(con, "pico_tag", inc_results, append = T)