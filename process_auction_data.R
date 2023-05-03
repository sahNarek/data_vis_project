library(dplyr)

car_prices_usa <- read.csv("data/cars.csv")

profitable_cars <- car_prices_usa %>% 
                    filter(Year >= 2016)

profitable_cars <- profitable_cars %>%
  arrange(desc(Make))

write.csv(profitable_cars, "data/filtered_cars.csv")
