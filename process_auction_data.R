library(dplyr)

car_prices_usa <- read.csv("data/cars.csv")

profitable_cars <- car_prices_usa %>% 
                    filter(Year >= 2016)

profitable_cars <- profitable_cars %>%
  group_by(Make, Model.Group) %>%
  distinct() %>%
  arrange((Make))

car_models <- distinct(profitable_cars,Make,Model.Group)

write.csv(car_models, "data/car_models.csv")
write.csv(profitable_cars, "data/filtered_cars.csv")
