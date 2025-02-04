get_xml <- function(con, path = "xml_texts"){
  
  # Read in existing metadata
  if (!dbExistsTable(con, "xml_texts")){
    xml_found <- data.frame(pmcid = as.character(),
                            pmid = as.numeric(),
                            doi = as.character(),
                            path = as.character())
  } else{
    xml_found <- dbReadTable(con, "xml_texts")
  }
  
  # Read in included data with DOI and filter for DOIs were XML has not been retrieved
  dat <- tbl(con, "study_classification") %>%
    filter(decision == "include") %>%
    left_join(tbl(con, "unique_citations"), by = "uid") %>%
    select(uid, doi) %>%
    filter(!is.na(doi)) %>%
    collect() %>%
    filter(!doi %in% xml_found$doi)
  
  # Calculate how many to retrieve
  if(length(dat$doi) < 1) {
    message("Done!")
    return()
  } else {
    message("Tagging all remaining records...")
  }
  
  # Create vecotr of unique DOIs to be searched for
  doi <- dat$doi
  
  # Initiate pmcid results dataframe
  pmcid <- data.frame()
  
  # Use CrossRef to get PMCID from DOI
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
  
  # Save data and make vector
  xml_texts <- pmcid
  pmcid <- pmcid$pmcid
  
  # Initiate results dataframe
  xml_path <- data.frame()
  
  # Retrieve XML full texts
  for (i in 1:length(pmcid)){
    # Try to download XML
    tryCatch({
      xml_result <- europepmc::epmc_ftxt(ext_id = pmcid[i])
      # Save as file if it exists
      xml2::write_xml(xml_result, paste0("xml_texts/",pmcid[i],".xml"))
      # Remove from environment
      rm(xml_result)
      # Save file path
      xml_path <- data.frame(pmcid = pmcid[i], path = paste0("xml_texts/",pmcid[i],".xml"))
      # Print message
      print(paste("Downloaded XML file for pmcid:", pmcid[i]))
    }, error = function(e) {
      # Print a message if there's an error
      print(paste("Error occurred for pmcid:", pmcid[i]))
    })
    # Sleep for 6 seconds
    Sys.sleep(6)
  }
  
  # Combine XML results
  xml_texts <- xml_texts %>%
    left_join(xml_path, by = "pmcid")
  
  # Save results
  dbWriteTable(con, "xml_tests", xml_texts, append = T)
  
}