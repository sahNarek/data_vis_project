#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(plotly)

print(getwd())
load("../data/profitable_cars_us_am.rda")
cars_us_am <- cars_us_am %>% na.omit()
str(cars_us_am)

addPlotRow <- function(plotName1, plotName2) {
  return (fluidRow(splitLayout(cellWidths = c("50%", "50%"), plotlyOutput(plotName1),
                plotlyOutput(plotName2))
  ))
}

columns <- colnames(cars_us_am)
numeric_cols <- columns[sapply(cars_us_am, is.numeric)]

columns[numeric_cols]

ui <- fluidPage(
  titlePanel("Cars Auction Visualizations"),
  tabsetPanel(
    tabPanel("Numerical Data",
             sidebarLayout(
               sidebarPanel(
                 selectInput("plot_type", "Select plot type:", c("Scatter plot", "Bar plot")),
                 selectInput("x", "Select variable for X", numeric_cols),
                 selectInput("y", "Select variable for Y", numeric_cols)
               ),
               mainPanel(
                 plotlyOutput("plot")
               )
             )),
    tabPanel("Categorical Data"),
    tabPanel("Distributions",
             sidebarPanel(
               selectInput("model", "Car Model:",
                           c("All" = "ALL",
                             "Volkswagen" = "VOLKSWAGEN",
                             "Toyota" = "TOYOTA",
                             "Porsche" = "PORSCHE",
                             "Nissan" = "NISSAN",
                             "Mercedes-Benz" = "MERCEDES-BENZ",
                             "Mazda" = "MAZDA",
                             "Lexus" = "LEXUS",
                             "Honda" = "HONDA",
                             "BMW" = "BMW",
                             "Audi" = "AUDI",
                             "Acura" = "ACURA")),
               
               selectInput("damage_type", "Damage Type:",
                           c("All" = "All",
                             "Front" = "Front",
                             "Side" = "Side",
                             "Minor" = "Minor",
                             "Rear" = "Rear",
                             "Under" = "Under",
                             "Wear" = "Wear",
                             "All Over" = "ALL OVER",
                             "Rollover" = "ROLLOVER",
                             "Mechanical" = "Mechanical")),
               
               sliderInput("year", label = h3("Year"), min = min(cars_us_am$Year), 
                           max = max(cars_us_am$Year), value = min(cars_us_am$Year), step = 1)
             ),
             
             # Show a plot of the generated distribution
             mainPanel(addPlotRow("distPlotByModel", "odometerVSPrice"),
                       addPlotRow("cost_by_damage", "counts_by_year")))
  ),
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  # Loading the data
  output$plot <- renderPlotly({
    plot_ly(cars_us_am, x = ~get(input$x), y = ~get(input$y), type = "scatter", mode = "markers")
  })

  output$distPlotByModel <- renderPlotly({
    plot_price_distributions(input$model)
  })
  
  output$odometerVSPrice <- renderPlotly({
    plot_odometer_vs_price(input$model)
  })
  
  output$cost_by_damage <- renderPlotly({
    plot_cost_by_damage(input$damage_type)
  })
  
  output$counts_by_year <- renderPlotly({
    ggplot(cars_us_am[cars_us_am$Year == input$year, ], aes(x = Make)) + 
      geom_bar(fill = "red") + 
      theme(axis.text.x=element_text(angle = 90)) +
      labs(x = "Car Type", y = "Count") +
      ggtitle(paste("Car Counts by model for the year: ", input$year)) 
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

