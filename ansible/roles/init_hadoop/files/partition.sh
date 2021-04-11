#!/bin/bash
# 做过分区的就会有/hadoop，grep 到后就退出执行脚本
df -h|grep '/hadoop' && exit 1
# 若没有grep到则进行分区
yum install parted kmod-xfs xfsprogs -y
# 抓出未分区盘号
#/dev/sdb
#/dev/sdd
#/dev/sde
#/dev/sdf
#/dev/sdc
#/dev/sdg
#/dev/sdh
#/dev/sdi
#/dev/sdj
#/dev/sdk
#/dev/sdl
#/dev/sdm
#disk_num=`fdisk -l | awk '$1=="Disk"&&$2~"^/dev"&&$2!~"^/dev/sda" {split($2,s,":"); print s[1]}'`
disk_num=`fdisk -l | awk '$1=="Disk"&&$2~"^/dev"&&$2!~"^/dev/sda"&&$2!~"^/dev/mapper" {split($2,s,":"); print s[1]}'`
NUM=0
for i in $disk_num
do
        # parted是比fdisk更高级的分区工具
        # 1、非交互模式，创建gpt分区表 parted  -s /dev/sdm mklabel gpt
        parted  -s $i mklabel gpt
        # 2、创建分区，分区名：主分区 开始位置 结束位置：100%表示使用剩下的全部空间  parted  -s /dev/sdm mkpart primary 1 100%
        parted  -s $i mkpart primary 1 100%
        # 3、格式化磁盘将新建分区文件系统设为系统所需格式 mkfs.xfs -f /dev/sdm1
        mkfs.xfs -f ${i}1

        if [ $NUM -eq 0 ];then
                TMP=""
        else
                TMP=$NUM
        fi
        # 4、新建挂载点 mkdir /hadoop
        mkdir /hadoop${TMP}
        # 5、将分区挂载到挂载点 mount -o noatime,nodiratime /dev/sdm1 /hadoop11
        mount -o noatime,nodiratime ${i}1 /hadoop${TMP}
        # 6、开机自动挂载，查询磁盘分区UUID
        uuid=`blkid ${i}1 |awk '{print $2}' |sed s#\"##g`
        # 7、将UUID信息写入/etc/fstab
        echo "$uuid     /hadoop${TMP}   xfs     noatime,nodiratime 0       0">>/etc/fstab
        ((NUM++))
done

# https://www.cnblogs.com/stulzq/p/7610100.html