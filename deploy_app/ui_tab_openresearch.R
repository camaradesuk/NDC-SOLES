# Transparency info tab UI--------------------------------------------------------------------------------------------------------------------------
ui_tab_openresearch <- tabItem(tabName = "data-summary-openresearch",
        
        bs4Jumbotron(
          title = tags$h1("Open research practices"),
          lead = tags$p("Open research practices help build collaboration and ensure transparency in research. This summary shows the overall percentages of publications
                engaging with open access publication, and sharing of data and code. You can
                also benchmark improvements by viewing the number of publications over time."),
          status = "primary",
          btnName = NULL
        ),
        
        fluidRow(
          
          valueBox(
            width=4,
            subtitle = tags$h2("Published open access", style = "color: white;"),
            color = "secondary",
            value = tags$p(round(length(oa_tag$uid[which(oa_tag$is_oa==TRUE)])/length(oa_tag$uid)*100,1), "%",
                           style = "font-size: 300%; color: white;"),
            icon = icon("lock-open")
          ),
          
          valueBox(
            width=4,
            subtitle = tags$h2("Publications shared data", style = "color: white;"),
            color = "secondary",
            value = tags$p(round(length(transparency$uid[which(transparency$is_open_data==TRUE)])/length(transparency$uid)*100,1), "%",
                           style = "font-size: 300%; color: white;"),
            icon = icon("bar-chart", verify_fa = FALSE)
          ),
          
          valueBox(
            width=4,
            subtitle = tags$h2("Publications shared code", style = "color: white;"),
            color = "secondary",
            value = tags$p(round(length(transparency$uid[which(transparency$is_open_code==TRUE)])/length(transparency$uid)*100,1), "%",
                           style = "font-size: 300%; color: white;"),
            icon = icon("code")
          )
        ),
        
        
        tabBox(
          
          width = 12,
          id = "tabcard",
          title = "",
          status = "secondary",
          solidHeader = FALSE,
          type = "tabs",
          
          yearBarUI("oa_pubs_per_year",
                    title = tags$p("Open access over time", style = " color: #1A465F;"),
                    theme = "primary",
                    spinner_colour = "#76A8C1",
                    table = oa_tag),
          
          yearBarUI("oa_pub_type_per_year",
                    title = tags$p("Open access type over time", style = " color: #1A465F;"),
                    theme = "primary",
                    spinner_colour = "#76A8C1",
                    table = oa_tag),
          
          yearBarUI("open_data_pubs_per_year",
                    title = tags$p("Open data availability over time", style = " color: #1A465F;"),
                    theme = "primary",
                    spinner_colour = "#76A8C1",
                    table = transparency),
          
          yearBarUI("open_code_pubs_per_year",
                    title = tags$p("Open code availability over time", style = " color: #1A465F;"),
                    theme = "primary",
                    spinner_colour = "#76A8C1",
                    table = transparency)
          
          
        ),
        
        plot_interpret_UI("transparency_intepret",
                          title = tags$p("How To Interpret This Plot"),
                          
                          div(
                            tags$p("Each bar plot shows the number of publications in each category over time.
                    Navigate between tabs to see different open research practices.
                    You can hover your mouse over the bars to see the exact number of publications estimated to be in each category for any given year.
                    To see only a specific category, double click on the relevant coloured square in the
                    legend on the top right. To remove any category, click once on any coloured square in the legend.
                    The tools and resources used to obtain the data are shown under the x-axis. Note that many publications are
                    still missing a status for one or more open research practices due to processing time or lack of available data."),
                    tags$a("Find out more about open access types on the Georgia State University Research Guides webpage.", href = 'https://research.library.gsu.edu/c.php?g=115588&p=754380', style = "color: #FFFFFF;"),
                    ),
                    theme = "primary")
        
        
)