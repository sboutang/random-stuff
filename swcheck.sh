#!/bin/bash
if [ $# -lt 1 ]; then

  printf "Usage: $(basename $0) [OPTION]\n"
  printf "[OPTION] lab (API call on lab controller)\n"
  printf "[OPTION] dc01 (API call on dc01 controller)\n"
  printf "[OPTION] dc02 (API call on dc02 controller)\n"
  printf "example: $(basename $0) lab\n"
  exit

elif [ $# -eq 1 ]; then
  bcf_ctrl=$1

    if [ $bcf_ctrl = "lab" ]; then
      base_url="lab"

    elif [ $bcf_ctrl = "dc01" ]; then
      base_url="dc01"

    elif [ $bcf_ctrl = "dc02" ]; then
      base_url="dc02"

    elif [ $bcf_ctrl != "dc01|lab|dc02" ]; then
      printf "Use one of the correct options below\n"
      printf "Usage: $(basename $0) [OPTION]\n"
      printf "[OPTION] lab (API call on lab controller)\n"
      printf "[OPTION] dc01 (API call on dc01 controller)\n"
      printf "[OPTION] dc02 (API call on dc02 controller)\n"
      printf "example: $(basename $0) lab\n"
      exit
    fi
fi

function countdown {
  IFS=:
  set -- $*
  secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo
}

while [ 1 ]; do
  date
  output=$(bsnapi.py ${base_url} /api/v1/data/controller/applications/bcf/info/fabric/switch \
    | jq -j '.[] | "\(.name)", " \(.asic)", " \(."fabric-connection-state")",
    " \(."connected-since" | sub("\\.[0-9]+Z$"; "Z") | fromdate |
      strflocaltime("%Y-%m-%d-%H:%M:%S-%Z"))", " \(."leaf-group")", "\n"' | column -t)
  printf "$output" | sort -k5
  countdown "00:30:00"
  #clear
done
