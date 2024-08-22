mytheme <- create_theme(
  bs4dash_vars(
    navbar_light_color = "#76A8C1",
    navbar_light_active_color = "#000",
    navbar_light_hover_color = "#000"
  ),
  bs4dash_yiq(
    contrasted_threshold = 80,
    text_dark = "#FFF",
    text_light = "#000"
  ),
  bs4dash_layout(
    main_bg = "#FFF"
  ),
  bs4dash_sidebar_light(
    bg = "#76A8C1",
    color = "#FFF",
    hover_color = "#FFF",
  ),
  bs4dash_status(
    primary = "#76A8C1", 
    danger = "#C6804F",  
    info = "#FFD251", 
    secondary = "#344149"
  ),
  bs4dash_color(
    gray_900 = "#344149"
  )
)