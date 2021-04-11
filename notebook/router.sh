#!/bin/bash
source /home/hadoop/.bash_profile
case "$1" in 
 start)
 
   for SERVER in `cat /var/soft/sh/router_host.info`
    do
       ssh -p 57522 hadoop@$SERVER "/var/soft/hadoop-3.3.0/bin/hdfs --daemon start dfsrouter"
       echo $SERVER
    done
    ;;
 stop)
  for SERVER in `cat /var/soft/sh/router_host.info`
    do
       ssh -p 57522 hadoop@$SERVER "/var/soft/hadoop-3.3.0/bin/hdfs --daemon stop dfsrouter"
       echo $SERVER
    done
    ;;

 *)
  echo "usage: $0 [start|stop]"
  ;;
esac
