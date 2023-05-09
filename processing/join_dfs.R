library(dplyr)

load("./data/cars_armenia.rda")
us_cars <- read.csv("./data/filtered_with_import.csv")

am_cars <- cars_armenia

am_cars <- am_cars %>%
  select(c(OfferId,Make,Model,Name,ProductionYear,Color,Engine,Gearbox,BodyStyle,Mileage,Price))

us_cars <- us_cars %>%
  select(-c(Unnamed..0))

tax_calculator <- function(price, volume){
  total_price_eu <- ((price * 1.20) * 0.9) + 3000
  engine_tax <- as.numeric(volume) * 440
  price_tax <- total_price_eu * 0.20
  duty_tax <- pmax(engine_tax, price_tax)
  vat <- (total_price_eu + duty_tax) * 0.2
  env_tax <- total_price_eu * 0.02
  overall_tax <- (duty_tax + env_tax + vat)
  return(as.integer(overall_tax))
}


us_cars$ImportPrice <- tax_calculator(us_cars$Price, us_cars$Engine)
us_cars$ShippingCost <- 3000

am_make_models <- distinct(am_cars, Make, Model)

us_cars <- us_cars %>%
  filter(Make %in% unique(am_make_models$Make), 
         Model.Group %in% unique(am_make_models$Model))

am_cars <- am_cars %>%
  filter(Price != 1000000)


# am_cars$ProductionYear <- as.integer(am_cars$ProductionYear)
# 
# 
# cars_us_am <- left_join(us_cars, am_cars, by = join_by(x$Make == y$Make, 
#                                                              x$Model.Group == y$Model, 
#                                                              x$Year == y$ProductionYear))
# 
# cars_us_am <- cars_us_am %>%
#   na.omit()
# 
# cars_us_am$ShippingCost <- 3000

# cars_us_am <- cars_us_am %>%
#   filter((Price.x * 1.15 + ImportPrice + ShippingCost) < Price.y)

us_cars <- us_cars %>% filter(!(Damage.Description %in% c("STRIPPED","DAMAGE HISTORY")))
am_cars$ProductionYear <- as.integer(am_cars$ProductionYear)

levels(am_cars$Color)[match("Օthercolor",levels(am_cars$Color))] <- "Other Color"


write.csv(us_cars, file = "./data/us_cars.csv")
save(us_cars, file = "./data/us_cars.rda")
write.csv(am_cars, file = "./data/am_cars.rda")
save(am_cars, file = "data/am_cars.rda")
