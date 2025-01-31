ui_tab_evidence_map <-    tabItem(tabName = "pico-bubble",
                                        
                                        box(
                                          width= 12,
                                          status = "primary",
                                          id = "pico_bubble_search_tab",
                                          collapsible = FALSE,
                                          #side = "left",
                                          
                                          tabPanel(title = "Population",
                                                   
                                                   
                                                   fluidRow(column(width = 4, 
                                                                   pickerInput(
                                                                     inputId = "select_model",
                                                                     label = "Select a gene model:",
                                                                     choices = sort(unique(data_for_bubble$model)),
                                                                     selected = sort(unique(data_for_bubble$model)),
                                                                     multiple = TRUE,
                                                                     options = pickerOptions(noneSelectedText = "Please Select",
                                                                                             virtualScroll = 100,
                                                                                             actionsBox = TRUE,
                                                                                             liveSearch = TRUE,
                                                                                             size = 10,
                                                                     )
                                                                   )),
                                                            
                                                            column(width = 4,
                                                                   pickerInput(
                                                                     inputId = "select_outcome",
                                                                     label = "Select an outcome:",
                                                                     choices = sort(unique(data_for_bubble$outcome)),
                                                                     selected = head(sort(unique(data_for_bubble$outcome)), 15),
                                                                     multiple = TRUE,
                                                                     options = list(
                                                                       `actions-box` = TRUE,
                                                                       `live-search` = TRUE
                                                                     ))
                                                                   
                                                                   
                                                            ),
                                                            column(width = 4,
                                                                   pickerInput(
                                                                     inputId = "select_species",
                                                                     label = "Select a species:",
                                                                     choices = sort(unique(data_for_bubble$species)),
                                                                     selected = sort(unique(data_for_bubble$species)),
                                                                     multiple = TRUE,
                                                                     options = list(
                                                                       `actions-box` = TRUE,
                                                                       `live-search` = TRUE
                                                                     )
                                                                   )
                                                                   
                                                                   
                                                            )
                                                            
                                                   )
                                                   
                                                   
                                          )),
                                        
                                        box(
                                          
                                          width = 12,
                                          height = 700,
                                          collapsible = FALSE,
                                          id = "species_outcome",
                                          status = "primary",
                                          
                                          
                                          
                                          plotlyOutput("bubble_plot"),
                                          verbatimTextOutput("click"),
                                          tags$br(),
                                          tags$br()
                                          
                                          
                                        ),
                                        
                                        box(
                                          
                                          width = 12,
                                          id = "species_outcome_datatable",
                                          collapsible = FALSE,
                                          status = "primary",
                                          
                                          DT::dataTableOutput("pop_table") %>% withSpinner(color="#76A8C1")
                                          
                                          
                                        ),
                                  box(
                                    title = "How to interpret this plot",
                                    collapsible = FALSE,
                                    solidHeader = TRUE,
                                    width = 12,
                                    background = "primary",
                                    p("Select genes, species, and outcomes of interest and explore the number 
                                      of publications mentioning these terms. False positives have been filtered out 
                                      as much as possible but some will remain. Up to 20 terms can be displayed on 
                                      a plot at once. Genetic models are from SFARI (reflecting genes with a 
                                      human gene score of 1) or identified through large exome sequencing 
                                      (Satterstrom et al., 2020: https://doi.org/10.1016/j.cell.2019.12.036). 
                                      Animal species are from Understanding Animal Research: 
                                      https://www.understandinganimalresearch.org.uk/using-animals-in-scientific-research/animal-research-species/.
                                      Hover over the circles for more information.")
                                  ))