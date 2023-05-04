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


class AutoAmScrapper:

    def __init__(self, main_url = "https://auto.am/lang/en") -> None:
        chrome_service = webdriver.chrome.service.Service(executable_path=ChromeDriverManager().install())
        self.driver = webdriver.Chrome(service=chrome_service)
        self.main_url = main_url
        self.driver.get(self.main_url)
        self.start()
    
    def start(self):
        self.columns = ["OfferId","Mileage","Version","BodyStyle","Gearbox","HandDrive","Engine",
                        "Color","InteriorColor","EngineVolume","Horsepower","Drivetrain","DoorCount",
                        "Wheels","EngineCylinders","Name","Price","Make","Model"]
        write_headers = False
        if not os.path.exists("cars_armenia.csv"):
             write_headers = True
        with open("./cars_armenia.csv", 'a+', newline='') as f:
            self.writer = csv.writer(f)
            if write_headers:
                self.writer.writerow(self.columns)
        self.search_cars()

    def search_cars(self):
        us_cars = pd.read_csv(os.path.join("data","car_models.csv"))
        for _, row in us_cars.iterrows():
            self.make = row['Make']
            self.model = row['Model.Group']
            logging.info(f"Fetching data for {self.make} {self.model}")
            self.search_cars_by_make()
            header = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, "header-logo")))
            header.click()

    def filter_years_and_tax(self):
        select_elements = WebDriverWait(self.driver, 10).until(EC.presence_of_all_elements_located((By.CLASS_NAME, "select2-selection__rendered")))
        year = 2016
        for i in range(2,4):
            select_element = select_elements[i]
            select_element.click()
            input_element = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "select2-search__field")))
            input_element.send_keys(year)
            input_element.send_keys(Keys.ENTER)
            year = year + 2
        search_options = WebDriverWait(self.driver, 10).until(EC.presence_of_all_elements_located((By.CLASS_NAME, "lever")))
        search_options[2].click()


    def search_cars_by_make(self):
        make_found = self.filter_attribute(self.make,"select2-filter-make-container","select2-search__field","select2-results__option")
        if make_found:
            model_found = self.filter_attribute(self.model,"select2-v-model-container","select2-search__field","select2-results__option")
            if model_found:
                try:
                    self.filter_years_and_tax()
                    search_button = self.driver.find_element(By.ID, "search-btn")
                    search_button.click()
                    self.get_model_data()
                except (NoSuchElementException, ElementClickInterceptedException):
                    logging.info("No results were found")
                except Exception as e:
                    logging.error(str(e))
                    raise e
            else:
                logging.info(f"Unable to find data for {self.make} {self.model}")
                with open("./missing_models.csv", "a+") as f:
                    missing_models_writer = csv.writer(f)
                    missing_models_writer.writerow([self.make, self.model])

    def get_car_details(self, link, price):
        self.offer_id = link.replace("https://auto.am/offer/","")
        page = requests.get("https://auto.am/lang/en", headers={"referer":link})
        soup = BeautifulSoup(page.content, 'html.parser')
        table = soup.find('table', class_='pad-top-6 ad-det')
        name = soup.find("title")
        row = dict.fromkeys(self.columns)
        if table:
            for tr in table.tbody.find_all("tr"):
                table_values = tr.find_all("td")
                for i in range(0, len(table_values) - 1):
                    column = table_values[i].text.strip().replace(" ", "")
                    value = table_values[i + 1].text.strip().replace(" ", "")
                    row[column] = value
            row["Name"] = name.text.strip().replace(" - Auto.am", "")
            row["Price"] = price
            row["Model"] = self.model
            row["Make"] = self.make
            row["OfferId"] = self.offer_id
            with open("./cars_armenia.csv", 'a+', newline='') as f:
                writer = csv.DictWriter(f,fieldnames=self.columns)
                writer.writerow(row)
    
    def get_offer_links(self):
        offers_xpath = "//div[@id='search-result']//div[contains(@id, 'ad')]"
        # prices_xpath = "//div[@id='search-result']//div[@class='card-action']//div[@class='price bold blue-text']"
        offers_elements = WebDriverWait(self.driver, 10).until(EC.presence_of_all_elements_located((By.XPATH, offers_xpath)))
        already_visited_links = []
        for offer_element in offers_elements:
            div_id = offer_element.get_attribute("id")
            link = offer_element.find_element(By.XPATH, f"//div[@id='{div_id}']//div[@class='card-content']//a[@href]").get_attribute("href")
            if link not in already_visited_links:
                price = offer_element.find_element(By.XPATH, f"//div[@id='{div_id}']//div[@class='card-action']//div[@class='price bold blue-text']").text
                already_visited_links.append(link)
                logging.info(f"The link {link} and the price {price}")
                self.get_car_details(link, price)
        self.page = self.page + 1
        next_page_element = self.driver.find_element(By.LINK_TEXT, str(self.page))
        next_page_element.click()

    def get_model_data(self):
        all_pages_viewed = False
        self.page = 1
        while not all_pages_viewed:
            try:
                self.get_offer_links()
            except StaleElementReferenceException:
                logging.info("StaleElementReference retrying !")
                time.sleep(3)
                self.get_offer_links()
            except NoSuchElementException:
                logging.info("All pages viewed")
                all_pages_viewed = True
                continue
            except TimeoutException:
                logging.info("No results were found")
                all_pages_viewed = True
                continue
            except Exception as e:
                logging.info(f"Exception occured while fetching {self.make} {self.model} {self.offer_id} at page {self.page}")
                logging.error(str(e))
                raise e

    def filter_attribute(self,attribute,select_id,input_id,results_cls):
        try:        
            select_element = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.ID, select_id)))
            select_element.click()
            input_element = WebDriverWait(self.driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, input_id)))
            input_element.send_keys(attribute)
            resulted_elements = WebDriverWait(self.driver, 10).until(EC.presence_of_all_elements_located((By.CLASS_NAME, results_cls)))
            if resulted_elements[0].text.lower() == "no results found":
                return False
            input_element.send_keys(Keys.ENTER)
            return True
        except TimeoutException:
            return False


AutoAmScrapper()
