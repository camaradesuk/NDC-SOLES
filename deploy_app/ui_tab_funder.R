# Funder info tab UI--------------------------------------------------------------------------------------------------------------------------
ui_tab_funder <- tabItem(tabName = "data-summary-funder",
                
                fluidRow(
                  box(
                    title = "Research funders",
                    status = "primary",
                    solidHeader = TRUE,
                    width = 12,
                    collapsible = FALSE,
                    p("Various different organisations fund research. Using data from OpenAlex, we can 
                      explore the top research funders.")
                  )
                ),
                               
                
                fluidRow(valueBox(
                  width=6,
                  subtitle = span("Funders support NDC research", style = "color: white;"),
                  color = "secondary",
                  value = span(length(unique(funder_tag$funder_name))-1,
                                 style = "font-size: 300%; color: white;"),
                  icon = icon("landmark")
                ),
                
                valueBox(
                  width=6,
                  subtitle = span("Publications tagged with funder", style = "color: white;"),
                  color = "secondary",
                  value = span(round(nrow(filter(funder_tag, funder_name != "Unknown") %>% select(uid) %>% distinct())/nrow(included_with_metadata)*100,1), "%",
                                 style = "font-size: 300%; color: white;"),
                  icon = icon("bar-chart", verify_fa = FALSE)
                )
                ),
                box(title = "Top 10 funders",
                    width = 12,
                    status = "primary",
                    solidHeader = TRUE,
                    collapsible = FALSE,
                    plotlyOutput("funderBarChart")),
                box(
                  title = "How to interpret this plot",
                  width = 12,
                  solidHeader = TRUE,
                  background = "primary",
                  collapsible = FALSE,
                  p("This bar plot shows the top 10 funders of research included in NDC-SOLES. Data are 
                    from OpenAlex. Not all publications are indexed with funder information in OpenAlex, 
                    so we also present the number of publications where the funder in unknown.")
                )
)