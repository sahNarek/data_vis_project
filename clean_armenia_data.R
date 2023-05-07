library(dplyr)
library(stringr)

cars_armenia <- read.csv("./cars_armenia.csv")

price_in_usd <- function(price, rate = 390) {
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
}

cars_armenia <- cars_armenia %>%
  filter(!(Price %in% c("Negotiable", "")), !(HandDrive == "Right")) %>%
  mutate(ProductionYear = sapply(strsplit(Name, " "), '[', 1),
         Name = trimws(str_replace(Name, ProductionYear, "")),
         Price = str_replace_all(Price, "֏", "AMD"),
         Price = str_replace_all(Price, "\\$", "USD"),
         Price = str_replace_all(Price, "€", "EU"),
         Price = sapply(Price, price_in_usd),
         Mileage = sapply(Mileage, odometer_in_miles),
         Color = as.factor(Color),
         BodyStyle = as.factor(BodyStyle),
         Make = as.factor(Make),
         Engine = as.factor(Engine),
         Gearbox = as.factor(Gearbox)
  )

save(cars_armenia, file = "./data/cars_armenia.rda")
