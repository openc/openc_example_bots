import requests
import json
from lxml import html

URL = "http://www.nbe.gov.et/financial/banks.html"
FIELDS = {
    'Telephone:': 'telephone',
    'Fax:': 'fax',
    'Address:': 'address',
    'Email:': 'email',
    'Swift Code:': 'swift_code',
    'Web Site:': 'web_site',
    'P.O.Box:': 'po_box',
    'Established Date:': 'established_date',
    'Number of Branches:': 'number_branches'
}


def emit(record):
    if len(record):
        print json.dumps(record)


def scrape():
    res = requests.get(URL)
    doc = html.fromstring(res.content)

    record = {}
    expect_value = None
    
    for a in doc.findall('.//a'):
        text = a.xpath('string()').strip()
        if a.get('class') == 'nbe':
            emit(record)
            record = {'name': text, 'source_url': URL, 'sample_date': '2014-06-17'}
        elif text in FIELDS:
            expect_value = FIELDS[text]
        elif expect_value is not None:
            record[expect_value] = text
            expect_value = None
        #elif len(text):
        #    print text

    emit(record)



if __name__ == '__main__':
    scrape()
