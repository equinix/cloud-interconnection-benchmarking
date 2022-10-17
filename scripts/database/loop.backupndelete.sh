#!/usr/bin/bash
touch benchmark.log
exec 1>> benchmark.log
while IFS=' ' read -r late loss; do
  now=$(date '+%Y-%m-%d %H:%M:%S')
  echo "Time: $now - Running three tests for latency: $late and packet loss: $loss"
  for i in {1..3}
  do
    echo "Inside loop v5.sh $late $loss"
    ./backupndelete.sh $late $loss
  done
done < <(grep "" input.txt)
