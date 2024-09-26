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
                                   
                                   pico_multi_select_UI(id = "interventions",
                                                        multi_select = FALSE,
                                                        table = interventions_tagging,
                                                        column = interventions_tagging$name,
                                                        label1 = "Select a drug: (20 selections max)",
                                                        title = "DrugBank drugs",
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
                                      the selected term or it's synonym. Up to 20 terms can be displayed on 
                                      a plot at once. Genetic models are from SFARI (reflecting genes with a 
                                      human gene score of 1) or identified through large exome sequencing 
                                      (Satterstrom et al., 2020). Drug names come from ", 
                                      tags$a(href = "https://go.drugbank.com/releases/latest#full", span("DrugBank"), style = "color: black;"),
                                      " and are available via a ",
                                      tags$a(href = "https://creativecommons.org/licenses/by/4.0/", 
                                             span("Creative Commoms by Attribution (CC-BY)", style = "color: black;")," license. 
                                      Outcomes were selected from review papers.")
                                  )
                                )
)
)