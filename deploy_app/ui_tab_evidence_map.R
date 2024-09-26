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
                                                                     inputId = "select_intervention",
                                                                     label = "Select a drug:",
                                                                     choices = sort(unique(data_for_bubble$intervention)),
                                                                     selected = head(sort(unique(data_for_bubble$intervention)), 15),
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
                                                                     inputId = "select_model",
                                                                     label = "Select a gene symbol:",
                                                                     choices = sort(unique(data_for_bubble$model)),
                                                                     selected = sort(unique(data_for_bubble$model)),
                                                                     multiple = TRUE,
                                                                     options = pickerOptions(noneSelectedText = "Please Select",
                                                                                             virtualScroll = 100,
                                                                                             actionsBox = TRUE,
                                                                                             size = 10,
                                                                     )
                                                                   )
                                                                   
                                                                   
                                                            )
                                                            
                                                   )
                                                   
                                                   
                                          )),
                                        
                                        box(
                                          
                                          width = 12,
                                          height = 700,
                                          collapsible = FALSE,
                                          id = "intervention_outcome",
                                          status = "primary",
                                          
                                          
                                          
                                          plotlyOutput("bubble_plot"),
                                          verbatimTextOutput("click"),
                                          tags$br(),
                                          tags$br()
                                          
                                          
                                        ),
                                        
                                        box(
                                          
                                          width = 12,
                                          id = "intervention_outcome_datatable",
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
                                    p("Select models, drugs, and outcomes of interest and explore the number 
                                      of publications mentioning these terms. Hover over the circles for 
                                      more information.")
                                  ))