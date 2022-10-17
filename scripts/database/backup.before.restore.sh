#!/bin/bash

##############################################################################################
## Author: Ravi Sharma - script created all functionalities
## Troubleshooting : Jaroslaw Zdebik - Added dev/null for wanem commands
## Removed netem from del: Pragnesh
## Added limit: Pragnesh
## Added actual packet loss capture: Pragnesh
## Version: 1.5
## Date: 07/12/2021
## Script  will backup db to oci bucket, send message to teams channel, delete backup and send message
##############################################################################################

# Variables
export ORACLE_HOME=/oracle/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=EQXFC
export PATH=$ORACLE_HOME/bin:$PATH
export SCRIPT_OUT=/tmp
export MAILX=/usr/bin/mailx
dd=`date '+%Y%m%d %T'`

TESTRESULTS=/home/oracle/opc/scripts/oci_installer/automation/version5/logs/Test_"$1"_"$2".txt
LOGFILE=/home/oracle/opc/scripts/oci_installer/automation/version5/script_log/Test_"$1"_"$2".log

Ping_time1=`ping -c 10 objectstorage.us-sanjose-1.oraclecloud.com | tail -1| awk '{print $4}' | cut -d '/' -f 2`

# JJZ commented
# webhook=https://dummywebhook.com

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
ssh root@wanem "tc qdisc add dev bond1.1060 root netem limit 187500 delay "$1"ms loss "$2"%" < /dev/null
sleep 2
ssh root@wanem "tc qdisc add dev bond1.1003 root netem limit 187500 delay "$1"ms" < /dev/null
sleep 2
ssh root@wanem "tc qdisc show | tail -2" < /dev/null >> $TESTRESULTS

ping_after=`ping -c 10 objectstorage.us-sanjose-1.oraclecloud.com | tail -1| awk '{print $4}' | cut -d '/' -f 2`

echo "Average ping time after setting loss and latency is "$ping_after"" >> $TESTRESULTS

# Function Delete Backup
delBackup () {
rman log=/home/oracle/script_log/backup_del.log << EOF
connect target /
DELETE noprompt BACKUP;
exit
EOF
}

# Function RMAN Full Backup
ocibackup () {
rman log=/home/oracle/script_log/fullbkp.log << EOF
connect target /
set echo on;
configure backup optimization on;
configure controlfile autobackup on;
configure maxsetsize to unlimited;

set encryption on identified by "provide password" only;
run {
allocate channel d1 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d2 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d3 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d4 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d5 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d6 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d7 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d8 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d9 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d10 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d11 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d12 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d13 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d14 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d15 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d16 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d17 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d18 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d19 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d20 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d21 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d22 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d23 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d24 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d25 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d26 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d27 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d28 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d29 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d30 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d31 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d32 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d33 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d34 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d35 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d36 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d37 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d38 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d39 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d40 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d41 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d42 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d43 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d44 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d45 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d46 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d47 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d48 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d49 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d50 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d51 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d52 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d53 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d54 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d55 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d56 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d57 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d58 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d59 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d60 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d61 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d62 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d63 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d64 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
allocate channel d65 device type 'SBT_TAPE' PARMS  'SBT_LIBRARY=/oracle/app/oracle/product/19.0.0/dbhome_1/lib/libopc.so,SBT_PARMS=(OPC_PFILE=/oracle/app/oracle/product/19.0.0/dbhome_1/dbs/opcRMANTEST.ora)';
BACKUP current controlfile;
BACKUP AS BACKUPSET SECTION SIZE 1G DATABASE plus archivelog;
release channel d1;
release channel d2;
release channel d3;
release channel d4;
release channel d5;
release channel d6;
release channel d7;
release channel d8;
release channel d9;
release channel d10;
release channel d11;
release channel d12;
release channel d13;
release channel d14;
release channel d15;
release channel d16;
release channel d17;
release channel d18;
release channel d19;
release channel d20;
release channel d21;
release channel d22;
release channel d23;
release channel d24;
release channel d25;
release channel d26;
release channel d27;
release channel d28;
release channel d29;
release channel d30;
release channel d31;
release channel d32;
release channel d33;
release channel d34;
release channel d35;
release channel d36;
release channel d37;
release channel d38;
release channel d39;
release channel d40;
release channel d41;
release channel d42;
release channel d43;
release channel d44;
release channel d45;
release channel d46;
release channel d47;
release channel d48;
release channel d49;
release channel d50;
release channel d51;
release channel d52;
release channel d53;
release channel d54;
release channel d55;
release channel d56;
release channel d57;
release channel d58;
release channel d59;
release channel d60;
release channel d61;
release channel d62;
release channel d63;
release channel d64;
release channel d65;
}
exit
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Main
# Post a message in Teams Chanel for start of Backup
echo "sending start backup message to teams channel" >> $TESTRESULTS
# JJZ
# /home/oracle/ravi/teams-chat-post.sh ""$webhook"" "Start Backup Script" "00ff00"  "Starting OCI Backup"
sleep 5
# JJZ
ocibackup
sleep 10
sleep 2
bkp_size=`oci os bucket get --bucket-name o-sink-pub-bucket-new --fields approximateSize | grep approximate-size`
output=`(sqlplus -s '/ as sysdba' <<EOF1
        set echo off verify off head off feed off pages0;
        select round(elapsed_seconds/60, 1) Mins from V\\$RMAN_BACKUP_JOB_DETAILS  where SESSION_KEY = ( select max(SESSION_KEY) from V\\$RMAN_BACKUP_JOB_DETAILS);
EOF1
)`
echo "Backup Time "$output" and OCI Bucket size after backup is "${bkp_size:: -1}"" >> $TESTRESULTS
echo "sending END backup message to teams channel" >> $TESTRESULTS
# JJZ
# /home/oracle/ravi/teams-chat-post.sh ""$webhook"" "Start Backup Script" "00ff00"  "Backup Completed in "$output" Mins Backup Size "$bkp_size""

########### Delete Backup from OCI
sleep 60
echo "sending start backup delete message to teams channel" >> $TESTRESULTS
# JJZ
# /home/oracle/ravi/teams-chat-post.sh ""$webhook"" "Test" "ff0000"  "Delete Backup Started from OCI"

# Capturing the exact packet loss
echo "-----------------------Actual Loss from the execution - BEGIN" >> $TESTRESULTS
ssh root@wanem "tc -s qdisc | tail -6"  < /dev/null >> $TESTRESULTS
echo "-----------------------Actual Loss from the execution - END" >> $TESTRESULTS

ssh root@wanem "tc qdisc del dev bond1.1060 root" < /dev/null
sleep 2
ssh root@wanem "tc qdisc del dev bond1.1003 root" < /dev/null
sleep 2
# JJZ
ssh root@wanem "tc qdisc show | tail -2" < /dev/null >> $TESTRESULTS

sleep 60
oci os bucket get --bucket-name BACKUP_EQXFC --fields approximateSize --fields approximateCount
# Pragnesh - Added the delete using Object storage cli as its faster and more importantly it does not change the number of objects 
# This helps in keeping the backup size as constant as possible. The other option to not backup archive logs causes the backup to
# be non-restorable. As a result this path was chosen to keep the backup size as consistent as possible.

# DO NOT DELETE the Backup now

# oci os object bulk-delete --namespace axmdl6rzyvt1 --bucket-name BACKUP_EQXFC --prefix file_chunk --force  &> /dev/null
# oci os object bulk-delete --namespace axmdl6rzyvt1 --bucket-name BACKUP_EQXFC --prefix sbt_catalog  --force &> /dev/null

# JJZ
# delBackup


# JJZ
# sleep 10
sleep 2

echo "sending END backup message to teams channel" >> $TESTRESULTS
echo "Put the below date-time in the restore script"
date
# JJZ
# /home/oracle/ravi/teams-chat-post.sh ""$webhook"" "Test" "ff0000"  "Backup Deleted from OCI Bucket"

