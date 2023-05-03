import requests
from bs4 import BeautifulSoup
import pandas as pd


page = requests.get("https://auto.am/lang/en", headers={"referer":"https://auto.am/offer/2847504"})
soup = BeautifulSoup(page.content, 'html.parser')
table = soup.find('table', class_='pad-top-6 ad-det')
rows = []
row = {}
for tr in table.tbody.find_all("tr"):
    table_values = tr.find_all("td")
    for i in range(0, len(table_values) - 1):
        column = table_values[i].text.strip().replace(" ", "")
        value = table_values[i + 1].text.strip().replace(" ", "")
        row[column] = value
rows.append(row)
print(pd.DataFrame(rows))
