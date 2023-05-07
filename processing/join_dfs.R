library(dplyr)

load("data/cars_armenia.rda")
us_cars <- read.csv("data/filtered_with_import.csv")

cars_armenia <- cars_armenia %>%
  select(c(OfferId,Make,Model,Name,ProductionYear,Color,Engine,Gearbox,BodyStyle,Mileage,Price))

us_cars <- us_cars %>%
  select(-c(Unnamed..0))

cars_armenia$ProductionYear <- as.integer(cars_armenia$ProductionYear)


cars_us_am <- left_join(us_cars, cars_armenia, by = join_by(x$Make == y$Make, 
                                                             x$Model.Group == y$Model, 
                                                             x$Year == y$ProductionYear))

cars_us_am <- cars_us_am %>%
  na.omit()

cars_us_am$ShippingCost <- 3000

cars_us_am <- cars_us_am %>%
  filter((Price.x * 1.15 + ImportPrice + ShippingCost) < Price.y)

write.csv(cars_us_am,file="data/profitable_cars_us_am.csv")
save(cars_us_am, file = "data/profitable_cars_us_am.rda")
