library(dplyr)
library(stringr)

cars_armenia <- read.csv("data/cars_armenia.csv")

price_in_usd <- function(price, rate = 390) {
  price <- str_replace_all(price, "֏", "AMD")
  price <- str_replace_all(price, "\\$", "USD")
  price <- str_replace_all(price, "€", "EU")
  if (grepl("AMD", price)){
    usd_price = str_replace_all(price,"AMD", "")
    usd_price = str_replace_all(usd_price, " ", "")
    usd_price = as.integer(as.numeric(usd_price) / rate)
    return(usd_price)
  }
  if (grepl("USD", price)){
    usd_price = str_replace_all(price, "USD", "")
    usd_price = str_replace_all(usd_price, " ", "")
    usd_price = as.integer(usd_price)
    return(usd_price)
  }
  if (grepl("EU", price)){
    usd_price = str_replace_all(price, "EU", "")
    usd_price = str_replace_all(usd_price, " ", "")
    usd_price = as.integer(as.numeric(usd_price) * 1.1)
    return(usd_price)
  }
  else{
    return(-1)
  }
}

odometer_in_miles <- function(odometer){
  if (grepl("miles", odometer)){
    mileage = str_replace_all(odometer,"miles", "")
    return(as.integer(mileage))
  }
  if (grepl("km", odometer)){
    mileage = str_replace_all(odometer,"km", "")
    return(as.integer(as.numeric(mileage) / 1.6 ))
  }
  else {
    return(-1)
  }
}

cars_armenia <- cars_armenia %>%
  filter(!(trimws(Price) %in% c("Negotiable", "")), !(HandDrive == "Right")) %>%
  mutate(ProductionYear = sapply(strsplit(Name, " "), '[', 1),
         Name = trimws(str_replace(Name, ProductionYear, "")),
         Mileage = unlist(lapply(Mileage, odometer_in_miles)),
         Price = unlist(lapply(Price, price_in_usd)),
         Color = as.factor(Color),
         BodyStyle = as.factor(BodyStyle),
         Make = as.factor(Make),
         Engine = as.factor(Engine),
         Gearbox = as.factor(Gearbox)
  ) %>%
  filter(Price != -1, Mileage != -1)
str(cars_armenia)
save(cars_armenia, file = "./data/cars_armenia.rda")
