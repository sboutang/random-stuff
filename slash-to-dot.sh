#!/bin/bash

while IFS="/" read IP S
do
        M=$(( 0xffffffff ^ ((1 << (32-S)) -1) ))
        echo "$IP $(( (M>>24) & 0xff )).$(( (M>>16) & 0xff )).$(( (M>>8) & 0xff )).$(( M & 0xff ))"
done
