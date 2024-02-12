plot_bubble_matrix <- function(df1, df2, x, y) {
  
  x <- ggplot2::enquo(x)
  y <- ggplot2::enquo(y)
  
  df1 <- df1 %>%
    select(uid, !!x)
  
  df2 <- df2 %>%
    select(uid, !!y)
  
  df <- inner_join(df1, df2)
  df <- df %>%
    select(-uid)
  
  freq_table <- table(df)
  
  freq_table <- as.data.frame(freq_table)
  freq_table <- freq_table %>%
    filter(Freq > 5) %>%
    mutate(text = paste0("Estimated number of papers:  ", Freq))
  
  # Classic ggplot
  p <- ggplot(freq_table, aes(size = Freq, color = Freq, text=text)) +
    geom_point(aes(!!x, !!y, alpha=0.7)) + 
    scale_color_viridis(discrete=FALSE, guide=FALSE) +
    theme(legend.position="none") +
    xlab("") + ylab("") +  theme_light() + theme(axis.text.x = element_text(angle = 60, hjust = 1)) 
  
  # turn ggplot interactive with plotly
  pp <- ggplotly(p, tooltip="text")
  pp %>%
    layout(autosize = T,
           paper_bgcolor="transparent",
           autoexpand = TRUE,
           xaxis = list(size = 14), 
           yaxis = list(size = 14))
  
  
}


