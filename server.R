
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(ggplot2)
library(scales)
library(plotly)
library(dplyr)
source("functions.R")




shinyServer(function(input, output) {
# Controles ---------------------------------------------------------------  
  # output$input_type_text <- renderText({
  #   input$inflation
  # })

  output$controls <- renderUI({
    # if (is.null(input$inflation))
    #   return()
    

  # Depending on input$inflation, we'll generate a different
  # UI component and send it to the client.
    inflation_fixed <- list(
    sliderInput("inflation_fixed",
                "Inflación:",
                0,
                100,
                0,
                step = 0.01,
                post = "%")
  )
  inflation_IE <- list(
    sliderInput("inflation_init",
                "Inflación inicial:",
                0,
                100,
                0,
                step = 0.01,
                post = "%"),
    sliderInput("inflation_end",
                "Inflación final:",
                0,
                100,
                0,
                step = 0.01,
                post = "%")
  )

    years <- 1:input$years
    inflation_n <-
      matrix(c(paste("inflation", years, sep = "_"),
               paste0("Inflación Año", years, ":")), ncol = 2)
    inflation_year <- apply(inflation_n, 1, function(x){
      numericInput(x[1],
                   x[2],
                   0,
                   step = 0.01)
    }
    )

  switch(input$inflation,
         "Fija" = inflation_fixed,
         "Inicio-Fin" =  inflation_IE,
         "Anual" =  inflation_year)

  }
  )

# Resultados ---------------------------------------------------------------  
  output$input_inflation_init <- renderText(
    c(input$inflation_init, input$inflation_end)
  )
  output$all_values <- renderText({
    c(capital = input$capital, interest = input$interest_rate, 
               years = input$years, inflation = input$inflation)
  }
)
  d <- reactiveValues(loans = list())
  data <- reactive({
    
    
    # Calculate the inflation
    
    yearly_inflation <- switch(input$inflation,
           "Fija" = rep(input$inflation_fixed, input$years),
           "Inicio-Fin" = interpolate_inflation(c(input$inflation_init,
                                           input$inflation_end),
                                           input$years),
           "Anual" = do.call(rbind, match_all(input, "inflation_\\d+")))
    
    
    monthly_inflation <- to_monthly_rate(yearly_inflation/100) %>% 
      rep(., each = 12)
    
    # Calculate the loan
    
    d$loan <- lifetime_loan(capital = input$capital, 
                            price = 1,
                            yearly_rate = input$interest_rate / 100,
                            n = input$years * 12,
                            inflation = monthly_inflation)
    d$loan
  })
  output$tabla <- renderDataTable({
    d$loan %>% 
      select(tot_pay, int_pay, cap_pay, uvi, capital_left) %>% 
      rename("Cuota Total" = tot_pay,
             "Interés Pagado" = int_pay,
             "Capital Pagado" = cap_pay,
             "UVI" = uvi,
             "Capital Debido" = capital_left) %>% 
      datatable() %>% 
      formatCurrency(columns = c(1:3, 5)) %>% 
      formatRound(columns = 4)
  }
  )
  output$total_paid <- renderPlotly({
    req(input$capital)
    loan <- data()
    
      # draw the total_paid to n
    gg <- ggplot(loan, aes(p, cum_total_paid)) +
      geom_line() +
      scale_y_continuous("Total Pagado", labels =  dollar_format())
    p <- ggplotly(gg)
    p
  })
  output$payment <- renderPlotly({
    loan <- data()
    if (is.null(loan))
      return()
    gg <- ggplot(loan, aes(p, tot_pay)) +
    geom_line() +
      scale_y_continuous("Cuota", labels =  dollar_format())
    p <- ggplotly(gg)
    p
  }
  )
}
)
