# Transparency info tab UI--------------------------------------------------------------------------------------------------------------------------
ui_tab_openresearch <- tabItem(tabName = "data-summary-openresearch",
                               
        fluidRow(
          box(
            title = "Open research practices",
            solidHeader = TRUE,
            width = 12,
            status = "primary",
            collapsible = FALSE,
            p("Open research practices help build collaboration and ensure transparency in 
              research. Publishing open access allows readers free access to research findings, 
              and there are multiple open access publishing options. Sharing data means others 
              can build upon scientific findings, and sharing analysis code allows verification 
              of findings.")
          )
        ),
        
        fluidRow(
          
          valueBox(
            width=4,
            subtitle = span("Published open access", style = "color: white;"),
            color = "secondary",
            value = span(round(length(oa_tag$uid[which(oa_tag$is_oa==TRUE)])/length(oa_tag$uid)*100,1), "%",
                           style = "font-size: 300%; color: white;"),
            icon = icon("lock-open")
          ),
          
          valueBox(
            width=4,
            subtitle = span("Publications shared data", style = "color: white;"),
            color = "secondary",
            value = span(round(length(transparency$uid[which(transparency$is_open_data==TRUE)])/length(transparency$uid)*100,1), "%",
                           style = "font-size: 300%; color: white;"),
            icon = icon("bar-chart", verify_fa = FALSE)
          ),
          
          valueBox(
            width=4,
            subtitle = span("Publications shared code", style = "color: white;"),
            color = "secondary",
            value = span(round(length(transparency$uid[which(transparency$is_open_code==TRUE)])/length(transparency$uid)*100,1), "%",
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
          collapsible = FALSE,
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
                            p("Each bar plot shows the number of publications in each category over time.
                    Navigate between tabs to see different open research practices.
                    You can hover your mouse over the bars to see the exact number of publications estimated to be in each category for any given year.
                    To see only a specific category, double click on the relevant coloured square in the
                    legend on the top right. To remove any category, click once on any coloured square in the legend.
                    Open access information comes from OpenAlex. The tool used for open code and open data tagging is ODDPub, Riedel, N., et al (2020), DOI:10.5334/dsj-2020-042. Note that some publications may be
                                           missing a risk of bias reporting status due to lack of available data."),
                    tags$a(strong("Find out more about open access types on the Georgia State University Research Guides webpage."), href = 'https://research.library.gsu.edu/c.php?g=115588&p=754380', style = "color: #FFFFFF;"),
                    ),
                    theme = "primary")
        
        
)