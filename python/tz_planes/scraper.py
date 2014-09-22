# -*- coding: utf-8 -*-

import json
import datetime
import turbotlib
import requests
import re
from bs4 import BeautifulSoup


turbotlib.log("Starting run...")  # Optional debug logging

HOST = "http://www.tcaa.go.tz/"
TARGET = "aircraft_register.php"

def clean_up(string):
    return re.sub(' +', ' ', string.replace('\r\n', ' ')).strip()

def parse_table(url):
    turbotlib.log("Parse " + url)

    # Load the page
    doc = BeautifulSoup(requests.get(HOST + url).content)
    
    # Find the right table for the data and the one for the links
    target_main = None
    for main in doc.find_all('td', class_='maincontent'):
        if len(main.find_all('table')):
            target_main = main
    target_tables = target_main.find_all('table')
    target_table = target_tables[0]
    links_table = target_tables[1]
    
    # Parse the data, skip header and footer
    for tr in target_table.find_all('tr')[1:-3]:
        tds = tr.find_all('td')
        record = {
            'Reg_and_C_of_R_Number': clean_up(tds[0].text),
            'Date_of_Issue_of_C_of_R': clean_up(tds[1].text),
            'Name_of_Owner_and_Address' : clean_up(tds[2].text),
            'type_and_serial_number' : clean_up(tds[2].text),
            'year_of_manufacture' : clean_up(tds[3].text),
            'all_up_mass_LBS_KGSS' : clean_up(tds[4].text),
            'category' : clean_up(tds[5].text),
            'engine_type' : clean_up(tds[6].text),
            'certificate_expiry_date' : clean_up(tds[7].text),
            'sample_date': datetime.datetime.now().isoformat(),
            'source_url': TARGET      
        }
        print (json.dumps(record))

    # Find links
    for td in links_table.find_all('td'):
        if clean_up(td.text) == 'Next':
            next_page = td.find('a', href=True)['href']
            parse_table(next_page)
     
     
parse_table(TARGET)
