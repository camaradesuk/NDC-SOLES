ui_tab_int_trends <- tabItem(tabName = "data-trends-int",
                             
                             tabBox(

                               width = 12,
                               id = "tabcard_interventions",
                               title = "",
                               status = "secondary",
                               solidHeader = FALSE,
                               type = "tabs",

                               pico_multi_select_UI(id = "interventions",
                                                    multi_select = FALSE,
                                                    table = interventions_tagging,
                                                    column = interventions_tagging$name,
                                                    label1 = "Select an Intervention: (20 selections max)",
                                                    title = "Interventions",
                                                    theme = "danger",
                                                    spinner_colour = "#9CAF88")

                             )
                             )