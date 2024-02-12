ui_tab_model_trends  <- tabItem(tabName = "data-trends-model",
                                 
                                 tabBox(
                                   
                                   width = 12,
                                   id = "tabcard_model",
                                   title = "",
                                   status = "secondary",
                                   solidHeader = FALSE,
                                   type = "tabs",
                                   
                                   pico_multi_select_UI(id = "model",
                                                        multi_select = FALSE,
                                                        table = model_tagging,
                                                        column = model_tagging$name,
                                                        label1 = "Select a model type:",
                                                        title = "Model",
                                                        theme = "danger",
                                                        spinner_colour = "#9CAF88")
                                   
                                 )
)