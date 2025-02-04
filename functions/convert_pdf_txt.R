convert_pdf_txt <- function(con, path = "full_texts"){
  
  # Get full text pdfs without txt
  pdf_missing_txt <- dbReadTable(con, "full_texts_clean") %>%
    filter(!is.na(path_pdf)) %>%
    filter(is.na(path_txt))
  
  # Read in pdf to text
  for(i in 1:nrow(pdf_missing_txt)){
    tryCatch({
      # Attempt to read the PDF
      txt <- readtext::readtext(pdf_missing_txt$path_pdf[i])
      
      # If reading was successful, process the file
      if(exists("txt")){
        file_name <- gsub("\\.pdf", ".txt", pdf_missing_txt$path_pdf[i])
        writeLines(txt$text, file_name)
        pdf_missing_txt$path_txt[i] <- file_name
        rm(txt, file_name)
        print(paste("Converted pdf to txt:", pdf_missing_txt$path_pdf[i]))
      }
    }, error = function(e) {
      # Handle the error and print a message, continue to the next iteration
      print(paste("Error reading PDF file:", pdf_missing_txt$path_pdf[i]))
    })
  }
  
  # Get files were pdf was converted
  pdf_converted_txt <- pdf_missing_txt %>%
    filter(!is.na(path_txt))
  
  # Update clean dataset
  full_texts_clean <- dbReadTable(con, "full_texts_clean") %>%
    filter(!doi %in% pdf_converted_txt$doi) %>%
    rbind(pdf_converted_txt)
  
  # Overwrite table
  dbWriteTable(con, "full_texts_clean", full_texts_clean, overwrite = T)
}