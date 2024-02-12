ui_tab_home <- tabItem(tabName = "home",
                       useShinyalert(force = TRUE),
                       bs4Jumbotron(
                         title = "Welcome to NDC-SOLES",
                         lead = "NDC-SOLES uses a series of automated tools and machine-learning approaches to systematically collect, synthesise, and display experimental evidence in genetically-modified animal models of neurodevelopmental conditions.",
                         status = "primary",
                         btnName = span("Tell us what you think of NDC-SOLES!", style = "color:black;"),
                         href = "https://forms.gle/bTPoiB9G7Yorpyxc9"
                         ),
                       fluidRow(
                         box(width = 4,
                             height = "8em",
                             title = span("Research overview", style="color:black"),
                             status = "secondary",
                             solidHeader = TRUE,
                             p("See trends in methodology, open research practices and report quality.")),
                         box(width = 4,
                             height = "8em",
                             title = span("Identify studies", style="color:black"),
                             status = "secondary",
                             solidHeader = TRUE,
                             p("Find research that’s relevant to you using our searchable, filterable database of published studies.")),
                         box(width = 4,
                             height = "8em",
                             title = span("Systematic reviews", style="color:black"),
                             status="secondary",
                             solidHeader = TRUE,
                             p("Save time on your systematic review by using SOLES to identify relevant research.")))
                       )