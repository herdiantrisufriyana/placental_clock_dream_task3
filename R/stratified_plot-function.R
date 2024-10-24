stratified_plot <-
  function(plot1, name1, plot2, name2, plot3, name3, plot4, name4, height = 8){
    if(!is.null(plot1) & !is.null(name1)){
      plot1 <-
        plot1 + theme(legend.position = "none") +
        ggtitle(name1)
    }else{
      plot1 = NULL
    }
    
    if(!is.null(plot2) & !is.null(name2)){
      plot2 <-
        plot2 +
        theme(
          legend.position = "none"
          ,axis.text.y = element_blank()
          ,strip.text.y.left = element_blank()
        ) +
        ggtitle(name2)
    }else{
      plot2 = NULL
    }
    
    if(!is.null(plot3) & !is.null(name3)){
      plot3 <-
        plot3 +
        theme(
          legend.position = "none"
          ,axis.text.y = element_blank()
          ,strip.text.y.left = element_blank()
        ) +
        ggtitle(name3)
    }else{
      plot3 = NULL
    }
    
    if(!is.null(plot4) & !is.null(name4)){
      plot4 <-
        plot4 +
        theme(
          axis.text.y = element_blank()
          ,strip.text.y.left = element_blank()
        ) +
        ggtitle(name4)
    }else{
      plot4 = NULL
    }
    
    ggarrange(
      plot1
      ,plot2
      ,plot3
      ,plot4
      ,nrow = 1
      ,ncol = 4
      ,widths = c(3.5, 2, 2, 2.5)
      ,heights = c(height)
    )
  }