from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException
from selenium.common.exceptions import ElementClickInterceptedException
from selenium.common.exceptions import StaleElementReferenceException
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import Select
from bs4 import BeautifulSoup
import requests, time, os, logging, csv, sys
import pandas as pd

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("debug.log"),
        logging.StreamHandler(sys.stdout)
    ]
)


class TaxCalculator:

    def __init__(self, main_url = "https://www.petekamutner.am/csOS_VehiclesCVC.aspx") -> None:
        chrome_service = webdriver.chrome.service.Service(executable_path=ChromeDriverManager().install())
        self.driver = webdriver.Chrome(service=chrome_service)
        self.main_url = main_url
        self.driver.get(self.main_url)
        self.start()
    
    def start(self):
        try:
            df = pd.read_csv(os.path.join("data","filtered_cars.csv")) 
            df["ImportPrice"] = None
            # columns = df.columns
            tabs = WebDriverWait(self.driver, 10).until(EC.presence_of_all_elements_located((By.CLASS_NAME, "rtsLink")))
            tabs[1].click()
            price_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rntbValue"
            shipping_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rntbOtherExpenses"
            volume_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rntbVolume"
            engine_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rcmbEngineType_Input"
            year_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rcmbYearOfProduction"
            month_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rcmbMonthOfProduction_Input"
            day_input_id = "ctl00_cphContent_csOS_VehiclesCVCView_rcmbDayOfProduction"
            month_xpath = "//div[@id='ctl00_cphContent_csOS_VehiclesCVCView_rcmbMonthOfProduction_DropDown']//ul[@class='rcbList']/li[7]"
            engine_xpath = "//div[@id='ctl00_cphContent_csOS_VehiclesCVCView_rcmbEngineType_DropDown']//ul[@class='rcbList']/li[1]"        
            price_input = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, price_input_id)))
            shipping_input = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, shipping_input_id)))
            volume_input = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, volume_input_id)))
            day_input = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, day_input_id)))
            price_id = "cphContent_csOS_VehiclesCVCView_lblCustomsTotalDuty"
            shipping_input.clear()
            shipping_input.send_keys(3000)
            time.sleep(2)
            WebDriverWait(self.driver, 10).until(EC.element_to_be_clickable((By.ID, month_input_id))).click()
            time.sleep(2)
            WebDriverWait(self.driver,10).until(EC.element_to_be_clickable((By.XPATH, month_xpath))).click()
            time.sleep(2)
            day_input.clear()
            day_input.send_keys(10)
            WebDriverWait(self.driver,10).until(EC.element_to_be_clickable((By.ID, engine_input_id))).click()
            time.sleep(2)
            WebDriverWait(self.driver,10).until(EC.element_to_be_clickable((By.XPATH, engine_xpath))).click()
            
            for index, row in df.iterrows():
                year = row["Year"]
                price = (int(row["Price"]) * 0.9) * 1.15
                engine = int(float(row["Engine"]) * 1000)
                price_input.clear()
                price_input.send_keys(price)
                WebDriverWait(self.driver, 10).until(EC.element_to_be_clickable((By.ID, year_input_id))).click()
                time.sleep(2)
                WebDriverWait(self.driver,10).until(EC.element_to_be_clickable((By.XPATH, f"//ul/li[contains(text(), '{year}')]"))).click()
                time.sleep(2)
                volume_input.clear()
                volume_input.send_keys(engine)
                volume_input.send_keys(Keys.ENTER)
                tax_price = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, price_id))).get_attribute("textContent")
                tax_price = int(int(tax_price.replace(",",""))/390)
                df.loc[index, 'ImportPrice'] = tax_price
                df.loc[[index], ].to_csv("filtered_with_import.csv",header = not os.path.exists("filtered_with_import.csv"), index = False, mode = "a")
        except Exception as e:
            print(str(e))
            df.to_csv("filtered_cars_with_import.csv")



TaxCalculator()