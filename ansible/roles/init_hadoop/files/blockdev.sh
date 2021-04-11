#/bin/bash
df -TH |awk '{print $1}'|grep -v Filesystem|grep -v cm_processes|grep -v tmpfs >/tmp/disk.txt
cat /tmp/disk.txt|while read i;do blockdev --setra 32768  $i&& blockdev --getra $i;done
