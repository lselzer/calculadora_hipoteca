
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Préstamos Hipotecarios"),

  # Sidebar with a slider input the capital loan, interest rate and inflation
  sidebarLayout(
    sidebarPanel(
      sliderInput("capital",
                  "Monto del Préstamo:",
                  min = 1000,
                  max = 3e6,
                  value = 1e6,
                  step = 10000),
      sliderInput("interest_rate",
                  "Tasa de interés anual:",
                  min = 0,
                  max = 20,
                  value = 5,
                  step = 0.01,
                  post = "%"),
      sliderInput("years",
                  "Años de préstamo:",
                  min = 5,
                  max = 20,
                  value = 15,
                  step = 1),
      radioButtons("inflation",label = "Inflación:",
                   choices = c("Fija" = "fixed",
                               "Inicio-Fin" = "ie", 
                               "Anual" = "yearly")),
      conditionalPanel(
        condition = "input.inflation == 'fixed'",
        sliderInput("inflation_fixed",
                    "Inflación:",
                    0,
                    100,
                    0,
                    step = 0.01,
                    post = "%")
      ),
      conditionalPanel(
        condition = "input.inflation == 'ie'",
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

    ),
    conditionalPanel(
      condition = "input.inflation == 'yearly'",
      tags$p(tags$b("Inflación:")),
      uiOutput("yearly_inflation")
      )
  ),
    
    
    

    # Show a plot of the generated distribution
    mainPanel(
      fluidRow(
        column(width = 3,
               wellPanel(
                 tags$p("Dynamic input value:"),
                 verbatimTextOutput("loan")
        
               )
        )
        ,
        column(width = 3,
               wellPanel(
                 tags$p("Inputs:"),
                 verbatimTextOutput("all_values")
               )
        )
      ),
      fluidRow(
        column(width = 6,
               plotlyOutput("total_paid")
        ),
        column(width = 6,
               plotlyOutput("payment")
        )
      ),
      wellPanel(
        dataTableOutput("tabla")
      )
      
    )
  )
))
