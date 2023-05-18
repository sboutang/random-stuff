#!/usr/bin/env python3
import argparse
import csv
parser = argparse.ArgumentParser(description='aci naming format')
parser.add_argument('input_file', type=str, help='csv input file')
args = parser.parse_args()
namelist = []

def read_input():
    with open(args.input_file, newline='') as csvfile:
        data = list(csv.reader(csvfile))
        for row in data:
            environment = row[0]
            vlanid = row[1]
            netname = row[2]
            subnet = row[3]
            (basesubnet, cidr) = subnet.split('/')
            namelist.append({"environment": environment, "vlanid": vlanid, "netname": netname, "basesubnet": basesubnet, "cidr": cidr})

def bd_names(namelist):
    for index in namelist:
        print("VLAN-%s-%s_%s_%s-%s" % (index['vlanid'], index['environment'], index['netname'], index['basesubnet'], index['cidr']))

def epg_names(namelist):
    for index in namelist:
        print("%s-%s-VL-%s-%s_%s" % (index['basesubnet'], index['cidr'], index['vlanid'], index['environment'], index['netname']))

def contract_names(namelist):
    for index in namelist:
        print("%s-VLAN-%s" % (index['environment'], index['vlanid']))

def main():
    print("create new bridge domains")
    print("----------------------------")
    read_input()
    bd_names(namelist)
    print()
    print("create new EPGs")
    print("----------------------------")
    epg_names(namelist)
    print()
    print("create new contracts")
    print("----------------------------")
    contract_names(namelist)

if __name__ == "__main__":
    main()
