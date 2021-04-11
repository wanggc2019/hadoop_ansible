#!/bin/bash
cat /etc/ansible/roles/init_hadoop/tests/inventory | while read $line
do
  cat /tmp/${line}/home/hadoop/.ssh/id_rsa.pub >> /tmp/authorized_keys
done