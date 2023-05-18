#!/bin/bash

if [ $# -eq 0 ]; then

  printf "Usage: $(basename $0) hostname:port\n"
    printf "example: $(basename $0) www.google.com:443\n"
    exit

elif [ $# -ne 0 ]; then
    checkval=`echo $1 | awk -F: '{print $2}'`

    if [ -z "$checkval" ];then
        #stick in port 443 if no port was provided
        hostport=$1:443
    else
        hostport=$1
    fi
    DELAY=1
    ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

    echo getting cipher list from $(openssl version).

    for cipher in ${ciphers[@]}
    do
        echo -n Testing $cipher...
        result=$(echo -n | openssl s_client -cipher "$cipher" -connect $hostport 2>&1)
        if [[ "$result" =~ ":error:" ]] ; then
            error=$(echo -n $result | cut -d':' -f6)
            echo NO \($error\)
        else
            if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ]] ; then
                echo YES
            else
                echo UNKNOWN RESPONSE
                echo $result
            fi
        fi
        sleep $DELAY
    done
fi
