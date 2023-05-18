#!/bin/bash

snmpget='/usr/bin/snmpget'
snmpoptions='-OqUv -v2c -c $SNMPCOMMSTRING'
vpnlist='mn111-asa-vpn il-lisle-asa-vpn'

maxsuppoid='1.3.6.1.4.1.9.9.392.1.1.1.0' # Max supportable sessions
curranyconoid='1.3.6.1.4.1.9.9.392.1.3.35.0' # anyconnect
currclientlessoid='1.3.6.1.4.1.9.9.392.1.3.38.0' # clientless
curripsecoid='1.3.6.1.4.1.9.9.392.1.3.26.0' # IPSec
currs2soid='1.3.6.1.4.1.9.9.392.1.3.29.0' # site-to-site
curr5mcpuoid='1.3.6.1.4.1.9.9.109.1.1.1.1.8.3' # 5min CPU
memusedoid='1.3.6.1.4.1.9.9.48.1.1.1.5.1' # memory used
memfreeoid='1.3.6.1.4.1.9.9.48.1.1.1.6.1' # memory free



for x in $vpnlist
do
  output=$( maxsuppvalue=$(${snmpget} ${snmpoptions} ${x} ${maxsuppoid})
    curranyconvalue=$(${snmpget} ${snmpoptions} ${x} ${curranyconoid})
    currclientlessvalue=$(${snmpget} ${snmpoptions} ${x} ${currclientlessoid})
    curripsecvalue=$(${snmpget} ${snmpoptions} ${x} ${curripsecoid})
    currs2svalue=$(${snmpget} ${snmpoptions} ${x} ${currs2soid})
    curr5mcpuvalue=$(${snmpget} ${snmpoptions} ${x} ${curr5mcpuoid})
    memfreevalue=$(${snmpget} ${snmpoptions} ${x} ${memfreeoid})
    memusedvalue=$(${snmpget} ${snmpoptions} ${x} ${memusedoid})
    totalmem=$((memfreevalue + memusedvalue))
    memusedper=$(echo "result = ($memusedvalue / $totalmem) * 100; scale=2; result / 1" | bc -l )
    printf "$maxsuppvalue $curranyconvalue $currclientlessvalue $curripsecvalue $currs2svalue $curr5mcpuvalue $memusedper")


    columns=$(printf "\e[95m\n$x\e[32m\nLicensed-Sessions AnyConnect Clientless IPSec Site-to-Site CPU%%%% Memory-Used%%%%\n$output" | column -t)

    printf "$columns\n\e[0m"
done
