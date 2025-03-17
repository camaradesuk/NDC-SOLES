ui_tab_rob <- tabItem(tabName = "data-summary-rob",
                      
                      fluidRow(
                        box(
                          title = "Reporting of measures to reduce the risk of bias",
                          width = 12,
                          solidHeader = TRUE,
                          status = "primary",
                          collapsible = FALSE,
                          p("Various types of bias can be introduced into animal experiments, which 
                            reduce the internal validity of an experiment. Measures to reduce the 
                            risk of bias include blinding (also known as masking), and reporting whether or not 
                            any animals were excluded from analyses.")
                        )
                      ),
                
                fluidRow(
                  
                  valueBox(
                    width=6,
                    subtitle = tags$p("Randomisation", style = "font-size: 150%; color: white;"),
                    color = "secondary",
                    value = tags$p(round(length(rob$uid[which(rob$is_random=="reported")])/
                                           nrow(included_with_metadata)*100,1), "%",
                                   style = "font-size: 200%; color: white;"),
                    icon = icon("asterisk")
                  ),
                  
                  valueBox(
                    width=6,
                    subtitle = tags$p("Blinded outcome assessment", style = "font-size: 150%; color: white;"),
                    color = "secondary",
                    value = tags$p(round(length(rob$uid[which(rob$is_blind=="reported")])/
                                           nrow(included_with_metadata)*100,1), "%",
                                   style = "font-size: 200%; color: white;"),
                    icon = icon("eye-slash", verify_fa = FALSE)
                  )
                ),
                
                fluidRow(
                  
                  valueBox(
                    width=4,
                    subtitle = tags$p("Conflicts of interest statement", style = "font-size: 150%; color: white;"),
                    color = "secondary",
                    value =tags$p(round(length(rob$uid[which(rob$is_interest=="reported")])/
                                          nrow(included_with_metadata)*100,1), "%",
                                  style = "font-size: 200%; color: white;"),
                    icon = icon("money-check-alt")
                  ),
                  
                  valueBox(
                    width=4,
                    subtitle = tags$p("Welfare approval statement", style = "font-size: 150%; color: white;"),
                    color = "secondary",
                    value = tags$p(round(length(rob$uid[which(rob$is_welfare == "reported")])/
                                           nrow(included_with_metadata)*100,1), "%",
                                   style = "font-size: 200%; color: white;"),
                    icon = icon("paw")
                  ),
                  
                  valueBox(
                    width=4,
                    subtitle = tags$p("Animal exclusions statement", style = "font-size: 150%; color: white;"),
                    color = "secondary",
                    value = tags$p(round(length(rob$uid[which(rob$is_exclusion == "reported")])/
                                           nrow(included_with_metadata)*100,1), "%",
                                   style = "font-size: 200%; color: white;"),
                    icon = icon("ban")
                  )
                ),
                
                fluidRow(
                  
                  tabBox(
                    width= 12,
                    id = "tabcard",
                    title = "",
                    status = "primary",
                    solidHeader = FALSE,
                    collapsible = FALSE,
                    type = "tabs",
                    
                    yearBarUI("random_per_year",
                              title = "Randomisation over time",
                              theme = "danger",
                              table = rob,
                              spinner_colour = "#76A8C1"),
                    
                    yearBarUI("blind_per_year",
                              title = "Blinding over time",
                              theme = "danger",
                              table = rob,
                              spinner_colour = "#76A8C1"),
                    
                    yearBarUI("coi_per_year",
                              title = "COI statements over time",
                              theme = "danger",
                              table = rob,
                              spinner_colour = "#76A8C1"),
                    
                    yearBarUI("exclusion_per_year",
                              title = "Exclusion statements over time",
                              theme = "danger",
                              table = rob,
                              spinner_colour = "#76A8C1"),
                    
                    yearBarUI("welfare_per_year",
                              title = "Welfare approval over time",
                              theme = "danger",
                              table = rob,
                              spinner_colour = "#76A8C1")
                  ),
                  
                  plot_interpret_UI("rob_interpret",
                                    title = "How to intepret this plot",
                                    p("Each bar plot shows the number of papers in each category over time.
                                           Navigate between tabs to see different risk of bias measures.
                                           You can hover your mouse over the bars to see the exact number of publications estimated to be in each category for any given year.
                                           To see only a specific category, double click on the relevant coloured square in the
                                           legend on the top right. To remove any category, click once on any coloured square in the legend.
                                           The tool used is RobPredictor, Wang, Q., et al (2021), DOI:10.1002/jrsm.1533. Note that some publications may be
                                           missing a risk of bias reporting status due to lack of available data."),
                                    theme = "primary"
                  )
                )
)