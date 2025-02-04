# ==============================================================================
# NDC-SOLES Workflow
# ==============================================================================

# This code is used to run the SOLES workflow for the NDC-SOLES project.
# Most of the functions come from the SOLES package.
# Access to the SQL database and James Thomas Machine Learning API are required.

# ------------------------------------------------------------------------------
# Load R Packages and Connect to Database
# ------------------------------------------------------------------------------

# GitHub R packages
library(soles)
library(AutoAnnotation)

# Cran R packages
library(dplyr)
library(readr)
library(DBI)
library(rcrossref)
library(roadoi)
library(purrr)
library(tidyr)
library(openalexR)
library(parallel)
library(lubridate)

# Extra functions
source("functions/run_ml_at_threshold.R")

# Set database connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = Sys.getenv("ndc_soles_dbname"),
                 host = Sys.getenv("ndc_soles_host"), 
                 port = 5432,
                 user = Sys.getenv("ndc_soles_user"),
                 password = Sys.getenv("ndc_soles_password"))

# ------------------------------------------------------------------------------
# Weekly Systematic Searches
# ------------------------------------------------------------------------------

# Database queries
query_pubmed <- "((neurodevelopmental disorders[MeSH] OR 'neurodevelopmental disorder*'[tiab] OR 'neurodevelopmental delay*'[tiab] OR 'delayed neurodevelopment'[tiab] OR intellectual disability[MeSH] OR 'intellectual disabilit*'[tiab] OR epilepsy[MeSH] OR epilepsy[tiab] OR autism spectrum disorder[MeSH] OR ASD[tiab] OR autism[tiab] OR autistic[tiab] OR CHD8[TiAb] OR SCN2A[TiAb] OR SYNGAP1[TiAb] OR ADNP[TiAb] OR FOXP1[TiAb] OR POGZ[TiAb] OR ARID1B[TiAb] OR SUV420H1[TiAb] OR DYRK1A[TiAb] OR SLC6A1[TiAb] OR GRIN2B[TiAb] OR PTEN[TiAb] OR SHANK3[TiAb] OR MED13L[TiAb] OR GIGYF1[TiAb] OR CHD2[TiAb] OR ANKRD11[TiAb] OR ANK2[TiAb] OR ASH1L[TiAb] OR TLK2[TiAb] OR DNMT3A[TiAb] OR DEAF1[TiAb] OR CTNNB1[TiAb] OR KDM6B[TiAb] OR DSCAM[TiAb] OR SETD5[TiAb] OR KCNQ3[TiAb] OR SRPR[TiAb] OR KDM5B[TiAb] OR WAC[TiAb] OR SHANK2[TiAb] OR NRXN1[TiAb] OR TBL1XR1[TiAb] OR MYT1L[TiAb] OR BCL11A[TiAb] OR RORB[TiAb] OR RAI1[TiAb] OR DYNC1H1[TiAb] OR DPYSL2[TiAb] OR AP2S1[TiAb] OR KMT2C[TiAb] OR PAX5[TiAb] OR MKX[TiAb] OR GABRB3[TiAb] OR SIN3A[TiAb] OR MBD5[TiAb] OR MAP1A[TiAb] OR STXBP1[TiAb] OR CELF4[TiAb] OR PHF12[TiAb] OR TBR1[TiAb] OR PPP2R5D[TiAb] OR TM9SF4[TiAb] OR PHF21A[TiAb] OR PRR12[TiAb] OR SKI[TiAb] OR ASXL3[TiAb] OR SPAST[TiAb] OR SMARCC2[TiAb] OR TRIP12[TiAb] OR CREBBP[TiAb] OR TCF4[TiAb] OR CACNA1E[TiAb] OR GNAI1[TiAb] OR TCF20[TiAb] OR FOXP2[TiAb] OR NSD1[TiAb] OR TCF7L2[TiAb] OR LDB1[TiAb] OR EIF3G[TiAb] OR PHF2[TiAb] OR KIAA0232[TiAb] OR VEZF1[TiAb] OR GFAP[TiAb] OR IRF2BPL[TiAb] OR ZMYND8[TiAb] OR SATB1[TiAb] OR RFX3[TiAb] OR SCN1A[TiAb] OR PPP5C[TiAb] OR TRIM23[TiAb] OR TRAF7[TiAb] OR ELAVL3[TiAb] OR GRIA2[TiAb] OR LRRC4C[TiAb] OR CACNA2D3[TiAb] OR NUP155[TiAb] OR KMT2E[TiAb] OR NR3C2[TiAb] OR NACC1[TiAb] OR PTK7[TiAb] OR PPP1R9B[TiAb] OR GABRB2[TiAb] OR HDLBP[TiAb] OR TAOK1[TiAb] OR UBR1[TiAb] OR TEK[TiAb] OR KCNMA1[TiAb] OR CORO1A[TiAb] OR HECTD4[TiAb] OR NCOA1[TiAb] OR DIP2A[TiAb] OR ALDH5A1[TiAb] OR ARX[TiAb] OR AUTS2[TiAb] OR BCKDK[TiAb] OR CACNA1C[TiAb] OR CAPRIN1[TiAb] OR CDKL5[TiAb] OR CHD7[TiAb] OR CIC[TiAb] OR CUL3[TiAb] OR DDX3X[TiAb] OR DHCR7[TiAb] OR DLG4[TiAb] OR DMPK[TiAb] OR FMR1[TiAb] OR FOXG1[TiAb] OR GRIN1[TiAb] OR HNRNPU[TiAb] OR IQSEC2[TiAb] OR KMT2A[TiAb] OR KMT5B[TiAb] OR MAGEL2[TiAb] OR MBOAT7[TiAb] OR MECP2[TiAb] OR MEF2C[TiAb] OR MTOR[TiAb] OR NBEA[TiAb] OR NEXMIF[TiAb] OR NF1[TiAb] OR NLGN2[TiAb] OR NLGN3[TiAb] OR NLGN4X[TiAb] OR NRXN2[TiAb] OR PCDH19[TiAb] OR PTCHD1[TiAb] OR RELN[TiAb] OR RIMS1[TiAb] OR SCN8A[TiAb] OR SLC9A6[TiAb] OR SYN1[TiAb] OR TRIO[TiAb] OR TSC1[TiAb] OR TSC2[TiAb] OR TSHZ3[TiAb] OR UBAP2L[TiAb] OR UBE3A[TiAb] OR UPF3B[TiAb] OR WDFY3[TiAb]) AND (animal experimentation[MeSH] OR models, animal[MeSH] OR Animals[Mesh:noexp] OR animal population groups[MeSH] OR in vivo[tiab] OR animal[tiab] OR animals[tiab] OR mice[MeSH] OR rats[MeSH] OR mouse[tiab] OR mice[tiab] OR murine[tiab] OR rat[tiab] OR rats[tiab] OR rodent[tiab] OR rodents[tiab] OR Drosophila[MeSH] OR Drosophila[tiab] OR fruit fly[tiab] OR fruit flies[tiab] OR Caenorhabditis elegans[MeSH] OR Caenorhabditis elegans[tiab] OR c. elegans[tiab] OR roundworm[tiab] OR roundworms[tiab] OR nematode[tiab] OR nematodes[tiab] OR zebrafish[MeSH] OR zebrafish[tiab])) NOT (review[PT] OR comment[PT] OR editorial[PT] OR letter[PT] OR news[PT] OR case reports[PT] OR clinical study[PT] OR clinical trial[PT] OR systematic review[PT] OR meta-analysis[PT] OR preprint[PT])"
query_wos <- "(TS=(\"neurodevelopmental disorder*\" OR \"neurodevelopmental delay*\" OR \"delayed neurodevelopment\" OR \"intellectual disabilit*\" OR \"epilepsy\" OR \"autism spectrum disorder\" OR \"ASD\" OR \"autism\" OR \"autistic\" OR  CHD8 OR SCN2A OR SYNGAP1 OR ADNP OR FOXP1 OR POGZ OR ARID1B OR SUV420H1 OR DYRK1A OR SLC6A1 OR GRIN2B OR PTEN OR SHANK3 OR MED13L OR GIGYF1 OR CHD2 OR ANKRD11 OR ANK2 OR ASH1L OR TLK2 OR DNMT3A OR DEAF1 OR CTNNB1 OR KDM6B OR DSCAM OR SETD5 OR KCNQ3 OR SRPR OR KDM5B OR WAC OR SHANK2 OR NRXN1 OR TBL1XR1 OR MYT1L OR BCL11A OR RORB OR RAI1 OR DYNC1H1 OR DPYSL2 OR AP2S1 OR KMT2C OR PAX5 OR MKX OR GABRB3 OR SIN3A OR MBD5 OR MAP1A OR STXBP1 OR CELF4 OR PHF12 OR TBR1 OR PPP2R5D OR TM9SF4 OR PHF21A OR PRR12 OR SKI OR ASXL3 OR SPAST OR SMARCC2 OR TRIP12 OR CREBBP OR TCF4 OR CACNA1E OR GNAI1 OR TCF20 OR FOXP2 OR NSD1 OR TCF7L2 OR LDB1 OR EIF3G OR PHF2 OR KIAA0232 OR VEZF1 OR GFAP OR IRF2BPL OR ZMYND8 OR SATB1 OR RFX3 OR SCN1A OR PPP5C OR TRIM23 OR TRAF7 OR ELAVL3 OR GRIA2 OR LRRC4C OR CACNA2D3 OR NUP155 OR KMT2E OR NR3C2 OR NACC1 OR PTK7 OR PPP1R9B OR GABRB2 OR HDLBP OR TAOK1 OR UBR1 OR TEK OR KCNMA1 OR CORO1A OR HECTD4 OR NCOA1 OR DIP2A OR ALDH5A1 OR ARX OR AUTS2 OR BCKDK OR CACNA1C OR CAPRIN1 OR CDKL5 OR CHD7 OR CIC OR CUL3 OR DDX3X OR DHCR7 OR DLG4 OR DMPK OR FMR1 OR FOXG1 OR GRIN1 OR HNRNPU OR IQSEC2 OR KMT2A OR KMT5B OR MAGEL2 OR MBOAT7 OR MECP2 OR MEF2C OR MTOR OR NBEA OR NEXMIF OR NF1 OR NLGN2 OR NLGN3 OR NLGN4X OR NRXN2 OR PCDH19 OR PTCHD1 OR RELN OR RIMS1 OR SCN8A OR SLC9A6 OR SYN1 OR TRIO OR TSC1 OR TSC2 OR TSHZ3 OR UBAP2L OR UBE3A OR UPF3B OR WDFY3) AND (TS=(animal* NEAR/3 model*) OR TS=(\"in vivo\" OR \"mouse\" OR \"mice\" OR \"murine\" OR \"rat\" OR \"rats\" OR \"rodent\" OR \"rodents\" OR \"Drosophila\" OR \"fruit fly\" OR \"fruit flies\" OR \"Caenorhabditis elegans\" OR \"c. elegans\" OR \"roundworm\" OR \"roundworms\" OR \"nematode\" OR \"nematodes\" OR \"zebrafish\"))) NOT DT=(\"abstract\" OR \"book\" OR \"case report\" OR \"clinical trial\" OR \"editorial\" OR \"letter\" OR \"meeting\" OR \"news\" OR \"review\")"
query_scopus <- "(TITLE-ABS-KEY(\"neurodevelopmental disorder*\" OR \"neurodevelopmental delay*\" OR \"delayed neurodevelopment\" OR \"intellectual disabilit*\" OR \"epilepsy\" OR \"autism spectrum disorder\" OR \"ASD\" OR \"autism\" OR \"autistic\" OR CHD8 OR SCN2A OR SYNGAP1 OR ADNP OR FOXP1 OR POGZ OR ARID1B OR SUV420H1 OR DYRK1A OR SLC6A1 OR GRIN2B OR PTEN OR SHANK3 OR MED13L OR GIGYF1 OR CHD2 OR ANKRD11 OR ANK2 OR ASH1L OR TLK2 OR DNMT3A OR DEAF1 OR CTNNB1 OR KDM6B OR DSCAM OR SETD5 OR KCNQ3 OR SRPR OR KDM5B OR WAC OR SHANK2 OR NRXN1 OR TBL1XR1 OR MYT1L OR BCL11A OR RORB OR RAI1 OR DYNC1H1 OR DPYSL2 OR AP2S1 OR KMT2C OR PAX5 OR MKX OR GABRB3 OR SIN3A OR MBD5 OR MAP1A OR STXBP1 OR CELF4 OR PHF12 OR TBR1 OR PPP2R5D OR TM9SF4 OR PHF21A OR PRR12 OR SKI OR ASXL3 OR SPAST OR SMARCC2 OR TRIP12 OR CREBBP OR TCF4 OR CACNA1E OR GNAI1 OR TCF20 OR FOXP2 OR NSD1 OR TCF7L2 OR LDB1 OR EIF3G OR PHF2 OR KIAA0232 OR VEZF1 OR GFAP OR IRF2BPL OR ZMYND8 OR SATB1 OR RFX3 OR SCN1A OR PPP5C OR TRIM23 OR TRAF7 OR ELAVL3 OR GRIA2 OR LRRC4C OR CACNA2D3 OR NUP155 OR KMT2E OR NR3C2 OR NACC1 OR PTK7 OR PPP1R9B OR GABRB2 OR HDLBP OR TAOK1 OR UBR1 OR TEK OR KCNMA1 OR CORO1A OR HECTD4 OR NCOA1 OR DIP2A OR ALDH5A1 OR ARX OR AUTS2 OR BCKDK OR CACNA1C OR CAPRIN1 OR CDKL5 OR CHD7 OR CIC OR CUL3 OR DDX3X OR DHCR7 OR DLG4 OR DMPK OR FMR1 OR FOXG1 OR GRIN1 OR HNRNPU OR IQSEC2 OR KMT2A OR KMT5B OR MAGEL2 OR MBOAT7 OR MECP2 OR MEF2C OR MTOR OR NBEA OR NEXMIF OR NF1 OR NLGN2 OR NLGN3 OR NLGN4X OR NRXN2 OR PCDH19 OR PTCHD1 OR RELN OR RIMS1 OR SCN8A OR SLC9A6 OR SYN1 OR TRIO OR TSC1 OR TSC2 OR TSHZ3 OR UBAP2L OR UBE3A OR UPF3B OR WDFY3) AND (TITLE-ABS-KEY(animal* W/3 model*) OR TITLE-ABS-KEY(\"in vivo\" OR \"mouse\" OR \"mice\" OR \"murine\" OR \"rat\" OR \"rats\" OR \"rodent\" OR \"rodents\" OR \"Drosophila\" OR \"fruit fly\" OR \"fruit flies\" OR \"Caenorhabditis elegans\" OR \"c. elegans\" OR \"roundworm\" OR \"roundworms\" OR \"nematode\" OR \"nematodes\" OR \"zebrafish\"))) AND NOT DOCTYPE(bk OR ch OR cp OR cr OR ed OR le OR no OR pr OR re)"


# Retrieve database search results
pubmed <- pubmed_search(query_pubmed, timespan = "1week")
scopus <- scopus_search(query_scopus, api_key= Sys.getenv("SCOPUS_API_TOKEN"), retMax = 500)
wos    <- wos_search(query_wos, timespan = "1week")

# Workaround for wos API issue
wos <- read.csv("wos.csv", stringsAsFactors = F)
wos <- wos %>% 
  mutate(source = "wos",
         url = NA,
         date = as.character(format(Sys.Date(), "%d%m%y")),
         ptype = NA,
         author_country = NA) %>%
  select(uid = "UT..Unique.WOS.ID.", source, author = Authors, year = Publication.Year,
         journal = Source.Title, doi = DOI, title = Article.Title, pages = Article.Number,
         volume = Volume, abstract = Abstract, isbn = ISBN, keywords = Keywords.Plus,
         secondarytitle = Source.Title, url, date, issn = ISSN, pmid = Pubmed.Id,
         ptype, author_affiliation = Affiliations, author_country, number = Issue)

# Format scopus and wos uid column
scopus$uid <- gsub("scopus-2-s2\\.0", "scopus", scopus$uid)
wos$uid    <- gsub("wos:|WOS:", "wos-", wos$uid)

# Combine search results into one dataframe
combined_result <- combine_searches(pubmed, wos, scopus)

# Identify new records and write to 'retrieved_citations' database
new_citations <- check_if_retrieved(con, combined_result)

# ------------------------------------------------------------------------------
# Retrieve Missing Meta-Data
# ------------------------------------------------------------------------------

# Find missing DOIs using Open Alex
new_citations <- get_missing_dois(new_citations)

# Find missing abstract text using CrossRef
new_citations <- get_missing_abstracts(new_citations)


# ------------------------------------------------------------------------------
# Remove Duplicate Copies of Records
# ------------------------------------------------------------------------------

# Get unique studies
new_citations_unique <- get_new_unique(con, new_citations)

# Change blank to NA
new_citations_unique <- new_citations_unique %>%
  mutate_all(na_if, "")

# Make DOI lowercase
new_citations_unique$doi <- tolower(new_citations_unique$doi)

# Write unique records to database table
dbWriteTable(con, "unique_citations", new_citations_unique, append=TRUE)

# ------------------------------------------------------------------------------
# Screen Studies for Inclusion
# ------------------------------------------------------------------------------

# Read in data that needs to go through ML
unscreened_set <- get_studies_to_screen(con, 
                                        classify_NA = TRUE, 
                                        project_name = "ndc-soles",
                                        classifier_name = "in-vivo")

# Read in training data for ML
screening_decisions <- read.csv("screening/validation/labelled_data_assigned_iteration.csv", 
                                stringsAsFactors = F) %>%
  filter(iteration == 4,
         cat == "Train") %>%
  select(ITEM_ID, LABEL, REVIEW_ID, KEYWORDS, Cat, ABSTRACT, TITLE)

# Run machine learning and write results to database table
run_ml_at_threshold(con, project_name="ndc-soles", classifier_name="in-vivo", 
                    screening_decisions, unscreened_set, threshold = 0.39)

# ------------------------------------------------------------------------------
# Retrieve Full Text Documents
# ------------------------------------------------------------------------------

# Retrieve full texts, save files to folder, and update database table
get_ft(con, path="full_texts")
get_xml(con, path = "xml_texts")

# ------------------------------------------------------------------------------
# Tag Study Characteristics Using RegEx
# ------------------------------------------------------------------------------
pico_tag(con, tag_type = "species", tag_method = "tiabkw", ignore_case = TRUE, extract_strings = TRUE)
pico_tag(con, tag_type = "model", tag_method = "tiabkw", ignore_case = TRUE, extract_strings = TRUE)
pico_tag(con, tag_type = "intervention", tag_method = "tiabkw", ignore_case = TRUE, extract_strings = FALSE)
pico_tag(con, tag_type = "outcome", tag_method = "tiabkw", ignore_case = TRUE, extract_strings = TRUE)

pico_tag(con, tag_type = "species", tag_method = "fulltext", ignore_case = TRUE, extract_strings = TRUE)
pico_tag(con, tag_type = "model", tag_method = "fulltext", ignore_case = TRUE, extract_strings = TRUE)
pico_tag(con, tag_type = "intervention", tag_method = "fulltext", ignore_case = TRUE, extract_strings = FALSE)
pico_tag(con, tag_type = "outcome", tag_method = "fulltext", ignore_case = TRUE, extract_strings = TRUE)

# ------------------------------------------------------------------------------
# Tag Risk of Bias Reporting Using Qianying's Tool
# ------------------------------------------------------------------------------

rob_tag(con, num_cores = 10)

# ------------------------------------------------------------------------------
# Tag Open Research Practices Using ODDPub
# ------------------------------------------------------------------------------

# Tag for open data and code availability statements and write to database table
ods_tag(con, path="full_texts")

# Open Alex
get_openalex_metadata(con)

get_openalex_update(con)

get_ror_coords(con)
