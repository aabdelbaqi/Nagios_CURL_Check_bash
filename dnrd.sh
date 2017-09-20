#!/bin/bash

while getopts 'w:c:hp' OPT; do
  case $OPT in
    w)  warn=$OPTARG;;
    c) crit=$OPTARG;;
    h)  hlp="yes";;
    p)  perform="yes";;
  esac
done

HELP="
    usage: $0 [ -w value -c value -p -h ]

    syntax:

            -w --> Warning integer value
            -c --> Critical integer value
            -p --> print out performance data
            -h --> print this help screen
"

if [ "$hlp" = "yes" -o $# -lt 1 ]; then
  echo "$HELP"
  exit 0
fi
### Set the variables ####
url=https://egovservices.dnrd.ae/dnrdmedservices/GetPersonInfoWithPhotoEx.asmx
header1='Content-Type:text/xml;charset=utf-8'
action='http://tempuri.org/Execute'
value=$(</root/request.xml)


### Run the Curl command with the XML and check time before and after ####
res1=$(date +%s.%N)
curl -s -k -H "$header1" -H "SOAPAction:$action" -d@/root/request.xml $url -o /root/output.txt
res2=$(date +%s.%N)

### Subtracting the time before and after, then convert to days, hours, minutes and seconds #####

dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

#printf  "Total runtime %02d:%02.4f in seconds " $dm $ds
printf -v ds "%0.4f" $ds

if [ "$perform" = "yes" ]; then
  OUTPUTP="Time Taken to request: $ds Seconds | Time="$ds";$warn;$crit;0"
else
  OUTPUT="Time Taken to request: $ds"
fi

#### Check the thresholds ###
if [ -n "$warn" -a -n "$crit" ]; then

  if (($(echo "$ds < $warn" | bc -l ))) ;then
    err=0
  elif (($(echo "$ds > $warn"| bc -l ))) & (($(echo "$ds < $crit" | bc -l))); then
    err=1
  elif (($(echo "$ds > $crit" |bc -l ))); then
    err=2
  fi

  if (( $err == 0 )); then

    if [ "$perform" = "yes" ]; then
      echo  "DNRD OK: $OUTPUTP "
      exit "$err"
    else
      echo  "DNRD OK: $OUTPUT "
      exit "$err"
    fi

  elif (( $err == 1 )); then
    if [ "$perform" = "yes" ]; then
      echo  "DNRD WARNING: $OUTPUTP "
      exit "$err"
    else
      echo  "DNRD WARNING: $OUTOUT "
      exit "$err"
    fi

  elif (( $err == 2 )); then

    if [ "$perform" = "yes" ]; then
      echo "DNRD CRITICAL: $OUTPUTP "
      exit "$err"
    else
      echo "DNRD CRITICAL: $OUTPUT "
      exit "$err"
    fi

  fi

else

  echo  "no output from plugin"
  exit 3

fi
exit
