# -*- coding: utf-8 -*-

import json
import datetime
import turbotlib
import requests
import lxml.html

BASE_URL = "http://license.reg.state.ma.us/public/licque.asp?query=business&color=&board="
SEARCH_URL = "http://license.reg.state.ma.us/public/pubLicRange.asp?profession=%s&busname=_&buscity=&querytype=business"
URL_BASE = "http://license.reg.state.ma.us/public/"

turbotlib.log("Starting run...")

# Start a requests session
s = requests.session()


def get_business_types(url):
    """Gets the available business types in the search form.
    Returns a list"""
    response = s.get(url)
    root = lxml.html.fromstring(response.text)
    options = root.xpath("//select[@name='profession']/option")
    return [option.text.strip() for option in options]


def parse_business_licenses(html):
    root = lxml.html.fromstring(html)
    trs = root.xpath("//table[@id='tableresults']/tbody/tr")
    for tr in trs:
        record = {}
        record['license_board'] = tr[0].text.strip()
        record['license_type'] = tr[1].text.strip()
        record['license_number'] = tr[2][0].text
        record['source_url'] = URL_BASE + tr[2][0].attrib['href']
        try:
            record['business_name'] = tr[3][0].text
        except AttributeError:
            # Business name is empty. This happens if a license
            # is expired
            record['business_name'] = ""
        try:
            record['business_city_state'] = tr[4].text.strip()
        except AttributeError:
            record['business_city_state'] = ""
        record['license_status'] = tr[5].text.strip()
        record['sample_date'] = datetime.datetime.now().isoformat()
        yield record


# Get the business types
business_types = get_business_types(BASE_URL)

for business_type in business_types:
    turbotlib.log("Doing: %s" % business_type)
    response = s.get(SEARCH_URL % business_type.encode('utf-8').replace(" ", "_"))
    items = parse_business_licenses(response.text)
    for item in items:
        print json.dumps(item)
