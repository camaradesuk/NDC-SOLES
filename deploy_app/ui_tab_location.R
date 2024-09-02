# Location info tab UI--------------------------------------------------------------------------------------------------------------------------
ui_tab_location <- tabItem(tabName = "data-summary-location",
                         
                         bs4Jumbotron(
                           title = tags$h1("Research around the world"),
                           lead = tags$p("Using data from OpenAlex, we can visualise where around the world research is being produced."),
                           status = "primary",
                           btnName = NULL
                         ),
                         
                         fluidRow(valueBox(
                           width=4,
                           subtitle = tags$h2("Institutions producing research", style = "color: white;"),
                           color = "secondary",
                           value = tags$p(length(unique(institution_tag$name))-1,
                                          style = "font-size: 300%; color: white;"),
                           icon = icon("landmark")
                         ),
                         
                         valueBox(
                           width=4,
                           subtitle = tags$h2("Countries producing research", style = "color: white;"),
                           color = "secondary",
                           value = tags$p(round(length(unique(institution_tag$institution_country_code[which(institution_tag$institution_country_code!="Unknown")]))/nrow(included_with_metadata)*100,1), "%",
                                          style = "font-size: 300%; color: white;"),
                           icon = icon("bar-chart", verify_fa = FALSE)
                         ),
                         valueBox(
                           width=4,
                           subtitle = tags$h2("Publications tagged with institution", style = "color: white;"),
                           color = "secondary",
                           value = tags$p(round(length(unique(institution_tag$name[which(institution_tag$name!="Unknown")]))/nrow(included_with_metadata)*100,1), "%",
                                          style = "font-size: 300%; color: white;"),
                           icon = icon("bar-chart", verify_fa = FALSE)
                         )
                         ),
                         fluidRow(
                           box(
                             width = 12,
                             title = "Research institutions world map",
                             status = "primary",
                             solidHeader = TRUE,
                             collapsable = FALSE,
                             closable=FALSE,
                             
                             sidebar = c(
                               # First sidebar with filter icon
                               boxSidebar(
                                 width = 30,
                                 background = "#344149",
                                 id = "inst_loc_sidebar",
                                 icon = icon("info"),
                                 fluidRow(
                                   column(width = 11,
                                          p("This map contains data on the location of first authors from across publications included in the NDC-SOLES database."),
                                          tags$div(
                                            style = "padding: 0px;",
                                            selectizeInput(inputId = "country_select",
                                                           label = tags$p("Select a Country", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
                                                           choices = sort(unique(institution_tag$country)),
                                                           selected = NULL,
                                                           multiple = TRUE,
                                                           options = list(
                                                             placeholder = "Please select one or more countries"
                                                           )
                                            ),
                                            pickerInput(
                                              inputId = "continent_select",
                                              label = tags$p("Select a Continent", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
                                              choices = sort(unique(institution_tag$continent)),
                                              selected = sort(unique(institution_tag$continent)),
                                              multiple = TRUE,
                                              options = pickerOptions(
                                                noneSelectedText = "Please Select",
                                                virtualScroll = 100,
                                                actionsBox = TRUE,
                                                size = 10
                                              )
                                            ),
                                            pickerInput(
                                              inputId = "inst_type_select",
                                              label = tags$p("Select Institution Type", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
                                              choices = sort(unique(institution_tag$type)),
                                              selected = sort(unique(institution_tag$type)),
                                              multiple = TRUE,
                                              options = pickerOptions(
                                                noneSelectedText = "Please Select",
                                                virtualScroll = 100,
                                                actionsBox = TRUE,
                                                size = 10
                                              )
                                            )
                                          )
                                   )
                                 )
                               )
                             ),
                             fluidRow(
                               column(width = 12,
                                      leafletOutput("institution_map", height = 500) %>% withSpinner(color="#76A8C1") ),
                               
                             )
                             
                           )
                         )
                         
)



