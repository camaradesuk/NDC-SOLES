clean_ft <- function(con, path = "full_texts"){
  
  # Remove any JSON or XML metadata files from folder
  file.remove(list.files(path, pattern = ".json", full.names = T))
  file.remove(list.files(path, pattern = ".xml", full.names = T))
  
  # List pdf and txt files
  file_pdf <- list.files(path, pattern = ".pdf", full.names = T)
  file_txt <- list.files(path, pattern = ".txt", full.names = T)
  
  # Get included data with dois
  dat <- tbl(con, "study_classification") %>%
    filter(decision == "include") %>%
    left_join(tbl(con, "unique_citations"), by = "uid") %>%
    select(uid, doi) %>%
    filter(!is.na(doi)) %>%
    collect()
  
  # Read in full_texts table and create separate columns
  full_texts <- dbReadTable(con, "full_texts") %>%
    filter(doi %in% dat$doi) %>%
    mutate(path_pdf = gsub("\\.(txt|json|xml)", ".pdf", path),
           path_txt = gsub("\\.(pdf|json|xml)", ".txt", path)) %>%
    select(-path)
  
  # Work out which files exist
  full_texts_pdf <- full_texts %>% filter(path_pdf %in% file_pdf) %>% select(doi, path_pdf)
  full_texts_txt <- full_texts %>% filter(path_txt %in% file_txt) %>% select(doi, path_txt)
  
  # Clean dataset
  full_texts_clean <- full_texts %>%
    select(doi) %>%
    left_join(full_texts_pdf, by = "doi") %>%
    left_join(full_texts_txt, by = "doi") %>%
    mutate(status = ifelse(!is.na(path_pdf) | !is.na(path_txt), "found", "failed"))
  
  # Write to table
  dbWriteTable(con, "full_texts_clean", full_texts_clean, overwrite = T)
  
  # Remove files not in included data
  file_pdf_remove <- data.frame(file_pdf) %>% filter(!file_pdf %in% full_texts_clean$path_pdf)
  file_txt_remove <- data.frame(file_txt) %>% filter(!file_txt %in% full_texts_clean$path_txt)
  file.remove(file_pdf_remove$file_pdf)
  file.remove(file_txt_remove$file_txt)
  
  #
}
