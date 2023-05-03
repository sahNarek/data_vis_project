from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from urllib.parse import urlencode
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import ActionChains
from bs4 import BeautifulSoup
import requests
import time
import json
import pandas as pd
import os
import logging
import csv
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("debug.log"),
        logging.StreamHandler(sys.stdout)
    ]
)


class AutoAmScrapper:

    def __init__(self, main_url = "https://auto.am/lang/en", driver_path = "/usr/local/bin/chromedriver") -> None:
        self.driver = webdriver.Chrome(driver_path)
        self.main_url = main_url
        self.driver.get(self.main_url)
        self.start()
    
    def start(self):
        headers = ["Id","Mileage","Version","BodyStyle","Gearbox","HandDrive","Engine","Color","name","InteriorColor","EngineVolume","Horsepower","Drivetrain","DoorCount","Wheels","EngineCylinders"]
        write_headers = False
        if not os.path.exists("cars_armenia.csv"):
             write_headers = True
        with open("./cars_armenia.csv", 'a+', newline='') as f:
            self.writer = csv.writer(f)
            if write_headers:
                self.writer.writerow(headers)
        
        self.search_cars()

    def search_cars(self):
        us_cars = pd.read_csv(os.path.join("data","filtered_cars.csv"))
        groups = us_cars.groupby(["Make","Model.Group"]).groups
        for group_name, _  in groups.items():
            self.make, self.model = group_name
            logging.info(f"Fetching data for {self.make} {self.model}")
            self.search_cars_by_make()
            self.driver.find_element(By.ID, "header-logo").click()
            time.sleep(3)

    def search_cars_by_make(self):
        time.sleep(3)
        make_found = self.filter_attribute(self.make,"select2-filter-make-container","select2-search__field","select2-results__option")
        if make_found:
            model_found = self.filter_attribute(self.model,"select2-v-model-container","select2-search__field","select2-results__option")
            if model_found:
                year_from = 2016
                year_to = 2019
                time.sleep(4)
                self.driver.find_elements(By.CLASS_NAME, "select2-selection__rendered")[2].click()
                input_element = self.driver.find_element(By.CLASS_NAME, "select2-search__field")
                input_element.send_keys(year_from)
                input_element.send_keys(Keys.ENTER)
                self.driver.find_elements(By.CLASS_NAME, "select2-selection__rendered")[3].click()
                input_element = self.driver.find_element(By.CLASS_NAME, "select2-search__field")
                input_element.send_keys(year_to)
                input_element.send_keys(Keys.ENTER)
                time.sleep(2)
                self.driver.find_elements(By.CLASS_NAME, "lever")[2].click()
                try:
                    search_button = self.driver.find_element(By.ID, "search-btn")
                    if search_button:
                        search_button.click()
                        self.get_model_data()
                except Exception as e:
                    logging.info(str(e))
                    logging.info("No results were found")
                time.sleep(5)
            else:
                logging.info(f"Unable to find data for {self.make} {self.model}")
                with open("./missing_models.csv", "a+") as f:
                    missing_models_writer = csv.writer(f)
                    missing_models_writer.writerow([self.make, self.model])

    def get_car_details(self, link):
        page = requests.get("https://auto.am/lang/en", headers={"referer":link})
        soup = BeautifulSoup(page.content, 'html.parser')
        table = soup.find('table', class_='pad-top-6 ad-det')
        name = soup.find("title")
        row = {}
        for tr in table.tbody.find_all("tr"):
            table_values = tr.find_all("td")
            for i in range(0, len(table_values) - 1):
                column = table_values[i].text.strip().replace(" ", "")
                value = table_values[i + 1].text.strip().replace(" ", "")
                row[column] = value
        row["name"] = name.text.strip().replace(" - Auto.am", "")
        row["model"] = self.model
        row["make"] = self.make
        with open("./cars_armenia.csv", 'a+', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(row.values())
    
    def get_model_data(self):
        all_pages_viewed = False
        page = 1
        while not all_pages_viewed:
            time.sleep(3)
            links_xpath = "//div[@id='search-result']//div[contains(@id, 'ad')]//a[@href]"
            links = [link.get_attribute("href") for link in self.driver.find_elements(By.XPATH, links_xpath)]
            for link in list(set(links)): 
                if "https://auto.am/offer/" in link:
                    self.get_car_details(link)
            page = page + 1
            try:
                next_page_element = self.driver.find_element(By.LINK_TEXT, str(page))
                next_page_element.click()
            except Exception as e:
                logging.error(str(e))
                logging.info("All pages viewed")
                all_pages_viewed = True
                continue
            time.sleep(3)
        # pd.DataFrame(self.rows).to_csv("test.csv")

    def get_make_ids(self):
        selection_element = self.driver.find_element(By.ID, "filter-make")
        select = Select(selection_element)
        self.make_ids = {option.text : option.get_attribute("value") for option in select.options}
    
    def filter_attribute(self,attribute,select_id,input_id,results_cls):
        select_element = self.driver.find_element(By.ID, select_id)
        select_element.click()
        input_element = self.driver.find_element(By.CLASS_NAME, input_id)
        input_element.send_keys(attribute)
        resulted_elements = self.driver.find_elements(By.CLASS_NAME, results_cls)
        if resulted_elements[0].text.lower() == "no results found":
            return False
        input_element.send_keys(Keys.ENTER)
        time.sleep(3)
        return True
  
    def search_by_make(self, make_id):
        params = {
                    "category":"1",
                    "page":"1",
                    "sort":"latest",
                    "layout":"list",
                    "user":{"dealer":"0","official":"0","id":""},
                    "make":[make_id],"year":{"gt":"1911","lt":"2024"},
                    "usdprice":{"gt":"0","lt":"100000000"},
                    "mileage":{"gt":"10","lt":"1000000"}
                }
        search_url = f"{self.main_url}/search/passenger-cars/?q={json.dumps(params)}"
        logging.info(search_url)
        self.driver.get(search_url)
        time.sleep(20)
        WebDriverWait(self.driver, 10)

AutoAmScrapper()
