ui_tab_evidence_map <-    tabItem(tabName = "pico-bubble",
                                        
                                        box(
                                          width= 12,
                                          status = "primary",
                                          id = "pico_bubble_search_tab",
                                          #side = "left",
                                          
                                          tabPanel(title = "Population",
                                                   
                                                   
                                                   fluidRow(column(width = 4, 
                                                                   pickerInput(
                                                                     inputId = "select_intervention",
                                                                     label = "Select an Intervention:",
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
                                                                     label = "Select an Outcome:",
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
                                                                     label = "Select a Model Type:",
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
                                          status = "primary",
                                          
                                          DT::dataTableOutput("pop_table") %>% withSpinner(color="#391171")
                                          
                                          
                                        ))