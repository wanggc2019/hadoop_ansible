#!/bin/bash
echo $1
echo $2
#cpu_load=$(echo `uptime |awk -F , '{printf $4}'`|awk -F : '{printf $2}'|awk '{print int($0)}')
cpu_load=$(w |head -1 |awk -F "load average:" '{print $2}' |awk -F '.' '{print $1}')
echo "cpu_load average is $cpu_load"
if [ $cpu_load -ge 720 ];then
  echo 'ERROR: Load is over 480'
else
  echo 'NORMAL: Load is less than 480'
fi
