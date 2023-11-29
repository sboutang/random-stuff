#!/usr/bin/env python3
import googlemaps
from datetime import datetime
import argparse
import airportsdata
import json
import os
import sys
import re

# Script to convert IATA code to physical address
# uses the airportsdata python module https://pypi.org/project/airportsdata/

# uses the googlemaps module to convert (lat, lon) to physical address and grabs the most formatted
# airport address from google

# googlemaps api key from env variable
gmaps = googlemaps.Client(key=os.getenv('GOOGLEMAPSAPI'))
parser = argparse.ArgumentParser(description='Lookup airport IATA code')
parser.add_argument('iata_code', type=str, help='three letter IATA code')
args = parser.parse_args()

def get_google_address(iatacode, lat, lon, tz, region, rawcountry):
    addr_pattern = '.*(\(\w{3}\)|Airport,).*' # match lines with IATA code in () or the word "Airport," seems the best google result
    country_pattern = '.+, (.+$)'
    just_addr_pattern = '^(.*?),\s*(.*)$' # split the description and address
    iata_pattern = '^.*\(\w{3}\).*$'
    site = (lat, lon)
    reverse_geocode_result = gmaps.reverse_geocode(site)
    for line in reverse_geocode_result:
        match_addr = re.search(addr_pattern, line['formatted_address'])
        match_iata = re.search(iata_pattern, line['formatted_address'])
        if match_addr and match_iata:
            matched_address = match_addr.group(0)
            break
        elif match_addr and not match_iata:
            matched_address = match_addr.group(0)

    match_country = re.search(country_pattern, matched_address)
    country = match_country.group(1)
    match_addr = re.search(just_addr_pattern, matched_address)
    addr = match_addr.group(2)
    description = match_addr.group(1)
    country_code = rawcountry
    print_data(iatacode, addr, tz, lat, lon, description, region, country, country_code, rawcountry)

def print_data(iatacode, addr, tz, lat, lon, description, region, country, country_code, rawcountry):
    data = [
        {
            "name": iatacode,
            "region": {
                "name": region
            },
            "description": description,
            "physical_address": addr,
            "country": country,
            "country_code": country_code.upper(),
            #"country_code2": rawcountry,
            "time_zone": tz,
            "latitude": lat,
            "longitude": lon
        }
            ]
    print(json.dumps(data, ensure_ascii=False, indent=2))
    sys.exit(0)


def code_lookup(iata_code):
    airports = airportsdata.load('IATA')
    try:
        name = airports[iata_code.upper()]
    except:
         print("{} not found in IATA codes".format(iata_code.upper()))
         sys.exit(1)

    lat = json.dumps(name['lat'])
    lon = json.dumps(name['lon'])
    pattern = re.compile('(.+\.\d{1,6})')
    matchlat = re.search(pattern, lat)
    matchlon = re.search(pattern, lon)
    shortlon = matchlon.group()
    shortlat = matchlat.group()
    tz = json.dumps(name['tz']).strip('\"')
    rawcountry = json.dumps(name['country']).strip('\"')
    iatacode = iata_code.upper()
    # Not needed for this, but sets a region for use in netbox
    if rawcountry:
        if rawcountry in {'AR', 'BO', 'BR', 'CL', 'CO', 'EC', 'FK', 'GF', 'GY', 'PY', 'PE', 'SR', 'UY','VE'}:
            region = 'SouthAmerica'
        elif rawcountry == 'MX':
            region = 'Mexico'
        elif rawcountry == 'CA':
            region = 'Canada'
        elif rawcountry == 'US':
            region = 'UnitedStates'
        elif rawcountry in {'AI', 'AG', 'AW', 'BS', 'BB', 'BM', 'VG', 'DM', 'GD', 'MS', 'PR', 'KN', 'LC', 'VC', 'TT', 'TC', 'VI', 'CU', 'DO', 'JM', 'KY', 'SX'}:
            region = 'Carribean'
        elif rawcountry in {'BZ', 'CR', 'HN','SV', 'PA', 'GT', 'NI'}:
            region = 'CentralAmerica'
        else:
            region = 'Other-International'
    else:
        region = 'Other-International'
    get_google_address(iatacode, shortlat, shortlon, tz, region, rawcountry)

if __name__ == '__main__':
    code_lookup(args.iata_code)
