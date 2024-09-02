# Funder info tab UI--------------------------------------------------------------------------------------------------------------------------
ui_tab_funder <- tabItem(tabName = "data-summary-funder",
                               
                               bs4Jumbotron(
                                 title = tags$h1("Research funders"),
                                 lead = tags$p("Using data from OpenAlex, we can visualise research funding sources."),
                status = "primary",
                btnName = NULL
                               ),
                
                fluidRow(valueBox(
                  width=6,
                  subtitle = tags$h2("Funders support NDC research", style = "color: white;"),
                  color = "secondary",
                  value = tags$p(length(unique(funder_tag$funder_name))-1,
                                 style = "font-size: 300%; color: white;"),
                  icon = icon("landmark")
                ),
                
                valueBox(
                  width=6,
                  subtitle = tags$h2("Publications tagged with funder", style = "color: white;"),
                  color = "secondary",
                  value = tags$p(round(length(unique(funder_tag$funder_name[which(funder_tag$funder_name!="Unknown")]))/nrow(included_with_metadata)*100,1), "%",
                                 style = "font-size: 300%; color: white;"),
                  icon = icon("bar-chart", verify_fa = FALSE)
                )
                ),
                box(title = "Top 10 funders",
                    width = 12,
                    status = "primary",
                    solidHeader = TRUE,
                    plotlyOutput("funderBarChart"))
)