#!/bin/bash
# make ping behave like solaris ping because I'm old. Also nice for basic scripts and loops
function pinghost {
    ping -c 1 -W 1 $args &> /dev/null
    case $? in
        0)
            echo "$host is alive";
            ;;
        1)
            echo "no answer from $host";
            ;;
        2)
            echo "sping: unknown host $host";
            ;;
    esac
}
if [ -z $1 ]; then
    echo "Usage: sping host"
    echo $(ping 2>&1 | sed -e 's/ping/sping/')
else
    #Get hostname from args (in any order)
    args=$@
    while test -n "$1"
    do
        if [[ "$1" = -* ]]; then
            shift 2
        else
            host="$1"
            break
        fi
        #shift
    done
    pinghost $args
fi
