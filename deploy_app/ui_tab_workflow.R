ui_tab_workflow <- tabItem(tabName = "workflow-accordion-dc",
                           
                           accordion(
                             id = "accordion1",
                             width =12,
                             
                             accordionItem(
                               title = span("Searching for publications", style = "color: white;"),
                               status = "primary",
                               collapsed = FALSE,
                               p("We retrieve new publications weekly (typically on Fridays) from PubMed, Web of Science Core Collection, 
                                 and SCOPUS using application programming interfaces (APIs) via the ScopusAPI, RISmed, and rwos R Packages."),
                               p("The last search was run on:", strong((include_by_date$date[1]))),
                             p("Duplicate copies of publications (where the same publication is obtained from multiple 
                               databases) are identified and removed using the Automated Systematic Search Deduplicator",
                               tags$a(href="https://www.biorxiv.org/content/10.1101/2021.05.04.442412v1", strong("(ASySD).")),
                               "Validation of the tool shows it removes ", strong(">95% "), "of duplicates.")
                             ),
                             
                             accordionItem(
                               title = span("Identify relevant publications", style = "color: white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("Newly retieved publications from our systematic searches are screened using a trained 
                                 machine learning algorithm. This algorithm is set to perform with", strong("95% recall"), 
                                 " meaning most relevant publications should be picked up. Please be aware that some 
                                 irrelevant publications will still remain in the database.")
                             ),
                             
                             accordionItem(
                               title = span("Retrieving metadata from OpenAlex", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("We use the ", tags$a(href="https://cran.r-project.org/web/packages/openalexR/index.html", 
                                                       strong("OpenAlex R package")), "to retrieve additional metadata for 
                                 included publications, including funder details, open access article status, author institutions 
                                 and country, article language, OpenAlex tagged disciplines, and retraction information. 
                                 Additionally, we get map coordinates for institutions from ",
                                 tags$a(href="https://ror.org/", strong("Research Organization Registry.")))
                             ),
                             
                             accordionItem(
                               title = span("Measuring data sharing and risk of bias reporting", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("We use ",
                               tags$a(href="https://doi.org/10.5334/dsj-2020-042", strong("ODDPub")),
                               ", developed by researchers at the BIH Quest centre in Berlin, to identify publications with 
                               open code and open data availability statements. Additionally we use ",
                               tags$a(href="10.1002/jrsm.1533", strong("a pre-trained BERT model")), ", developed by a former 
                               CAMARADES researcher, to detect reporting of measures to reduce the risk of bias in animal 
                               experiments.")),
                             
                             accordionItem(
                               title = span("Tagging by experimental details", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("We developed custom dictionaries of words, phrases, and synonyms of (1) genes commonly 
                                 associated with neurodevelopmental conditions that may be altered in animals to generate models 
                                 (either from ",
                                 tags$a(href="https://gene.sfari.org/database/animal-models/genetic-animal-models/", 
                                       strong("the SFARI gene list with a score of 1")),"or those identified by ",
                                 tags$a(href="https://doi.org/10.1016/j.cell.2019.12.036", 
                                        strong("Satterstrom et al, 2020")),"), (2) ",
                                 tags$a(href="https://www.understandinganimalresearch.org.uk/using-animals-in-scientific-research/animal-research-species/", 
                                        strong("common animal species")),", (3) sex of animals, and (4) 
                                 experimental procedures, and tag publications which mention these terms. We have validated 
                                 optimal approaches to extract this information from publication texts, however please be aware 
                                 that tagging may be inaccurate if publications texts are unavailable or reporting is poor. False positives 
                                 may also be picked up.")
                             )
                           )
)