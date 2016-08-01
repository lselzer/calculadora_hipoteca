
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

  output$yearly_inflation <- renderUI({
    # Depending on input$inflation, we'll generate a different
    # UI component and send it to the client.
    years <- 1:input$years
    inflation_n <-
      matrix(c(paste("inflation", years, sep = "_"),
               paste0("Año ", years, ":")), ncol = 2)
    inflation_year <- apply(inflation_n, 1, function(x){
      numericInput(x[1],
                   x[2],
                   0,
                   step = 0.01)
    }
    )
    inflation_year
    
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
    
    req(input$capital, input$interest_rate, input$years, input)
    # Calculate the inflation
    
    yearly_inflation <- switch(input$inflation,
           "fixed" = rep(input$inflation_fixed, input$years),
           "ie" = interpolate_inflation(c(input$inflation_init,
                                           input$inflation_end),
                                           input$years),
           "yearly" = do.call(rbind, match_all(input, "inflation_\\d+")))
    
    
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
  
  output$loan <- renderText({
    length(data())
  })
  
  output$tabla <- renderDataTable({
    data() %>% 
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
      gg <- ggplot(loan, aes(p, tot_pay)) +
        geom_line() +
        scale_y_continuous("Cuota", labels =  dollar_format())
      p <- ggplotly(gg)
      p  

  }
  )
}
)
