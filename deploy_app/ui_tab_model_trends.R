ui_tab_model_trends  <- tabItem(tabName = "data-trends-model",
                                 
                                 tabBox(
                                   
                                   width = 12,
                                   id = "tabcard_model",
                                   title = "",
                                   status = "secondary",
                                   solidHeader = FALSE,
                                   collapsible = FALSE,
                                   type = "tabs",
                                   
                                   pico_multi_select_UI(id = "model",
                                                        multi_select = FALSE,
                                                        table = model_tagging,
                                                        column = model_tagging$name,
                                                        label1 = "Select a gene symbol:",
                                                        title = "Genetic models",
                                                        theme = "danger",
                                                        spinner_colour = "#76A8C1"),
                                   
                                   pico_multi_select_UI(id = "species",
                                                        multi_select = FALSE,
                                                        table = species_tagging,
                                                        column = species_tagging$name,
                                                        label1 = "Select a species:",
                                                        title = "Animal species",
                                                        theme = "danger",
                                                        spinner_colour = "#76A8C1"),
                                   
                                   pico_multi_select_UI(id = "sex",
                                                        multi_select = FALSE,
                                                        table = sex_tagging,
                                                        column = sex_tagging$name,
                                                        label1 = "Select a sex:",
                                                        title = "Animal sex",
                                                        theme = "danger",
                                                        spinner_colour = "#76A8C1"),
                                   
                                   pico_multi_select_UI(id = "outcome",
                                                        multi_select = FALSE,
                                                        table = outcome_tagging,
                                                        column = outcome_tagging$name,
                                                        label1 = "Select an outcome: (20 selections max)",
                                                        title = "Experimental outcomes",
                                                        theme = "danger",
                                                        spinner_colour = "#76A8C1")
                                   
                                 ),
                                fluidRow(
                                  box(
                                    title = "How to interpret this plot",
                                    width = 12,
                                    collapsible = FALSE,
                                    solidHeader = TRUE,
                                    background = "primary",
                                    p("This bar plots display the number of publications tagged as mentioning 
                                      the selected term or it's synonym. False positives have been filtered out 
                                      as much as possible but some will remain. Up to 20 terms can be displayed on 
                                      a plot at once. Genetic models are from SFARI (reflecting genes with a 
                                      human gene score of 1) or identified through large exome sequencing 
                                      (Satterstrom et al., 2020: https://doi.org/10.1016/j.cell.2019.12.036). 
                                      Animal species are from Understanding Animal Research: 
                                      https://www.understandinganimalresearch.org.uk/using-animals-in-scientific-research/animal-research-species/.")
                                )
)
)