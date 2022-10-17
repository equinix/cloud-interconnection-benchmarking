#!/bin/bash
 
if [ -z "$1" ]; then
        echo
        echo usage: $0 network-interface
        echo
        echo e.g. $0 eth0
        echo
        exit
fi
 
IF=$1
 
while true
do
        R1N1=`cat /sys/class/net/$1/statistics/rx_bytes`
        T1N1=`cat /sys/class/net/$1/statistics/tx_bytes`
        sleep 1
        R2N1=`cat /sys/class/net/$1/statistics/rx_bytes`
        T2N1=`cat /sys/class/net/$1/statistics/tx_bytes`
        TBPSN1=`expr $T2N1 - $T1N1`
        RBPSN1=`expr $R2N1 - $R1N1`
        TMBPSN1=`expr $TBPSN1 / 1048576`
        RMBPSN1=`expr $RBPSN1 / 1048576`
printf '%19s%27s%4s%11s%4s%10s%4s%11s%4s%11s%4s%11s%4s\n' "`date +%Y-%m-%d\ \%H:%M:%S`" "|$1 (MB/s)|Node1(tx):" "$TMBPSN1" "|TOTAL(tx):" "$TMPSNX" "|Node1(rx):" "$RMBPSN1" "|TOTAL(rx):" "$RMPSNX"
done
