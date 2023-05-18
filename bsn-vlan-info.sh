#!/bin/bash
command -v curl >/dev/null 2>&1 || { echo >&2 "I require curl but it's not installed.  Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "I require jq but it's not installed.  Aborting."; exit 1; }

if [ $# -lt 2 ]; then

  printf "Usage: $(basename $0) [OPTION] <VLAN_ID>\n"
  printf "[OPTION] -lab (API call on lab controller)\n"
  printf "[OPTION] -dc01 (API call on dc01 controller)\n"
  printf "[OPTION] -dc02 (API call on dc02 controller)\n"
  printf "example: $(basename $0) -lab 123\n"
  exit

elif [ $# -eq 2 ]; then
  bcf_ctrl=$1
  vlan_id=$2

    if [ $bcf_ctrl = "-lab" ]; then
      base_url="mn-pcclab-pnet-ctlr:8443"

    elif [ $bcf_ctrl = "-dc01" ]; then
      base_url="dc01-bcf-ctrl:8443"

    elif [ $bcf_ctrl = "-dc02" ]; then
      base_url="dc02-bcf-ctrl:8443"

    elif [ $bcf_ctrl != "-dc01|-lab|-dc02" ]; then
      printf "Use one of the correct options below\n"
      printf "Usage: $(basename $0) [OPTION] <VLAN_ID>\n"
      printf "[OPTION] -lab (API call on lab controller)\n"
      printf "[OPTION] -dc01 (API call on dc01 controller)\n"
      printf "[OPTION] -dc02 (API call on dc02 controller)\n"
      printf "example: $(basename $0) -lab 123\n"
      exit
    fi

  if [[ $vlan_id =~ ^[[:digit:]] ]]; then
    segment_name=vlan$2
      else
        segment_name=$2
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

session_cookie="$(get_cookie)"

if [ $session_cookie = ERROR ]; then
  printf "Couldn't get a session cookie, check username/password"
  exit
  else
    tenant=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET https://${base_url}'/api/v1/data/controller/applications/bcf/info/endpoint-manager/segment[name="'${segment_name}'"]' | jq '.[].tenant')
fi

if [[ "$tenant" == "" ]]; then
  echo "segment: '${segment_name}' does not exist in any tenant on this fabric"
  kill_session
  exit
  else
    interface_group_members=$(curl -s -g --insecure -H "Cookie:session_cookie=${session_cookie}" -X GET https://${base_url}'/api/v1/data/controller/applications/bcf/tenant[name='${tenant}'][segment/name="'${segment_name}'"]?select=segment[name="'${segment_name}'"]' | jq -jr '.[].segment[]."interface-group-membership-rule"[]? | "\(."interface-group")", " ",("\(.vlan)" | sub("-1"; "untagged")), "\n"')

    printf "segment: $segment_name\n"
    printf "  tenant: $tenant\n"
    printf "  interface_group_members:\n"
    IFS=$'\n'
    for y in $interface_group_members
    do
      printf "    $y"
      printf "\n"
    done

    kill_session
fi
