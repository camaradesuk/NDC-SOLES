ui_tab_workflow <- tabItem(tabName = "workflow-accordion-dc",
                           
                           accordion(
                             id = "accordion1",
                             width =12,
                             
                             accordionItem(
                               title = tags$p("Collecting relevant citations", style = "color: white;"),
                               status = "primary",
                               collapsed = FALSE,
                               p("We programmatically retrieve new citations on a weekly basis (every Friday) from PubMed, Web of Science, and SCOPUS using application programming interfaces (APIs). More specifically, we use
                             the open source R packages: ScopusAPI, RISmed, and rwos, which are all available on GitHub."),
                             p("Duplicate citations (where the same citation is obtained from multiple databases) are identified and removed using ",
                               tags$a(href="https://github.com/camaradesuk/ASySD", strong("ASySD.")),
                               "This tool typically identifies ", strong(">95% "), "of duplicate citations and has a low false positive rate (does not remove many citations incorrectly). You can read more about the performance of the tool ",
                               tags$a(href="https://www.biorxiv.org/content/10.1101/2021.05.04.442412v1", strong("here."))),
                             p("Look at the other sections below by clicking on the header to expand the explanation")
                             ),
                             
                             accordionItem(
                               title = tags$p("Screening for relevance ", style = "color: white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("Newly retieved citations are screened using a machine learning algorithm trained to identify animal in vivo experiments of focal cerebral ischaemia.
                             In validation tests, this algorithm", strong(" includes >95% "), "of papers which",
                             strong("should"), "be included. All included citations are added to the Stroke-SOLES database.",
                             "This application was last updated on", (include_by_date$date[1]))
                             ),
                             
                             accordionItem(
                               title = tags$p("Downloading full texts", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("Full texts of included citations are downloaded (where possible) to facilitate automated tagging of risk of bias reporting, modelling, interventions, and outcome measures.
                             We also use automated tools to extract information about transparency and open-access status.")
                             ),
                             
                             accordionItem(
                               title = tags$p("Retrieving metadata from OpenAlex", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("We use the ", tags$a(href="https://cran.r-project.org/web/packages/openalexR/index.html", strong("OpenAlex R package")), "to retrieve additional metadata for included studies, including funder details, open access article status, author institutions and country, 
                                 article language, OpenAlex tagged disciplines, and retraction information.")
                             ),
                             
                             accordionItem(
                               title = tags$p("Measuring open research and risk of bias reporting", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("To measure open research practices, we link citations using their DOIs to the CrossRef database (via the ",  tags$a(href="https://www.biorxiv.org/content/10.1101/2021.05.04.442412v1", em("rcorssref")), " R package.
                             CrossRef contains information about open-access status, citation counts and much more."),
                             p("We also use a tool called ",
                               tags$a(href="https://doi.org/10.5334/dsj-2020-042", strong("ODDPub")),
                               ", developed by researchers at the BIH Quest centre in Berlin. This tool detects open code and open data availability statements from publications.
                             It performs with a sensitivity of ~73% (meaning it correctly identifies 73% of papers where open code/data is available) and has a high specificity of 97%, meaning it correctly classifies 97% papers where open code/data is not availble. Overall,
                             this means it may miss data/code availability from some papers, but when it classifies a paper as having open/code data, it is very likely to be correct."
                             )),
                             
                             accordionItem(
                               title = tags$p("Tagging by experimental details", style = "color:white;"),
                               status = "primary",
                               collapsed = TRUE,
                               p("To extract model, intervention, and outcome meausre details from publications, we created
                             custom dictionaries of words and phrases relating to each tag."),
                             p("Using these dictionaries, we create ",
                               tags$a(href="https://en.wikipedia.org/wiki/Regular_expression", strong("regular expressions ")),
                               "to identify those specific words and phrases in the full text of publications and frequency of matches.
                             We tag a study by each model / intervention/ outcome measure when it is mentioned at least once within the publication (omitting the references and introduction), or when it is mentioned at
                             least once in the title, abstract, or keywords.")
                             )
                           )
)