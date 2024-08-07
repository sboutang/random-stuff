#!/bin/bash

if [ $# -eq 0 ]; then
  printf "Usage: $(basename $0) hostname:port\n"
  printf "example: $(basename $0) www.google.com:443\n"
  exit
else
  checkval=$(echo $1 | awk -F: '{print $2}')

  if [ -z "$checkval" ]; then
    hostport=$1:443
    name=$1
  else
    hostport=$1
    name=$(echo $1 | awk -F: '{print $1}')
  fi

  if [ "$2" == "-text" ]; then
    echo | openssl s_client -servername $name -connect $hostport -legacy_renegotiation 2>/dev/null | openssl x509 -text 2>/dev/null
  elif [ "$2" == "-subject" ]; then
    echo | openssl s_client -servername $name -connect $hostport -legacy_renegotiation 2>/dev/null | openssl x509 -noout -subject -ext subjectAltName 2>/dev/null
  else
    echo | openssl s_client -servername $name -connect $hostport -legacy_renegotiation 2>/dev/null | openssl x509 -noout -dates 2>/dev/null
  fi
fi
