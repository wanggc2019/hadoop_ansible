#!/bin/bash
export HADOOP_USER_NAME=hbase
cat hbase_tbl.list | while read line
do
echo "snapshot  '$line', 'snap-$line',{SKIP_FLUSH => true}" | hbase shell
/opt/cloudera/parcels/CDH/lib/hbase/bin/hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot \
 -snapshot snap-$line \
 -copy-to hdfs://10.90.48.128:8020/hbase/ \
 -mappers 200 \
 -bandwidth 400
done