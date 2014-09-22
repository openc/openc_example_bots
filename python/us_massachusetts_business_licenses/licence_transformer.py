import sys
import json


while True:
    line = sys.stdin.readline()

    if not line:
        break

    try:
        raw_record = json.loads("line")
    except ValueError:
        continue

    if raw_record['business_name'] != "":
        continue

    licence_record = {
        "company_name": raw_record['business_name'],
        "company_jurisdiction": "United States",
        "source_url": raw_record['source_url'],
        "sample_date": raw_record['sample_date'],
        "licence_number": raw_record['license_number'],
        "jurisdiction_classification": raw_record['license_type'],
        "category": 'Business',
        "confidence": 'HIGH',
        "regulator": "Massachusetts Office of Consumer Affairs and Business Regulation, Licensing board: %s" % raw_record['license_board'],
        "licence_jursidiction": "Massachusetts",
        "status": raw_record['license_status']
    }

    print json.dumps(licence_record)
