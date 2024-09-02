ui_included_studies <- tabItem(tabName = "studies-included-summary-dc",
        fluidRow(
          valueBox(
            width=3,
            subtitle = tags$p("Publications this week", style = "font-size: 120%; color: white;"),
            color = "secondary",
            value = tags$p(sum(as.numeric(include_by_date$n)[which(include_by_date$date >= Sys.Date()-7)]),
                           style = "font-size: 300%; color: white;"),
            icon = icon("clock", verify_fa = FALSE)),
          valueBox(
            width=3,
            subtitle = tags$p("Publications in the last year", style = "font-size: 120%; color: white;"),
            color = "secondary",
            value = tags$p(sum(as.numeric(include_by_date$n)[which(include_by_date$date >= Sys.Date()-365)]),
                           style = "font-size: 300%; color: white;"),
            icon = icon("calendar")),
          valueBox(
            width=3,
            subtitle = tags$p("Total publications", style = "font-size: 120%; color: white;"),
            color = "secondary",
            value = tags$p(sum(as.numeric(include_by_date$n)),
                           style = "font-size: 300%; color: white;"),
            icon = icon("database", verify_fa = FALSE)),
          valueBox(
            width=3,
            subtitle = tags$p("Retracted publications", style = "font-size: 150%; color: black;"),
            color = "danger",
            value = tags$p(nrow(filter(retraction_tag, is_retracted == TRUE)),
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
            type = "tabs",
            yearBarUI_included_only("included_studies_over_time_bar",
                                    title = "Articles published per year",
                                    theme = "danger",
                                    spinner_colour = "#76A8C1",
                                    table = n_included_per_year_plot_data)
            
            
            
          )
        )
)