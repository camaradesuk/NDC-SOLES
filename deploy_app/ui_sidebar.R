ui_sidebar <- sidebarMenu(
  bs4SidebarMenuItem("Home", tabName = "home", icon = icon("home", verify_fa = FALSE)),
  bs4SidebarMenuItem("Data collection", tabName = "dc-main", icon = icon("database", verify_fa = FALSE), startExpanded = FALSE,
                     bs4SidebarMenuSubItem("Included studies", tabName = "studies-included-summary-dc"),
                     bs4SidebarMenuSubItem("Workflow", tabName = "workflow-accordion-dc")),
  #bs4SidebarMenuItem("Data collection old", tabName = "workflow", icon = icon("database", verify_fa = FALSE)),
  bs4SidebarMenuItem("Risk of bias", tabName = "data-summary-rob", icon = icon("check", verify_fa = FALSE)),
  bs4SidebarMenuItem("Open research", tabName = "data-summary-openresearch", icon = icon("lock-open", verify_fa = FALSE)),
  bs4SidebarMenuItem("Funders", tabName = "data-summary-funder", icon = icon("landmark", verify_fa = FALSE)),
  bs4SidebarMenuItem("Animal models", tabName = "data-trends-model", icon = icon("paw"), startExpanded = FALSE),
  bs4SidebarMenuItem("Interventions", tabName = "data-trends-int", icon = icon("pills"), startExpanded = FALSE),
                     #bs4SidebarMenuSubItem("Intervention summary", tabName = "data-summary-int"),
                     #bs4SidebarMenuSubItem("Trends", tabName = "data-trends-int")),
  bs4SidebarMenuItem("Experimental outcomes", tabName = "data-trends-outcome", icon = icon("microscope", verify_fa = FALSE)),
  #bs4SidebarMenuItem("Matrix", tabName = "matrix", icon = icon("border-all", verify_fa = FALSE)),
  bs4SidebarMenuItem("Evidence Map", tabName = "pico-bubble", icon = icon("border-all", verify_fa = FALSE)),
  bs4SidebarMenuItem("Search database", tabName = "search-database", icon = icon("search", verify_fa = FALSE)),
  bs4SidebarMenuItem("About", tabName = "about", icon = icon("info", verify_fa = FALSE))
  
)