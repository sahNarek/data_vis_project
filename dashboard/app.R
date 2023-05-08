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
library(dplyr)

load("../data/us_cars.rda")
load("../data/am_cars.rda")

addPlotRow <- function(plotName1, plotName2) {
  return (fluidRow(splitLayout(cellWidths = c("50%", "50%"), plotlyOutput(plotName1),
                plotlyOutput(plotName2))
  ))
}

us_cars$Engine <- as.factor(us_cars$Engine)

us_columns <- colnames(us_cars)
am_columns <- colnames(am_cars)
am_numeric_cols <- am_columns[sapply(am_cars, is.numeric)]
us_numeric_cols <- us_columns[sapply(us_cars, is.numeric)]
us_numeric_cols <- us_numeric_cols[!(us_numeric_cols %in% c("Year","VIN"))]
am_numeric_cols <- am_numeric_cols[!(am_numeric_cols %in% c("OfferId"))]

us_cat_cols <- us_columns[sapply(us_cars, is.character)]
us_factor_cols <- us_columns[sapply(us_cars, is.factor)]
us_cat_cols <- c(us_cat_cols, us_factor_cols)
us_cat_cols <- us_cat_cols[!(us_cat_cols %in% c("VIN","Model.Group", "Model.Detail"))]

am_cat_cols <- am_columns[sapply(am_cars, is.factor)]

ui <- fluidPage(
  titlePanel("Cars Auction Visualizations"),
  tabsetPanel(
    tabPanel("Numerical Data",
             sidebarLayout(
               sidebarPanel(
                 selectInput("dataframe", "Select Dataframe:", 
                             c("Cars from Copart","Cars from auto.am"),
                             selected = "Cars from Copart"
                             ),
                 conditionalPanel(
                   condition = "input.dataframe == 'Cars from Copart'",
                   selectInput("x_copart", "Select a variable for X", us_numeric_cols, selected = "Odometer"),
                   selectInput("y_copart", "Select a variable for Y", us_numeric_cols, selected = "Price"),
                   selectInput("fill_copart", "Select a categorical variable for filling", c("None",us_cat_cols), selected = "Make")
                 ),
                 conditionalPanel(
                   condition = "input.dataframe == 'Cars from auto.am'",
                   selectInput("fill_cars_am", "Select a categorical variable for filling", c("None",am_cat_cols), selected = "Make")
                   # selectInput("x_cars_am", "Select variable for X (AM)", am_numeric_cols, s),
                   # selectInput("y_cars_am", "Select variable for Y (AM)", am_numeric_cols)
                 ),
               ),
               mainPanel(
                 plotlyOutput("plot")
               )
             )),
    tabPanel("Categorical Data",
             sidebarLayout(
               sidebarPanel(
                 selectInput("dataframe_bar", "Select Dataframe:", 
                             c("Cars from Copart","Cars from auto.am"),
                             selected = "Cars from Copart"
                 ),
                 conditionalPanel(
                   condition = "input.dataframe_bar == 'Cars from Copart'",
                   selectInput("x_copart_bar", "Select a categorical variable for X", us_cat_cols, selected = "Make"),
                   selectInput("y_copart_bar", "Select a numerical variable for Y", c("Count",us_numeric_cols), selected = "Price")
                 ),
                 conditionalPanel(
                   condition = "input.dataframe_bar == 'Cars from auto.am'",
                   selectInput("x_cars_am_bar", "Select a categorical variable for X", am_cat_cols, selected = "Make"),
                   selectInput("y_cars_am_bar", "Select a numerical variable for Y", c("Count",am_numeric_cols), selected = "Price")
                 ),
               ),
               mainPanel(
                 plotlyOutput("barPlot")
               )
             )),
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
               
               sliderInput("year", label = h3("Year"), min = min(us_cars$Year), 
                           max = max(us_cars$Year), value = min(us_cars$Year), step = 1)
             ),
             
             # Show a plot of the generated distribution
             mainPanel(addPlotRow("distPlotByModel", "odometerVSPrice"),
                       addPlotRow("cost_by_damage", "counts_by_year")))
  ),
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  output$plot <- renderPlotly({
    group = ""
    if (input$dataframe == "Cars from Copart"){
      df = us_cars
      x = ~get(input$x_copart)
      y = ~get(input$y_copart)
      if (input$fill_copart != "None"){
        group = ~get(input$fill_copart)
      }
    }
    if (input$dataframe == "Cars from auto.am"){
      df = am_cars
      x = ~get("Mileage")
      y = ~get("Price")
      if (input$fill_cars_am != "None"){
        group = ~get(input$fill_cars_am)
      }
    }
    
    if (group == "") {
      plot_ly(df, x = x, y = y, type = "scatter", mode = "markers")
    } 
    else {
      plot_ly(df, x = x, y = y, color = group, type = "scatter", mode = "markers")
    }
  })
  
  output$barPlot <- renderPlotly({
    group = ""
    if (input$dataframe_bar == "Cars from Copart"){
      df = us_cars
      x = ~get(input$x_copart_bar)
      if(input$y_copart_bar == "Count"){
        df = df %>%
          group_by_at(input$x_copart_bar) %>%
          summarize(count = n())
        y = ~count
      }
      else{
        y = ~get(input$y_copart_bar)
      }
    }
    if (input$dataframe_bar == "Cars from auto.am"){
      df = am_cars
      x = ~get(input$x_cars_am_bar)
      if(input$y_cars_am_bar == "Count"){
        df <- df %>%
          group_by_at(input$x_cars_am_bar) %>%
          summarize(count = n())
        y = ~count
      }
      else{
        y = ~get(input$y_cars_am_bar)
      }
    }
    plot_ly(df, x = x, y = y, type = "bar")
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
    ggplot(us_cars[us_cars$Year == input$year, ], aes(x = Make)) + 
      geom_bar(fill = "red") + 
      theme(axis.text.x=element_text(angle = 90)) +
      labs(x = "Car Type", y = "Count") +
      ggtitle(paste("Car Counts by model for the year: ", input$year)) 
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

