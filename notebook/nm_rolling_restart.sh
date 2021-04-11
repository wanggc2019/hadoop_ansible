#!/bin/bash
source /home/hadoop/.bash_profile
for SERVER in `cat /data/apache/scripts/host.info`
  do
    ssh hadoop@$SERVER "/data/apache/hadoop/bin/yarn --daemon stop nodemanager;sleep 2;/data/apache/hadoop/bin/yarn --daemon start nodemanager"
    echo $SERVER
    sleep 5
  done
