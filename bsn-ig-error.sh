#!/bin/bash
command -v curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed.  Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }
command -v column >/dev/null 2>&1 || { echo >&2 "I require column but it's not installed.  Aborting."; exit 1; }

if [ $# -lt 1 ]; then

  printf "Usage: $(basename $0) [OPTION] <interface_group_name>\n"
  printf "[OPTION] -lab (API call on lab controller)\n"
  printf "[OPTION] -dc01 (API call on dc01 controller)\n"
  printf "[OPTION] -dc02 (API call on dc02 controller)\n"
  printf "example: $(basename $0) -lab boomer-bond0\n"
  exit

elif [ $# -eq 2 ]; then
  bcf_ctrl=$1
  interface_group_name=$2

    if [ $bcf_ctrl = "-lab" ]; then
      base_url="mn-pcclab-pnet-ctlr:8443"

    elif [ $bcf_ctrl = "-dc01" ]; then
      base_url="dc01-bcf-ctrl:8443"

    elif [ $bcf_ctrl = "-dc02" ]; then
      base_url="dc02-bcf-ctrl:8443"

    elif [ $bcf_ctrl != "-dc01|-lab|-dc02" ]; then
      printf "Use one of the correct options below\n"
      printf "Usage: $(basename $0) [OPTION] <interface_group_name>\n"
      printf "[OPTION] -lab (API call on lab controller)\n"
      printf "[OPTION] -dc01 (API call on dc01 controller)\n"
      printf "[OPTION] -dc02 (API call on dc02 controller)\n"
      printf "example: $(basename $0) -lab boomer-bond0\n"
      exit
    fi
fi


function get_cookie {
# get cookie
  cookie=$(curl -s -g --insecure -H "Content-type: application/json" -d '{"user": "'$BSNUSER'","password": "'$BSNPASS'"}' -X POST https://${base_url}/api/v1/auth/login | jq -r '.session_cookie')

  if [ "$cookie" = "null" ]; then
    cookie_error=$(echo ERROR)
    echo "$cookie_error"
    exit
  else
    echo "$cookie"
  fi
}

function kill_session {
# kill session
  curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X DELETE 'https://'${base_url}'/api/v1/data/controller/core/aaa/session[auth-token="'${session_cookie}'"]'
}

function get_stats {
    IFS=$'\n'
    for y in $members
    do
      ig_name=$(echo ${y} | cut -d" " -f1)
      switch_name=$(echo ${y} | cut -d" " -f2)
      interface_name=$(echo ${y} | cut -d" " -f3)
      dpid=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET 'https://'${base_url}'/api/v1/data/controller/core/switch[name="'${switch_name}'"]?select=dpid' | jq '.[].dpid')
      stats=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET 'https://'${base_url}'/api/v1/data/controller/applications/bcf/info/statistic/interface-counter[interface/name="'${interface_name}'"][switch-dpid='${dpid}']?select=interface[name="'${interface_name}'"]')
      rx_bad_vlan=$(echo $stats | jq '.[].interface[].counter."rx-bad-vlan-packet"')
      rx_crc_error=$(echo $stats | jq '.[].interface[].counter."rx-crc-error"')
      rx_error=$(echo $stats | jq '.[].interface[].counter."rx-error"')
      tx_error=$(echo $stats | jq '.[].interface[].counter."tx-error"')
#      rx_drop=$(echo $stats | jq '.[].interface[].counter."rx-drop"')
#      tx_drop=$(echo $stats | jq '.[].interface[].counter."tx-drop"')

      printf "${ig_name}:\n"
#      columns=$(printf "switch_name |interface_name |rx_bad_vlan_pkt |rx_crc_error |rx_error |tx_error |rx_drop |tx_drop\n${switch_name} |${interface_name} |${rx_bad_vlan} |${rx_crc_error} |${rx_error} |${tx_error} |${rx_drop} |${tx_drop}\n" | column -t)
      columns=$(printf "switch_name |interface_name |rx_bad_vlan_pkt |rx_crc_error |rx_error |tx_error\n${switch_name} |${interface_name} |${rx_bad_vlan} |${rx_crc_error} |${rx_error} |${tx_error}\n" | column -t)
      printf "${columns}\n\n"
    done
}

session_cookie="$(get_cookie)"

if [ $session_cookie = ERROR ]; then
  printf "Couldn't get a session cookie, check username/password"
  exit
  elif [[ $interface_group_name == "?" ]]; then
  ig_list=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET https://${base_url}/api/v1/data/controller/applications/bcf/info/fabric/interface-group/summary | jq -r '.[] | select(.mode!="static-auto-controller-inband") | .name')
  printf "Use one of these interface-group names:\n"
  printf "${ig_list}"
  kill_session
  exit
  elif [[ $interface_group_name == "-all" ]]; then
      allup=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET 'https://'${base_url}'/api/v1/data/controller/applications/bcf/info/fabric/interface-group/summary' | jq -r '.[] | select(.state=="up") | select(.mode!="static-auto-controller-inband") | .name')
    for x in $allup
    do
    members=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET 'https://'${base_url}'/api/v1/data/controller/applications/bcf/info/fabric/interface-group/detail[name="'${x}'"]' | jq -jr '.[].interface | .[]."member-info" | "'${x}'", " ", "\(."switch-name")", " ", "\(."interface-name")", "\n"')

      ig_name=$(echo ${x} | cut -d" " -f1)
      get_stats
  done
      kill_session
      exit
  else
    members=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET 'https://'${base_url}'/api/v1/data/controller/applications/bcf/info/fabric/interface-group/detail[name="'${interface_group_name}'"]' | jq -jr '.[].interface | .[]."member-info" | "'${interface_group_name}'", " ", "\(."switch-name")", " ", "\(."interface-name")", "\n"')

fi

if [[ "$members" == "" ]]; then
  echo "interface_group: ${interface_group_name} does not exist on this fabric"
  ig_list=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET https://${base_url}/api/v1/data/controller/applications/bcf/info/fabric/interface-group/summary | jq -r '.[] | select(.mode!="static-auto-controller-inband") | .name')
  printf "Use one of these interface-group names:\n"
  printf "${ig_list}"
  kill_session
  exit
  else
    get_stats
    kill_session
fi
