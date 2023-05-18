#!/bin/bash
#
# To help find Cisco AnyConnect users and log them off
# requires you have grepcidr installed
# create a file with one machine name on each line
# Usage: vpnkick <FILENAME> | sort
# I like to pipe the output to sort to get a sorted list
#
if [ $# -eq 0 ]; then

    printf "Usage: `basename $0` FILENAME\n"
    exit
fi

while read line; do
    echo -e show vpn-sessiondb anyconnect filter name "$line"
    echo -e vpn-sessiondb logoff name "$line" noconfirm
    echo -e $line | awk '{print "dig +noall +answer "$1}' | sh | grepcidr 172.16.128.0/22,172.19.240.0/22 | awk '{print $5}' | sort | awk '{print "show vpn-sessiondb anyconnect filter a-ipaddress "$1"\nvpn-sessiondb logoff ipaddress "$1" noconfirm"}'
done < "$1"
exit 0
