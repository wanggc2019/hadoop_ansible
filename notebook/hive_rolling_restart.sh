#!/bin/bash
source /home/hadoop/.bash_profile
for SERVER in `cat /data/apache/scripts/hive_host_all.info`
  do
    ssh hadoop@$SERVER "sh /data/apache/scripts/restart_hive.sh"
    sleep 1
  done
