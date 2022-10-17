#!/bin/bash

##############################################################################################
## Author: Ravi Sharma - script created all functionalities
##############################################################################################

# Variables
export ORACLE_HOME=/oracle/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=EQXFC
export PATH=$ORACLE_HOME/bin:$PATH
export SCRIPT_OUT=/tmp
export MAILX=/usr/bin/mailx
dd=`date '+%Y%m%d %T'`

TESTRESULTS=/home/oracle/opc/scripts/oci_installer/recover_scnario/logs/Test_"$1"_"$2".txt
LOGFILE=/home/oracle/opc/scripts/oci_installer/recover_scnario/script_log/Test_"$1"_"$2".log

Ping_time1=`ping -c 10 objectstorage.us-sanjose-1.oraclecloud.com | tail -1| awk '{print $4}' | cut -d '/' -f 2`


# Check arguments
PRG=`basename $0`

# Checking if 2 arguments are passed to the script if not exit
if [ "$#" -ne 2 ]
then
  echo "Insufficient arguments. Usage: $PRG <latency> <loss>"
  echo "Example ${PRG} 0 0 for 0 latency 0 loss"
  exit 1
fi

# Check if rman already running if yes exit
SERVICE="rman"
if pgrep -x "$SERVICE" >/dev/null
then
  echo "$SERVICE process exists....exiting" >> $TESTRESULTS
  exit 1
fi

# Creating logs directory if doesn't exist
if [ ! -d "$HOME/script_log/results" ]; then
  echo " Creating log directory" >> $TESTRESULTS
  mkdir -p $HOME/script_log/results
fi

echo "Starting Test: Ts-Internet-"${1}"-"${2}" " >> $TESTRESULTS
echo "Average ping time before starting is "$Ping_time1"" >> $TESTRESULTS
echo "resetting the previous latency and loss settings" >> $TESTRESULTS

ssh root@wanem "tc qdisc show | tail -2" < /dev/null >> $TESTRESULTS

sleep 5

echo "changing parameters on wanem for this test latency "$1"ms, loss "$2"%" >> $TESTRESULTS
sleep 2
ssh root@wanem "tc qdisc add dev bond1.1003 root netem limit 187500 delay "$1"ms loss "$2"%" < /dev/null
sleep 2
ssh root@wanem "tc qdisc add dev bond1.1060 root netem limit 187500 delay "$1"ms" < /dev/null
sleep 2
ssh root@wanem "tc qdisc show | tail -2" < /dev/null >> $TESTRESULTS

ping_after=`ping -c 10 objectstorage.us-sanjose-1.oraclecloud.com | tail -1| awk '{print $4}' | cut -d '/' -f 2`

echo "Average ping time after setting loss and latency is "$ping_after"" >> $TESTRESULTS

${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba" <<EOF1
DROP TABLESPACE "SOE8" INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;
exit
EOF1


# Function RMAN Recover

rman target / <<EOF
SET AUXILIARY INSTANCE PARAMETER FILE;
set decryption identified by 'provide password';
run{
recover tablespace SOE8 until time "to_date('27-Jun-22 14:39:00','dd-mon-rr hh24:mi:ss')" auxiliary destination '/oracle/auxdest';
}
exit
EOF


# ---------------------------------------------------------------------------------------------------------------------
# Main


sleep 2

${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba" <<EOF2
alter tablespace SOE8 online;
exit
EOF2

# Capturing the exact packet loss
echo "-----------------------Actual Loss from the execution - BEGIN" >> $TESTRESULTS
ssh root@wanem "tc -s qdisc | tail -6"  < /dev/null >> $TESTRESULTS
echo "-----------------------Actual Loss from the execution - END" >> $TESTRESULTS

ssh root@wanem "tc qdisc del dev bond1.1060 root" < /dev/null
sleep 2
ssh root@wanem "tc qdisc del dev bond1.1003 root" < /dev/null
sleep 2

ssh root@wanem "tc qdisc show | tail -2" < /dev/null >> $TESTRESULTS


# sleep 10
sleep 2

echo "sending END backup message to teams channel" >> $TESTRESULTS


# /home/oracle/ravi/teams-chat-post.sh ""$webhook"" "Test" "ff0000"  "Backup Deleted from OCI Bucket"



