from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from urllib.parse import urlencode
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
import time
import json



class AutoAmScrapper:

    def __init__(self, main_url = "https://auto.am/lang/en", driver_path = "/usr/local/bin/chromedriver") -> None:
        self.driver = webdriver.Chrome(driver_path)
        self.driver.get(main_url)
        self.main_url = main_url
        self.search_cars()
    
    def search_cars(self):
        make_found = self.filter_attribute("BMW","select2-filter-make-container","select2-search__field","select2-results__option")
        if make_found:
            model_found = self.filter_attribute("3 Series","select2-v-model-container","select2-search__field","select2-results__option")
            print(model_found)
            if model_found:
                year_from = 2017
                year_to = 2023
                time.sleep(4)
                self.driver.find_elements(By.CLASS_NAME, "select2-selection__rendered")[2].click()
                input_element = self.driver.find_element(By.CLASS_NAME, "select2-search__field")
                input_element.send_keys(year_from)
                input_element.send_keys(Keys.ENTER)
                self.driver.find_elements(By.CLASS_NAME, "select2-selection__rendered")[3].click()
                input_element = self.driver.find_element(By.CLASS_NAME, "select2-search__field")
                input_element.send_keys(year_to)
                input_element.send_keys(Keys.ENTER)
                time.sleep(10)

        self.driver.find_elements(By.CLASS_NAME, "lever")[2].click()
        search_button = self.driver.find_element(By.ID, "search-btn")
        if search_button:
            search_button.click()
        time.sleep(10)


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
        print(search_url)
        self.driver.get(search_url)
        time.sleep(20)
        WebDriverWait(self.driver, 10)

AutoAmScrapper()


params = {
            "category":"1",
            "page":"1",
            "sort":"latest",
            "layout":"list",
            "user":{"dealer":"0","official":"0","id":""},
            "make":[246],"year":{"gt":"1911","lt":"2024"},
            "usdprice":{"gt":"0","lt":"100000000"},
            "mileage":{"gt":"10","lt":"1000000"}
        }