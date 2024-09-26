ui_tab_workflow <- tabItem(tabName = "workflow-accordion-dc",
                           
                           accordion(
                             id = "accordion1",
                             width =12,
                             
                             accordionItem(
                               title = span("Searching for publications", style = "color: white;"),
                               status = "primary",
                               collapsed = FALSE,
                               p("We retrieve new publications weekly (typically on Fridays) from PubMed, Web of Science, 
                                 and SCOPUS using application programming interfaces (APIs). To do this, we use the 
                                 following R packages: ScopusAPI, RISmed, and rwos."),
                               p("The last search was run on", strong((include_by_date$date[1]))),
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
                                 irrelevant publications may end up in the database.")
                             ),
                             
                             accordionItem(
                               title = span("Retrieving metadata from OpenAlex", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("We use the ", tags$a(href="https://cran.r-project.org/web/packages/openalexR/index.html", 
                                                       strong("OpenAlex R package")), "to retrieve additional metadata for 
                                 included publications, including funder details, open access article status, author institutions 
                                 and country, article language, OpenAlex tagged disciplines, and retraction information. 
                                 Additonally, we get map coordinates for institutions from ",
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
                               p("We developed custom dictionaries of words, phrases, and synonyms of common animal models, 
                                 drug names, and experimental procedures, and tag publications which mention these terms. 
                                 We are still validating the best way to extract this information from publications.")
                             )
                           )
)