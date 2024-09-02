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
                             title = "Instutitons conducting controlled studies evaluating interventions",
                             status = "primary",
                             solidHeader = TRUE,
                             collapsable = FALSE,
                             closable=FALSE,
                             
                             sidebar = c(
                               # First sidebar with filter icon
                               boxSidebar(
                                 width = 30,
                                 background = "#64C296",
                                 id = "inst_loc_sidebar",
                                 icon = icon("info"),
                                 fluidRow(
                                   column(width = 11,
                                          p("This map contains data on the location of first authors from across acticles represented in the iRISE database (including both controlled evaluations of interventions and other studies evaluating interventions). We were only able to obtain data
                                               for article with a DOI and where the author's institutional information was present in OpenAlex. For more information on our methodology, please visit the methodology page."),
                                          tags$div(
                                            style = "padding: 0px;",
                                            selectizeInput(inputId = "country_select",
                                                           label = tags$p("Select a Country", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
                                                           choices = sort(unique(ror_data$country)),
                                                           selected = NULL,
                                                           multiple = TRUE,
                                                           options = list(
                                                             placeholder = "Please select one or more countries"
                                                           )
                                            ),
                                            pickerInput(
                                              inputId = "continent_select",
                                              label = tags$p("Select a Continent", style = "color: #ffffff; font-family: KohinoorBangla, sans-serif;margin: 0; padding: 0;"),
                                              choices = sort(unique(ror_data$continent)),
                                              selected = sort(unique(ror_data$continent)),
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
                                              choices = sort(unique(ror_data$type)),
                                              selected = sort(unique(ror_data$type)),
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
                               ),
                               
                               # Second sidebar with info-circle icon
                               boxSidebar(
                                 id = "int_ac_dis_sidebar",
                                 icon = icon("info-circle"),
                                 tags$div(
                                   style = "padding: 10px;",
                                   tags$h4("Guidance for Evidence Map"),
                                   tags$p("Use the map below to visualize evidence on interventions to improve different types of reproducibility and related outcomes. This visualization contains all articles which have been classified as controlled, primary research studies evaluating an intervention to improve reproducibility. Click a bubble to see all the relevant evidence in the table below."),
                                   tags$p("You can select multiple outcome measures and subgroups to filter the data. The bubbles represent the number of studies, with larger bubbles indicating more studies.")
                                 )
                               )
                             ),
                             fluidRow(
                               column(width = 12,
                                      leafletOutput("institution_map", height = 500) %>% withSpinner(color="#96c296") ),
                               
                             )
                             
                           )
                         )
                         
)



