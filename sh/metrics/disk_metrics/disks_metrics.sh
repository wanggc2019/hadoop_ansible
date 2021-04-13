#!/bin/bash
# get hdfs bad disks ipand nums metrics
pushgateway='10.6.100.160:9091'
jobname=hdfs
# run this shell

#_ip=$(/sbin/ip addr|grep -oP '10(\.\d{1,3}){3}'|head -1)
cd `dirname $0`
_scriptname=$(basename $0)
#hdfs bad disks ip and nums runtime
_tmp=$(echo $_scriptname|sed 's/.sh$/.tmp/')
_log=$(echo $_scriptname|sed 's/.sh$/.log/')
/usr/local/bin/python2.7 /var/soft/sh/metrics/disk_metrics/hdfs_metrics.py >$_tmp 2>$_log


# metrics' data
cat <<EOF | curl --data-binary @- http://$pushgateway/metrics/job/$jobname/instance/10.90.49.222
#Type  apache_hdfs_bad_disks gauge
$(awk -F '[ ]+' '{print "Apache_Bad_DisksIp{Ip=\""$1"\"} "$2}' $_tmp)
EOF

