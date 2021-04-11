#!/bin/bash
 for SERVER in `cat /data/apache/scripts/host.info`
    do
      scp -r $1 $SERVER:$2
      echo $SERVER
    done
