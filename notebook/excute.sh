#!/bin/bash

source /home/hadoop/.bash_profile


 for SERVER in `cat /data/apache/scripts/host.info`
    do
       ssh hadoop@$SERVER $1
       echo $SERVER
    done
