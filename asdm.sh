#!/bin/bash
# easy asdm launcher

if [ $# -eq 0 ]; then
        read -s -p "Enter IP address: " asaip
else
        asaip=`echo "$1"`
fi

$(javaws https://$asaip/admin/public/asdm.jnlp)
exit 0
