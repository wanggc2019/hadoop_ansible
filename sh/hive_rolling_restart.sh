#!/bin/bash
source /home/hadoop/.bash_profile
for SERVER in `cat /var/soft/sh/hive_host_all.info`
  do
    ssh -p 57522 hadoop@$SERVER "sh /var/soft/sh/restart_hive.sh"
    sleep 1
  done
