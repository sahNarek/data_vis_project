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

cars <- read.csv("filtered_cars.csv")

addPlotRow <- function(plotName1, plotName2) {
  return (fluidRow(splitLayout(cellWidths = c("50%", "50%"), plotlyOutput(plotName1),
                plotlyOutput(plotName2))
  ))
}

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Cars Auction Visualizations"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
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
                        "Mechanical" = "Mechanical",
                        "Vandalism" = "Vandalism",
                        "Stripped" = "STRIPPED")),
          
          sliderInput("year", label = h3("Year"), min = min(cars$Year), 
                      max = max(cars$Year), value = min(cars$Year), step = 1)
        ),
        
        # Show a plot of the generated distribution
        mainPanel(addPlotRow("distPlotByModel", "odometerVSPrice"),
                  addPlotRow("cost_by_damage", "counts_by_year")
        )
    )
)

plot_price_distributions <- function(selectedModel) {
  if (selectedModel == "ALL") {
    result_plot <- ggplot(cars, aes(Price, fill = Make, colour = Make)) + 
                          geom_density(alpha = 0.3) +
                          labs(x = "Price in dollars", y = "Density") +
                          ggtitle("Distribution of the cars by price")
    return (result_plot)
  }
  
  result_plot <- ggplot(cars[cars$Make == selectedModel, ], aes(Price)) + 
                          geom_density(color="darkblue", fill="lightblue", alpha = 0.3) +
                          labs(x = "Price in dollars", y = "Density") +
                          ggtitle("Distribution of the selected model by price")
  return (result_plot)
}

plot_odometer_vs_price <- function(selectedModel) {
  if (selectedModel == "ALL") {
    result_plot <- ggplot(cars, aes(x = Price, y = Odometer, fill = Make, colour = Make)) + 
      geom_point(alpha = 0.3) +
      labs(x = "Price in Dollars", y = "Odometer") +
      ggtitle("Price VS Odometer")
    
    return (result_plot)
  }
  
  result_plot <- ggplot(cars[cars$Make == selectedModel, ], aes(x = Price, y = Odometer)) +
    geom_point(color="darkblue", fill="lightblue", alpha = 0.3) +
    labs(x = "Price in Dollars", y = "Odometer") +
    ggtitle("Price VS Odometer")
  
  return (result_plot)
}

plot_cost_by_damage <- function(selectedDamageType) {
  if (selectedDamageType == "All") {
    cars_clean <- cars %>% filter(Damage.Description != "DAMAGE HISTORY")
    result_plot <- ggplot(cars_clean, aes(y = Repair.cost, x = Damage.Description)) +
      geom_boxplot(fill = "lightblue") + 
      labs(x = "Damage Type", y = "Repair Cost") +
      ggtitle("Damage type and Repair Cost") +
      theme(axis.text.x=element_text(angle=90))
    
    return (result_plot)
  }
  
  result_plot <- ggplot(cars[cars$Damage.Description == selectedDamageType, ], aes(y = Repair.cost)) +
    geom_boxplot(fill = "lightblue") + 
    labs(x = "Damage Type", y = "Repair Cost") +
    ggtitle("Damage type and Repair Cost") + 
    theme(axis.text.x=element_text(angle=90))
  
  return (result_plot)
  
}

# Define server logic required to draw a histogram
server <- function(input, output) {
  # Loading the data
  
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
    ggplot(cars[cars$Year == input$year, ], aes(x = Make)) + 
      geom_bar(fill = "red") + 
      theme(axis.text.x=element_text(angle = 90)) +
      labs(x = "Car Type", y = "Count") +
      ggtitle(paste("Car Counts by model for the year: ", input$year)) 
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

