ui_included_studies <- tabItem(tabName = "studies-included-summary-dc",
        fluidRow(
          valueBox(
            width=3,
            subtitle = span("Publications this week", style = "font-size: 120%; color: white;"),
            color = "secondary",
            value = span(sum(as.numeric(include_by_date$n)[which(include_by_date$date >= Sys.Date()-7)]),
                           style = "font-size: 300%; color: white;"),
            icon = icon("clock", verify_fa = FALSE)),
          valueBox(
            width=3,
            subtitle = span("Publications in the last year", style = "font-size: 120%; color: white;"),
            color = "secondary",
            value = span(sum(as.numeric(include_by_date$n)[which(include_by_date$date >= Sys.Date()-365)]),
                           style = "font-size: 300%; color: white;"),
            icon = icon("calendar")),
          valueBox(
            width=3,
            subtitle = span("Total publications", style = "font-size: 120%; color: white;"),
            color = "secondary",
            value = span(sum(as.numeric(include_by_date$n)),
                           style = "font-size: 300%; color: white;"),
            icon = icon("database", verify_fa = FALSE)),
          valueBox(
            width=3,
            subtitle = span("Retracted publications", style = "font-size: 120%; color: black;"),
            color = "danger",
            value = span(nrow(filter(retraction_tag, is_retracted == TRUE)),
                           style = "font-size: 300%; color: black;"),
            icon = icon("circle-xmark"))
        ),
        fluidRow(
          tabBox(
            width=12,
            id = "tabcard_included_studies",
            title = "",
            status = "secondary",
            solidHeader = FALSE,
            collapsible = FALSE,
            type = "tabs",
            yearBarUI_included_only("included_studies_over_time_bar",
                                    title = "Articles published per year",
                                    theme = "danger",
                                    spinner_colour = "#76A8C1",
                                    table = n_included_per_year_plot_data)
            
            
            
          ),
          plot_interpret_UI("included_interpret",
                            title = "How to intepret this plot",
                            p("The bar plot shows the number of publications per year included 
                              in the NDC-SOLES dataset. We search three bibliographic sources 
                              each week, and use machine learning to identify relevant publications 
                              from search results. Read our Workflow page to learn more."),
                            theme = "primary"
          )
        )
)