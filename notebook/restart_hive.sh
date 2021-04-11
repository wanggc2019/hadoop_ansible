#!/bin/bash
ip=$(/sbin/ip addr|grep -oP '10(\.\d{1,3}){3}'|head -1)
# restart hms
pid=`ps -ef 2>/dev/null | grep -v "grep" | grep "HiveMetaStore" | awk '{print $2}'`
ppid=`netstat -nltp 2>/dev/null | grep "9083" | awk '{print $7}' | cut -d '/' -f 1`
if [ $pid == $ppid ]
then
  kill $pid
  sleep 2
  nohup /data/apache/hive/bin/hive --service metastore &> /data/apache/hive/logs/metastore.log &
  sleep 3
  success=`ps -ef 2>/dev/null | grep -v "grep" | grep "HiveMetaStore" | awk '{print $2}'`
  if [ $success ]
  then
    echo `date '+%Y-%m-%d %H:%M:%S'` "$ip:HiveMetaStore restart success."
  fi
else
  echo "Can not restart hms,please check process!"
fi
# restart hs2
pidd=`ps -ef 2>/dev/null | grep -v "grep" | grep HiveServer2 | awk '{print $2}'`
ppidd=`netstat -nltp 2>/dev/null | grep "10000" | awk '{print $7}' | cut -d '/' -f 1`
if [ $pidd == $ppidd ]
then
  kill $pidd
  sleep 2
  nohup /data/apache/hive/bin/hive --service hiveserver2 &> /data/apache/hive/logs/hiveserver2.log &
  sleep 3
  success=`ps -ef 2>/dev/null | grep -v "grep" | grep HiveServer2 | awk '{print $2}'`
  if [ $success ]
  then
    echo `date '+%Y-%m-%d %H:%M:%S'` "$ip:HiveServer2 restart success."
  fi    
else
  echo "Can not restart hs2,please check process!"
fi
