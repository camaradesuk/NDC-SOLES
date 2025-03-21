# R packages
library(shinythemes)
library(viridis)
library(viridisLite)
library(ggiraph)
library(shiny)
library(shinyWidgets)
library(ggplot2)
library(RPostgres)
library(RSQLite)
library(DBI)
library(dbplyr)
library(dplyr)
library(shinyjs)
library(shinycssloaders)
library(plotly)
library(purrr)
library(networkD3)
library(RColorBrewer)
library(wordcloud2)
library(bs4Dash)
library(tools)
library(readr)
library(fresh)
library(htmlwidgets)
library(lubridate)
library(stringr)
library(fst)
library(readr)
library(jsonlite)
library(tidyr)
library(shinyalert)
library(rsconnect)
library(gtools)
library(leaflet)

# set wd
#setwd("/home/ewilson/SOLES/NDC-SOLES/deploy_app")

# Get theme
source("create_theme.R")

# Specify the directory where the fst files are located
dir_path <- "fst_files"

# Get a list of all fst files in the directory
all_files <- list.files(path = dir_path, pattern = "\\.fst$")

# Read each fst file
for (file in all_files) {
  assign(sub("\\.fst$", "", file), read_fst(file.path(dir_path, file)), envir = .GlobalEnv)
}

# Get today
today <- format(Sys.Date(), format="%B %d %Y")


# Source modules code
source("modules.R")

# Get UI
source("ui_sidebar.R")
source("ui_tab_home.R")
source("ui_included_studies.R")
source("ui_tab_workflow.R")
source("ui_tab_openresearch.R")
source("ui_tab_rob.R")
source("ui_tab_funder.R")
source("ui_tab_location.R")
source("ui_tab_model_trends.R")
#source("ui_tab_int_trends.R")
#source("ui_tab_outcome_trends.R")
source("ui_tab_evidence_map.R")
source("ui_tab_database.R")
source("ui_tab_about.R")

# Set cache
cache_path = "./cache"
shinyOptions(cache = cachem::cache_disk(file.path(cache_path)))

# Pico elements
pico_elements_list <- list(pico_element_1 = list(id = "dropdown_model",
                                                 table = model_df,
                                                 label1 = "Filter by model:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_2 = list(id = "dropdown_species",
                                                 table = species_df,
                                                 label1 = "Filter by species:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_3 = list(id = "dropdown_sex",
                                                 table = sex_df,
                                                 label1 = "Filter by sex:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_4 = list(id = "dropdown_outcome",
                                                 table = outcome_df,
                                                 label1 = "Filter by outcome:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_5 = list(id = "dropdown_funder",
                                                 table = funder_tag %>% rename(name = funder_name),
                                                 label1 = "Filter by funder:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_6 = list(id = "dropdown_institution",
                                                 table = institution_tag,
                                                 label1 = "Filter by institution:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_7 = list(id = "dropdown_discipline",
                                                 table = discipline_tag %>% rename(name = main_discipline),
                                                 label1 = "Filter by OpenAlex discipline:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_8 = list(id = "dropdown_language",
                                                 table = article_tag %>% rename(name = language),
                                                 label1 = "Filter by language:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_9 = list(id = "dropdown_retraction",
                                                 table = retraction_tag %>% 
                                                   rename(name = is_retracted),
                                                 label1 = "Show or hide retracted articles:",
                                                 column1 = "name",
                                                 filter_no = 1),
                           pico_element_10 = list(id = "dropdown_openaccess",
                                                  table = oa_tag %>% 
                                                    rename(name = oa_status),
                                                  label1 = "Filter by open access type:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_11 = list(id = "dropdown_opendata",
                                                  table = transparency %>% 
                                                    rename(name = is_open_data),
                                                  label1 = "Filter by data availablity:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_12 = list(id = "dropdown_opencode",
                                                  table = transparency %>% 
                                                    rename(name = is_open_code),
                                                  label1 = "Filter by code availablity:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_13 = list(id = "dropdown_random",
                                                  table = rob %>% 
                                                    rename(name = is_random),
                                                  label1 = "Filter by reporting random allocation of animals to groups:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_14 = list(id = "dropdown_blind",
                                                  table = rob %>% 
                                                    rename(name = is_blind),
                                                  label1 = "Filter by reporting blinded outcome assessment:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_15 = list(id = "dropdown_coi",
                                                  table = rob %>% 
                                                    rename(name = is_interest),
                                                  label1 = "Filter by reporting conflicts of interest statement:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_16 = list(id = "dropdown_welfare",
                                                  table = rob %>% 
                                                    rename(name = is_welfare),
                                                  label1 = "Filter by reporting animal welfare approval statement:",
                                                  column1 = "name",
                                                  filter_no = 1),
                           pico_element_17 = list(id = "dropdown_exclusion",
                                                  table = rob %>% 
                                                    rename(name = is_exclusion),
                                                  label1 = "Filter by reporting animal exclusion statement:",
                                                  column1 = "name",
                                                  filter_no = 1))


# UI ------------------------------
ui <- bs4DashPage(
  # Set theme
  freshTheme = mytheme,
  dark = NULL,
  # Set header
  dbHeader <- dashboardHeader(title = "NDC-SOLES",
                              tags$img(src='CAMARADES_logo.jpg',
                                       height = "30px")
  ),
  
  # Set sidebar
  dashboardSidebar(ui_sidebar),
  
  # Set body
  bs4DashBody(
    # Analytics
    #tags$head(includeHTML("google_analytics.html")),
    # Theme
    use_theme(mytheme),
    # Side Bar Items
    tabItems(
      ui_tab_home,
      ui_included_studies,
      ui_tab_workflow,
      # ui_tab_status,
      # ui_tab_model,
      ui_tab_rob,
      ui_tab_openresearch,
      ui_tab_funder,
      ui_tab_location,
      # ui_tab_int_summary,
      ui_tab_model_trends,
      #ui_tab_int_trends,
      #ui_tab_outcome_trends,
      ui_tab_evidence_map,
      # ui_tab_matrix,
      ui_tab_database,
      ui_tab_about
    )
  )
)

# Server ---------------------------

server <- function(input, output, session) {
  
  shinyalert("Welcome", "Welcome to the NDC-SOLES Dashboard!
             Please note this app is still under development and not all data has been processed yet.", type = "warning", confirmButtonCol = "#76A8C1")
  

  yearBarServer_included_only("included_studies_over_time_bar", 
                              table = n_included_per_year_plot_data, 
                              column = "is_included",
                              colour = "#76A8C1")
  
  output$funderBarChart <- renderPlotly({
    
    # Funder plot - data format
    top_funders <- funder_tag %>%
      select(funder_name, uid) %>%
      distinct() %>%
      group_by(funder_name) %>%
      count() %>%
      arrange(desc(n)) %>%
      head(11)
    
    # Funder plot - plot
    plot_ly(
      top_funders, 
      x = ~n, 
      y = ~funder_name, 
      type = "bar", 
      orientation = "h",
      marker = list(color = "#76A8C1")
    ) %>%
      layout(
        title = "Top 10 Funders by Number of Publications",
        xaxis = list(title = "Number of Publications"),
        yaxis = list(title = "", categoryorder = "total ascending"),
        margin = list(l = 200)  # Adjust for long funder names
      )
  })
  
  pico_multi_select_Server("model",
                           multi_select = FALSE,
                           table = model_tagging,
                           column = "name",
                           text = "Tool: custom regex drug dictionary")
  
  pico_multi_select_Server("species",
                           multi_select = FALSE,
                           table = species_tagging,
                           column = "name",
                           text = "Tool: custom regex drug dictionary")
  
  pico_multi_select_Server("sex",
                           multi_select = FALSE,
                           table = sex_tagging,
                           column = "name",
                           text = "Tool: custom regex drug dictionary")
  
  pico_multi_select_Server("outcome",
                           multi_select = FALSE,
                           table = outcome_tagging,
                           column = "name",
                           text = "Tool: custom regex drug dictionary")
  
  
  yearBarServer("oa_pubs_per_year", table=oa_tag, column="is_oa", display=c("open", "closed", "unknown"), order=c("open", "closed", "unknown"), text="Source:OpenAlex", colours = c("#76A8C1", "#FFC076", "grey")) %>%
    bindCache(nrow(transparency))
  yearBarServer("oa_pub_type_per_year", table=oa_tag, column="oa_status", display=c("hybrid", "bronze", "gold", "green", "diamond", "closed", "unknown"), order=c("hybrid", "bronze", "gold", "green", "diamond", "closed", "unknown"),
                text="Source:CrossRef", colours = c("pink", "orange", "gold", "green", "blue", "red", "grey")) %>% bindCache(nrow(transparency))
  yearBarServer("open_data_pubs_per_year", table=transparency, column="is_open_data", display= c("available", "not available", "unknown"), order=c("available", "not available", "unknown"),  text="Tool: OddPub, Riedel, N, et al. (2020), DOI:10.5334/dsj-2020-042", colours = c("#76A8C1", "#FFC076", "grey")) %>% bindCache(nrow(transparency))
  yearBarServer("open_code_pubs_per_year", table=transparency, column="is_open_code", display= c("available", "not available", "unknown"), order=c("available", "not available", "unknown"),  text="Tool: OddPub, Riedel, N, et al. (2020), DOI:10.5334/dsj-2020-042", colours = c("#76A8C1", "#FFC076", "grey")) %>% bindCache(nrow(transparency))
  
  
  yearBarServer("random_per_year", table=rob, column="is_random", display = c("reported", "not reported", "unknown"), order = c("reported", "not reported", "unknown"), colours = c("#76A8C1", "#FFC076", "grey"), text="Tool: RobPredictor, Wang, Q., et al (2021), DOI:10.1002/jrsm.1533") %>% bindCache(nrow(rob))
  yearBarServer("blind_per_year", table=rob, column="is_blind", display = c("reported", "not reported", "unknown"), order = c("reported", "not reported", "unknown"), colours = c("#76A8C1", "#FFC076", "grey"), text="Tool: RobPredictor, Wang, Q., et al (2021), DOI:10.1002/jrsm.1533") %>% bindCache(nrow(rob))
  yearBarServer("coi_per_year", table=rob, column="is_interest", display = c("reported", "not reported", "unknown"), order = c("reported", "not reported", "unknown"), colours = c("#76A8C1", "#FFC076", "grey"), text="Tool: RobPredictor, Wang, Q., et al (2021), DOI:10.1002/jrsm.1533") %>% bindCache(nrow(rob))
  yearBarServer("exclusion_per_year", table=rob, column="is_exclusion", display = c("reported", "not reported", "unknown"), order = c("reported", "not reported", "unknown"), colours = c("#76A8C1", "#FFC076", "grey"), text="Tool: RobPredictor, Wang, Q., et al (2021), DOI:10.1002/jrsm.1533") %>% bindCache(nrow(rob))
  yearBarServer("welfare_per_year", table=rob, column="is_welfare", display = c("reported", "not reported", "unknown"), order = c("reported", "not reported", "unknown"), colours = c("#76A8C1", "#FFC076", "grey"), text="Tool: RobPredictor, Wang, Q., et al (2021), DOI:10.1002/jrsm.1533") %>% bindCache(nrow(rob))
  
  search_Server("search_results",
                pico_data = pico_elements_list,
                table = included_with_metadata,
                combined_pico_table = pico,
                citations_for_download = included_with_metadata)
  

  bubble_react <- reactive({
    data <- data_for_bubble %>%
      filter(species %in% input$select_species) %>% 
      filter(model %in% input$select_model) %>% 
      filter(outcome %in% input$select_outcome) %>% 
      group_by(species, outcome) %>% 
      count()
    
    data$key <- row.names(data)
    data$col <- "#76A8C1"
    
    
    return(data)
  })
  
  table_react <- reactive({
    table <- data_for_bubble %>%
      filter(species %in% input$select_species) %>% 
      filter(model %in% input$select_model) %>% 
      filter(outcome %in% input$select_outcome) %>% 
      left_join(included_with_metadata, by = "uid") %>% 
      select(year, author, title, model, species, outcome, doi, url) %>% 
      mutate(link = ifelse(!is.na(doi), paste0("https://doi.org/", doi), url)) %>%
      arrange(desc(year))
    
    table$title <- paste0("<a href='",table$link, "' target='_blank'>",table$title,"</a>")
    
    table <- table %>% 
      select(-doi, -url, -link)
    
    
    
    
    
    return(table)
  })
  
  
  output$bubble_plot <- renderPlotly({
    
    click_data <- event_data("plotly_click", priority = "event")

    if (!is.null(click_data)) {
      
      bubble_react_new <- bubble_react() %>% 
        mutate(selected_colour = key %in% click_data$customdata)
      
      bubble_react_new$selected_colour <- bubble_react()$key %in% click_data$customdata
      
      bubble_react_new <- bubble_react_new %>% 
        mutate(col = case_when(
          selected_colour == FALSE ~ "#266080",
          selected_colour == TRUE ~ "#47B1A3"
        ))
      
    }
    else {
      bubble_react_new <- bubble_react()
      
    }
    
    p <- plot_ly(bubble_react_new,
                 x = ~species, y = ~outcome, size = ~n, 
                 colors = ~sort(unique(col)), color = ~col, customdata = ~key,
                 type = 'scatter', 
                 marker = list(symbol = 'circle', sizemode = 'diameter', opacity = 0.8,
                               line = list(color = '#FFFFFF', width = 2)),
                 hoverinfo = 'text',
                 textposition = "none",
                 text = ~paste("Species:", species,
                               "<br>Outcome:", outcome,
                               "<br>Number of Citations:", n)) %>% 
      layout(p, yaxis = list(title = list(text = "Outcome", standoff = 25)),
             xaxis = list(title = list(text = "Species", standoff = 25),
                          tickangle = -20,
                          ticklen = 1),
             hoverlabel = list(bgcolor = "white",
                               font = list(size = 14)),
             height = 550,
             showlegend = FALSE
      )
    
    event_register(p, event = "plotly_selecting")
    
  })
  
  output$pop_table <- DT::renderDataTable({
    
    d <- event_data("plotly_click")

    selected_studies <- table_react() %>% 
      filter(species %in% d$x,
             outcome %in% d$y)
    
    
    DT::datatable(
      selected_studies,
      rownames = FALSE,
      escape = FALSE,
      options = list(
        language = list(
          zeroRecords = "Click on a point to show data",
          emptyTable = "Click on a point to show data"),
        deferRender = FALSE,
        scrollY = 600,
        scrollX = 100,
        scroller = TRUE,
        columnDefs = list(
          list(
            targets = c(2), #target for JS code
            render = JS(
              "function(data, type, row, meta) {",
              "return type === 'display' && data.length > 100 ?",
              "'<span title=\"' + data + '\">' + data.substr(0, 100) + '...</span>' : data;",
              "}")),
          list(
            targets = c(1,2), #target for JS code
            render = JS(
              "function(data, type, row, meta) {",
              "return type === 'display' && data.length > 15 ?",
              "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;",
              "}")),

          list(width = '10%', targets = "_all")
        )
      )
      
    )
  })
  
  # Location - server -----
  scale_size <- function(num) {
    scales::rescale(num, c(3, 15))  # Adjust size range as necessary
  }
  
  # Create a reactive color palette
  color_palette <- reactive({
    colorFactor(palette = "Set2", domain = institution_tag$type)
  })
  
  
  # Location - filtered data -----
  filtered_map_data <- reactive({
    
    
    # If country is null
    if (is.null(input$country_select)) {
      
      inst_locations_filter <- institution_tag %>%
        filter(continent %in% input$continent_select,
               type %in% input$inst_type_select) %>%
        distinct()
      
    } else {
      
      inst_locations_filter <- institution_tag %>%
        filter(country %in% input$country_select,
               continent %in% input$continent_select,
               type %in% input$inst_type_select) %>%
        distinct()
    }
    
    if (nrow(inst_locations_filter >= 1)){
      inst_locations_filter <- inst_locations_filter %>%
        distinct()
      
    } else {
      
      inst_locations_filter <- institution_tag %>%
        distinct()
      
    }
    
    
    return(inst_locations_filter)
  })
  
  # Location - render leaflet map -----
  output$institution_map <- renderLeaflet({
    map_data <- filtered_map_data() %>%
      group_by(name) %>%
      mutate(filter_num_pubs = n_distinct(uid)) %>%
      ungroup()
    
    leaflet(map_data) %>%
      addProviderTiles(providers$Esri.WorldStreetMap
      ) %>%
      addCircleMarkers(
        ~long,
        ~lat,
        popup = ~paste0("<b>", name, "</b><br>",
                        "Institution Type: ", type, "<br>",
                        "No. of Publications: ", filter_num_pubs),
        radius = ~scale_size(filter_num_pubs),
        color = "black",
        fillColor = ~color_palette()(type),
        fillOpacity = 1,
        label = ~name,
        weight = 1,
        layerId = ~name
        
      ) %>%
      addLegend(
        position = "bottomleft",
        pal = color_palette(),
        values = ~type,
        title = "Institution Type",
        opacity = 0.8
      ) %>%
      setView(lat = 0, lng = 0, zoom = 1) %>%
      fitBounds(lng1 = min(filtered_map_data()$long, na.rm = TRUE) - 3,
                lat1 = min(filtered_map_data()$lat, na.rm = TRUE) - 3,
                lng2 = max(filtered_map_data()$long, na.rm = TRUE) + 3,
                lat2 = max(filtered_map_data()$lat, na.rm = TRUE) + 3)
    
    
  })
  
  
  observe({
    leafletProxy("institution_map", data = filtered_map_data()) %>%
      #clearShapes() %>%
      fitBounds(lng1 = min(filtered_map_data()$long, na.rm = TRUE) - 3,
                lat1 = min(filtered_map_data()$lat, na.rm = TRUE) - 3,
                lng2 = max(filtered_map_data()$long, na.rm = TRUE) + 3,
                lat2 = max(filtered_map_data()$lat, na.rm = TRUE) + 3)
    
  })

  
}
  
# Run the application
shinyApp(ui = ui, server = server)


