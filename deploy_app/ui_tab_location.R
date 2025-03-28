# Location info tab UI--------------------------------------------------------------------------------------------------------------------------
ui_tab_location <- tabItem(tabName = "data-summary-location",
                           
                           fluidRow(
                             box(
                              title = "Research around the world",
                              collapsible = FALSE,
                              width = 12,
                              solidHeader = TRUE,
                              status = "primary",
                              p("The research publications included in the NDC-SOLES database come from 
                                all around the world. Explore the map below to find out more about the 
                                institutions producing research.")
                             )
                           ),
                         
                         fluidRow(valueBox(
                           width=4,
                           subtitle = span("Institutions producing research", style = "color: white;"),
                           color = "secondary",
                           value = span(length(unique(institution_tag$name))-1,
                                          style = "font-size: 300%; color: white;"),
                           icon = icon("landmark")
                         ),
                         
                         valueBox(
                           width=4,
                           subtitle = span("Countries producing research", style = "color: white;"),
                           color = "secondary",
                           value = span(length(unique(institution_tag$country))-1,
                                          style = "font-size: 300%; color: white;"),
                           icon = icon("earth-europe", verify_fa = FALSE)
                         ),
                         valueBox(
                           width=4,
                           subtitle = span("Publications tagged with institution", style = "color: white;"),
                           color = "secondary",
                           value = span(round(length(institution_tag$name[which(institution_tag$name!="Unknown")])/nrow(included_with_metadata)*100,1), "%",
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
                                 icon = icon("angles-right"),
                                 fluidRow(
                                   column(width = 11,
                                          tags$div(
                                            style = "padding: 0px;",
                                            selectizeInput(inputId = "country_select",
                                                           label = span("Select a Country", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
                                                           choices = sort(unique(institution_tag$country)),
                                                           selected = NULL,
                                                           multiple = TRUE,
                                                           options = list(
                                                             placeholder = "Please select one or more countries"
                                                           )
                                            ),
                                            pickerInput(
                                              inputId = "continent_select",
                                              label = span("Select a Continent", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
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
                                              label = span("Select Institution Type", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
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
                                      leafletOutput("institution_map", height = 500) %>% withSpinner(color="#76A8C1") )
                               
                             )
                             
                           )
                         ),
                         
                         fluidRow(
                           box(title = "How to interpret this plot",
                               collapsible = FALSE,
                               solidHeader = TRUE,
                               width = 12,
                               background = "primary",
                               p("This map contains data on the location of first authors from across publications 
                                     included in the NDC-SOLES database. Data are from OpenAlex and the Research 
                                     Organization Registry. Click on a dot on the map for more information. 
                                 Click the arrows on the top right of the map to filter data."))
                         )
                         
)



