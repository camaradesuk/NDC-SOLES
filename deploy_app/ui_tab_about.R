ui_tab_about <- tabItem(tabName = "about",
                        
                        fluidRow(
                          
                          box(width = 6,
                              title = span("About NDC-SOLES", style="color:white"),
                              status = "secondary",
                              solidHeader = TRUE,
                              collapsible = FALSE,
                              p("Read our full methods in our ",
                                strong(tags$a(href="https://osf.io/gftzp/", "project protocol.")), "Thank you to Tamsin Baxter, Sarah Bendova, Sarah Giachetti, Chloe Henley, Nawon Kim, Malcolm Macleod, Jessica Pierce, Fiona Ramage, and Eleni Tsoukala for providing data annotation to help train our machine-learning tools."),
                              p("The NDC-SOLES Project is funded by a Simons Initiative for the Developing Brain (SIDB) PhD studentship.",
                                br(),
                                tags$img(
                                  src = "sidb.jpg",
                                  width = 200,
                                  alt = "SIDB logo"
                                ))
                              ),
                          
                          
                          box(width = 6,
                              title = span("CAMARADES", style="color:white"),
                              status="secondary",
                              solidHeader = TRUE,
                              collapsible = FALSE,
                              p("The", tags$a(href="https://www.ed.ac.uk/clinical-brain-sciences/research/camarades", "CAMARADES"), "(Collaborative Approach to Meta-Analysis and Review of
                      Animal Data from Experimental Studies) group specialise in performing", strong("systematic review and meta-analysis"), "of data
                      from experimental studies.
                      Follow us on twitter", tags$a(href="https://twitter.com/camarades_?", "@CAMARADES_")),
                      p("If you have any questions about the project, please contact:",
                        strong(tags$a(href="mailto:emma.wilson@ed.ac.uk", "emma.wilson[at]ed.ac.uk"))))),
                      
                      fluidRow(
                        
                        box(width = 6,
                            title = span("Give us your feedback", style="color:white"),
                            status = "secondary",
                            solidHeader = TRUE,
                            collapsible = FALSE,
                            p("We’re working to continually improve the NDC-SOLES app. Give us your feedback via this ",
                              strong(tags$a(href="https://forms.gle/bTPoiB9G7Yorpyxc9", "short survey.")))),
                        
                        
                        box(width = 6,
                            title = "Using NDC-SOLES data",
                            background="primary",
                            collapsible = FALSE,
                            p("All data and information are provided under a
                      Creative Commons Attribution 4.0 International license (CC BY 4.0)"),
                      p("If you have used the NDC-SOLES data for a research project or review, please cite our SOLES paper:
                      Hair, K., Wilson, E., Wong, C., Tsang, A., Macleod, M. R., & Bannach-Brown, A. (2023). Systematic online 
                      living evidence summaries: emerging tools to accelerate evidence synthesis. Clinical science (London, 
                      England : 1979), 137(10), 773–784. https://doi.org/10.1042/CS20220494"))
                      ))