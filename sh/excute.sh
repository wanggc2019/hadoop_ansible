#!/bin/bash

source /home/hadoop/.bash_profile


 for SERVER in `cat /var/soft/sh/host.info`
    do
       ssh -p 57522 hadoop@$SERVER $1
       echo $SERVER
    done
