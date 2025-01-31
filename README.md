# NDC-SOLES
NDC-SOLES uses a series of automated tools and machine-learning approaches to systematically collect, synthesise, and display experimental evidence in genetically-modified animal models of neurodevelopmental conditions.

## About SOLES
Systematic online living evidence summaries (SOLES) is a novel approach to research synthesis, using automated approaches and machine learning to keep to to date with new research as it is published.

Learn more about SOLES projects and the code underlying this app on our [SOLES project website](https://camaradesuk.github.io/soles-projects/). Thank you to SOLES Team members: Emma Wilson, Kaitlyn Hair, Sean Smith, Alexandra Bannach-Brown, and Maria Economou. 

Read our full methods for NDC-SOLES in our [project protocol](https://osf.io/gftzp/). Thank you to Tamsin Baxter, Sarah Bendova, Sarah Giachetti, Chloe Henley, Nawon Kim, Malcolm Macleod, Jessica Pierce, Fiona Ramage, and Eleni Tsoukala for providing data annotation to help train our machine-learning tools.

The NDC-SOLES Project is funded by a Simons Initiative for the Developing Brain (SIDB) PhD studentship.

## Project structure
**Please note:**
- **files in `regex` and `screening` folders may not be fully reproducible as article abstracts have been removed for copyright reasons**
- **data is stored in SQL tables, information to read and write to these tables is NOT provided in this repo**
- **our machine learning classifier is provided by the EPPI-Centre, University College London, who are in the process of making it open source; in the meantime, the classifier is not available in this repo**

Repository structure:
- `deploy_app`: files for generating R Shiny App
- `regex`: data relating to regex validation tasks
- `screening_no_abstract`: data relating to training machine learning classifier for classification, without abstract data shared
- `NDC-SOLES_Additional_Dedup_20241007.R`: code for additional removal of duplicates from the NDC-SOLES dataset
- `NDC-SOLES_ML_Backlog.R`: code for tagging unique citations using machine learning classifier after classifier validation
- `NDC-SOLES_ML_Error_Correction.R`: code for performing error correction prior to machine learning validation
- `NDC-SOLES_ML_Validation.`: code for running k-fold cross validation on machine learning classifier
- `NDC-SOLES_Number_Analysis`: code for analysing number of records tagged for thesis project
- `NDC-SOLES_Regex.R`: code for developing and validating regular expressions approaches for named entity recognition
- `NDC-SOLES_Regex_All.R`: code for running regexes on whole dataset
- `NDC-SOLES_workflow.R`: workflow that is run weekly to retrieve and tag new citations
- `write_data.R`: code to write data for app
