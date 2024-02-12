ui_tab_outcome_trends <- tabItem(tabName = "data-trends-outcome",
                             
                             tabBox(
                               
                               width = 12,
                               id = "tabcard_outcome",
                               title = "",
                               status = "secondary",
                               solidHeader = FALSE,
                               type = "tabs",
                               
                               pico_multi_select_UI(id = "outcome",
                                                    multi_select = FALSE,
                                                    table = outcome_tagging,
                                                    column = outcome_tagging$name,
                                                    label1 = "Select an outcome: (20 selections max)",
                                                    title = "Outcome",
                                                    theme = "danger",
                                                    spinner_colour = "#9CAF88")
                               
                             )
)