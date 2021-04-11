# 一、初步安装
官网 https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-common/ClusterSetup.html
# 1、下载安装介质
# 可以是预编译好的，也可以是源码自己编译
# 2、启动用户
# 用hadoop用户启动所有的组件进程
# 3、解压安装包
tar -zxvf hadoop-3.3.0.tar.gz
# 4、做软连接
ln -s hadoop-3.3.0 hadoop
# 5、修改配置文件
hadoop-env.sh,core-site.xml,hdfs-site.xml,mapred-site.xml
# 6、格式化namenode
hdfs namenode -format
# 如果此时启动star-all.sh脚本，那么一个基础的hadoop集群就起来了，他是由nn和snn组成的，hdf、yarn等均没有高可用
######################################################################################################################


# 二、启用hdfs HA
https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html
# 1、修改配置文件
core-site.xml,hdfs-site.xml
# 2、启动所有的jn
hdfs --daemon start journalnode
# 3、启动格式化过的namenode
hdfs --daemon start namenode
# 4、拷贝格式化的namenode的nn数据复制到另一个新的未格式化的namenode
# 先起动格式化过的nn，然后再未格式化的nn上执行这个命令，该命令会从格式化过的nn上拉取jn数据到本地
hdfs namenode -bootstrapStandby
# 将非ha的namenode转化为ha的namenode，则执行，如果nn是个新节点，这步不需要执行了
#hdfs namenode -initializeSharedEdits  不一定需要执行
# 5、启动该namenode
hdfs --daemon start namenode
# 6、配置自动故障转换zkfc
# 前提 ：zookeeper集群要部署并启动 --建议5节点
# 1）修改配置文件core-site.xml,hdfs-site.xml
# 2）格式化zkfc--创建znode
hdfs zkfc -formatZK
# 3）可以用star-all.sh脚本起动包括zkfc的所有进程，也可以单独起zkfc
hdfs --daemon start zkfc
# 7、启动datandoe，或者用star-all.sh,该脚本也会起动yarn的rm和nm
hdfs --daemon start datanode
# 8、查看namenode的状态
hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2
hdfs haadmin -getAllServiceState
http://10.6.103.34.p9870.ipport.internal.mob.com
http://10.6.103.35.p9870.ipport.internal.mob.com

# 可能用的到的
hdfs haadmin
    [-transitionToActive <serviceId>]
    [-transitionToStandby <serviceId>]
    [-failover [--forcefence] [--forceactive] <serviceId> <serviceId>]
    [-getServiceState <serviceId>]
    [-getAllServiceState]
    [-checkHealth <serviceId>]
    [-help <command>]
# 强制转换为active nn，这是不做fence的
hdfs haadmin -transitionToActive --forcemanual nna
hdfs haadmin -transitionToActive nn1
hadoop namenode -recover

# 联邦后查看nn状态
hdfs haadmin -ns mycluster01 -getAllServiceState


#################################################################################################################
# 三、启用resourcemanager HA
官网 https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html
# 除了下面的这个参数，其他都是一样的,rm1和rm2不能共存
    <property>
        <name>yarn.resourcemanager.ha.id</name>
        <value>rm1</value>
    </property>
# 1、修改yarn-site.xml
# 2、启动resourcemanager
yarn --daemon start resourcemanager
# 3、查看rm状态
yarn rmadmin -getAllServiceState
http://10.6.103.34.p8088.ipport.internal.mob.com
# 4、启动nm
yarn --daemon start nodemanager
# 5、启动jobhistory
mapred --daemon start historyserver   # 新的启动方式
mr-jobhistory-daemon.sh start historyserver   # 老的启动方式
# 除了下面的这个参数，其他都是一样的,/mycluster01和/mycluster02不能共存
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://10-6-103-34-vm-jhdxyjd.mob.local:8485;10-6-103-35-vm-jhdxyjd.mob.local:8485;10-6-103-36-vm-jhdxyjd.mob.local:8485/mycluster01</value>
    </property>


#######################################################################################################################
# 四、启用hdfs联邦--基于RBF
# 联邦是多组nameservice组成，每组nameservice中有多个namenode
# 上面已经配置了一组HA namenode，下面再配置一组nameservice
# 参考 https://juejin.cn/post/6844903743494815758、https://www.jianshu.com/p/c22a0cf63da4
参考华为联邦配置,很有参考价值 https://support.huawei.com/enterprise/zh/doc/EDOC1100094182/57508c66
# 1、修改配置文件 hdfs-rbf-site.xml core-site.xml hdfs-site.xml
# 2、格式化namenode --和ns1一样，只是需要用ns1的cluster id来格式化，这样才能让datanode也注册到第二组ns2
# cluster id 可以在webui上看到
hdfs namenode -format -clusterId CID-f8231223-de33-43b1-bd27-62371bb40b99
# 3、启动该namenode
hdfs --daemon start namenode
# 3、将元数据拷贝到ns2的另一个namenode -- 另一个nn不需要格式化
hdfs namenode -bootstrapStandby
# 4、启动该namenode
hdfs --daemon start namenode
# 5、查看ns2的状态
hdfs haadmin -getServiceState nn3
hdfs haadmin -getServiceState nn4
hdfs haadmin -getAllServiceState
http://10.6.103.36.p9870.ipport.internal.mob.com
http://10.6.103.37.p9870.ipport.internal.mob.com
# 5、启动dfsrouter，每个namenode上都要启动一个
hdfs --daemon start dfsrouter
# 6、查看dfsrouter
http://10.6.103.34.p50071.ipport.internal.mob.com
# 可能用到的命令
Usage: hdfs dfsrouteradmin :
	[-add <source> <nameservice1, nameservice2, ...> <destination> [-readonly] [-faulttolerant] [-order HASH|LOCAL|RANDOM|HASH_ALL|SPACE] -owner <owner> -group <group> -mode <mode>]
	[-update <source> [<nameservice1, nameservice2, ...> <destination>] [-readonly true|false] [-faulttolerant true|false] [-order HASH|LOCAL|RANDOM|HASH_ALL|SPACE] -owner <owner> -group <group> -mode <mode>]
	[-rm <source>]
	[-ls [-d] <path>]
	[-getDestination <path>]
	[-setQuota <path> -nsQuota <nsQuota> -ssQuota <quota in bytes or quota size string>]
	[-setStorageTypeQuota <path> -storageType <storage type> <quota in bytes or quota size string>]
	[-clrQuota <path>]
	[-clrStorageTypeQuota <path>]
	[-safemode enter | leave | get]
	[-nameservice enable | disable <nameservice>]
	[-getDisabledNameservices]
	[-refresh]
	[-refreshRouterArgs <host:ipc_port> <key> [arg1..argn]]
	[-refreshSuperUserGroupsConfiguration]

# 7、添加挂载点
# 1)查看挂载点情况
hdfs dfsrouteradmin -ls
# 2)针对所有的NameService，创建 /<nameservice_name>_root 的挂载点，对应于相应<nameservice_name>的根目录，以便可以在Router中可访问<nameservice_name>中未在Router挂载表中挂载的目录
hdfs dfsrouteradmin -add /mycluster01_root mycluster01 /
hdfs dfsrouteradmin -add /mycluster01_root mycluster02 /
# 3)刷新--这个会自动做，间隔是一分钟，若立刻想看到效果则手动刷新
hdfs dfsrouteradmin -refresh
# 可能用到的
hdfs dfsrouteradmin -add /tmp mycluster01,mycluster02 /tmp  --挂载/tmp目录
hdfs dfsrouteradmin -rm /tmp  --删除挂载点
# 检查router健康状态
http://10.6.103.34.p50071.ipport.internal.mob.com/isActive
# 添加制度的挂载点
hdfs dfsrouteradmin -add /readonly ns1 / -readonly
# 设置mount table权限
# w --add,update,remove mount table
# r --list mount table
# x --未使用
hdfs dfsrouteradmin -add /tmp ns1 /tmp -owner root -group supergroup -mode 0755

# 8、配额管理
hdfs dfsrouteradmin -setQuota /path -nsQuota 100 -ssQuota 1024

###################################################################################################################
# 五、yarn labels
# 1、修改yarn-site.xml
# 2、修改capacity-scheduler.xml
# 3、添加label
# 格式
yarn rmadmin -addToClusterNodeLabels "label_1(exclusive=true/false),label_2(exclusive=true/false)"
yarn rmadmin -addToClusterNodeLabels "wgc(exclusive=true),eda(exclusive=true)"
# 4、查看labels
yarn cluster --list-node-labels
# 5、将node加入label
yarn rmadmin -replaceLabelsOnNode "10-6-103-36-vm-jhdxyjd.mob.local:45454=wgc 10-6-103-37-vm-jhdxyjd.mob.local:45454=wgc 10-6-103-38-vm-jhdxyjd.mob.local:45454=eda 10-6-103-39-vm-jhdxyjd.mob.local:45454=eda" -failOnUnknownNodes
# 6、其他
# 移除label
yarn rmadmin -removeFromClusterNodeLabels "wgc,eda"


###################################################################################################################
# 其他
# RBF架构下如何解析路径
https://www.huaweicloud.com/articles/8bd255fcf2778b4fe227f0e43890d56b.html
# router: 代理客户端请求，并解析挂表(check stat store)找到对应的子集群，转发请求到子集群active的namenode --代理服务
# state store: 存储router状态的服务 --router状态存储

# 查看子集群mycluster01的hdfs目录
hdfs dfs -ls hdfs://mycluster01/
# 查看子集群mycluster02的hdfs目录
hdfs dfs -ls hdfs://mycluster02/


hdfs dfsrouteradmin -add /tmp mycluster01,mycluster02 /tmp -order HASH_ALL

hdfs dfsrouteradmin -getDestination /user/user1/file.txt


# 问题
# 1、hdfs/router webui 文件访问报错Permission denied: user=dr.who, access=READ_EXECUTE, inode="/":hadoop:hadoop:drwx------
# 2、datanode分布问题


#####################################################################################################################
# hive部署
# 要求
mysql -uroot -pWgcqw20210104!?*

# 1、配置环境变量
vim /home/hadoop/.bash_profile
export HIVE_HOME=/data/apache/hive
PATH=$PATH:$HOME/.local/bin:$HOME/bin:$JAVA_HOME/bin:$ZOOKEEPER_HOME/bin:$SCALA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$SPARK_HOME/bin

source /home/hadoop/.bash_profile

# 2、修改hive-site.xml

# 3、建hive目录
mkdir /data/apache/data/tmp/hive    # 本地临时数据
hadoop fs -mkdir /user/hive/warehouse   # 数仓目录
hadoop fs -mkdir /tmp   # 临时目录

# 4、拷贝驱动
scp mysql-connector-java-5.1.49.jar root@10.6.103.34:/data/apache/hive/lib/

# 5、建hive库
mysql -uroot -p
CREATE DATABASE hive;
CREATE USER 'hive' IDENTIFIED BY 'hive';
grant all privileges on *.* to 'hive' identified by 'hive';
flush privileges;

# 6、初始化hive元数据库，执行以下命令hive库下生成一些配置表
schematool -dbType mysql -initSchema

# 将core-site.xml,hdfs-site.xml,hadoop-env.sh,mapred-site.xml,yarn-site.xml拷贝到hive/conf/


# 7、启动hive
# 启动hms
nohup /data/apache/hive/bin/hive --service metastore &> /data/apache/hive/logs/metastore.log &
# 启动hs2
nohup /data/apache/hive/bin/hive --service hiveserver2 &> /data/apache/hive/logs/hiveserver2.log &
# 启动hms报错
Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)V
# 解决,hive3.1.2得guava-19.0.jar包与hadoop的包guava-27.0-jre.jar不一致，将hadoop的拷贝过去
https://issues.apache.org/jira/browse/HIVE-22915
ls -al /data/apache/hive/lib/guava-19.0.jar
ls -al /data/apache/hadoop/share/hadoop/hdfs/lib/guava-27.0-jre.jar
mv /data/apache/hive/lib/guava-19.0.jar /data/apache/hive/lib/guava-19.0.jar.bak
cp /data/apache/hadoop/share/hadoop/hdfs/lib/guava-27.0-jre.jar /data/apache/hive/lib/

# 8、测试
# hive cli

# hs2
beeline -u "jdbc:hive2://10.6.103.34:10000" -n hadoop
beeline -u "jdbc:hive2://10.6.103.36:10000" -n hadoop

# 测试sql报错select count(*) from dws_device_install_status;
Error: Could not find or load main class org.apache.hadoop.mapreduce.v2.app.MRAppMaster
Please check whether your <HADOOP_HOME>/etc/hadoop/mapred-site.xml contains the below configuration:
<property>
<name>yarn.app.mapreduce.am.env</name>
<value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
</property>
<property>
<name>mapreduce.map.env</name>
<value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
</property>
<property>
<name>mapreduce.reduce.env</name>
<value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
</property>

# 还需要配置mapred-site.xml文件，分发配置文件后重启yarn服务，重新进入hive

######################################################################################################
# ranger 部署
# 1、下载
# 2、编译，编译完成后在target目录下生成的tgz包
# 3、安装admin
yum install -y bc  # ranger安装依赖bc
# 1）数据库
vim /data/apache/apache-ranger-2.0.0/ranger-2.0.0-admin/install.properties
SQL_CONNECTOR_JAR=/data/apache/ranger/ranger-2.0.0-admin/mysql-connector-java-5.1.49.jar  # 默认是/usr/share/java
db_root_user=root
db_root_password=Wgcqw20210104!?*
db_host=localhost
db_name=ranger
db_user=ranger
db_password=1lpJHRAJ
rangerAdmin_password=admin123
rangerTagsync_password=admin123
rangerUsersync_password=admin123
keyadmin_password=admin123
#audit_solr_urls=
#audit_solr_user=
#audit_solr_password=
#audit_solr_zookeepers=
policymgr_external_url=http://10.6.103.34:6080
RANGER_PID_DIR_PATH=/data/apache/data/tmp/ranger
unix_user=hadoop
unix_user_pwd=hadoop
unix_group=hadoop

# 2）安装
./setup.sh
# 3)启动
cd ews
./ranger-admin-services.sh  start
ps -ef|grep ranger
netstat -lntp|grep 6080
# 4）登录web
http://10.6.103.34.p6080.ipport.internal.mob.com/
admin/admin123

# 4、安装hdfs插件
tar -zxvf ranger-2.0.0-hdfs-plugin.tar.gz
vim ./ranger-2.0.0-hdfs-plugin/install.properties
POLICY_MGR_URL=http://10.6.103.34:6080
REPOSITORY_NAME=hadoopdev
COMPONENT_INSTALL_DIR_NAME=/data/apache/hadoop
# 启用
./enable-hdfs-plugin.sh
# 重启hadoop
/data/apache/hadoop/sbin/stop-all.sh
/data/apache/hadoop/sbin/start-all.sh
# web
Service Name和REPOSITORY_NAME要一样
Namenode URL:hdfs://10.6.103.34:8020,hdfs://10.6.103.35:8020,hdfs://10.6.103.36:8020,hdfs://10.6.103.37:8020
# 启动namenode报错
2021-01-28 00:02:25,512 INFO org.apache.ranger.authorization.hadoop.config.RangerConfiguration: addResourceIfReadable(ranger-hdfs-audit.xml): resource file is file:/data/apache/hadoop-3.3.0/etc/hadoop/ranger-hdfs-audit.xml
2021-01-28 00:02:25,512 INFO org.apache.ranger.authorization.hadoop.config.RangerConfiguration: addResourceIfReadable(ranger-hdfs-security.xml): resource file is file:/data/apache/hadoop-3.3.0/etc/hadoop/ranger-hdfs-security.xml
2021-01-28 00:02:25,517 ERROR org.apache.hadoop.hdfs.server.namenode.NameNode: Failed to start namenode.
java.lang.NoClassDefFoundError: org/apache/commons/lang/StringUtils
	at org.apache.ranger.plugin.service.RangerBasePlugin.init(RangerBasePlugin.java:193)
	at org.apache.ranger.authorization.hadoop.RangerHdfsPlugin.init(RangerHdfsAuthorizer.java:767)
	at org.apache.ranger.authorization.hadoop.RangerHdfsAuthorizer.start(RangerHdfsAuthorizer.java:100)
	at org.apache.ranger.authorization.hadoop.RangerHdfsAuthorizer.start(RangerHdfsAuthorizer.java:86)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.startCommonServices(FSNamesystem.java:1282)
	at org.apache.hadoop.hdfs.server.namenode.NameNode.startCommonServices(NameNode.java:862)
	at org.apache.hadoop.hdfs.server.namenode.NameNode.initialize(NameNode.java:783)
	at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:1014)
	at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:987)
	at org.apache.hadoop.hdfs.server.namenode.NameNode.createNameNode(NameNode.java:1756)
	at org.apache.hadoop.hdfs.server.namenode.NameNode.main(NameNode.java:1821)
Caused by: java.lang.ClassNotFoundException: org.apache.commons.lang.StringUtils
	at java.lang.ClassLoader.findClass(ClassLoader.java:530)
	at org.apache.ranger.plugin.classloader.RangerPluginClassLoader$MyClassLoader.findClass(RangerPluginClassLoader.java:285)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
	at org.apache.ranger.plugin.classloader.RangerPluginClassLoader.loadClass(RangerPluginClassLoader.java:127)
	... 11 more
# 解决
https://mvnrepository.com/artifact/commons-lang/commons-lang/2.6
scp commons-lang-2.6.jar hadoop@10.6.103.37:/data/apache/hadoop/share/hadoop/common
# 授权
# /tmp的权限都要给

# 5、安装hive插件
vim install.properties
POLICY_MGR_URL=http://10.6.103.34:6080
REPOSITORY_NAME=hivedev
COMPONENT_INSTALL_DIR_NAME=/data/apache/hive
CUSTOM_USER=hadoop
CUSTOM_GROUP=hadoop
# 启用
sudo ./enable-hive-plugin.sh
# 重启hive
nohup /data/apache/hive/bin/hive --service metastore &> /data/apache/hive/logs/metastore.log &
nohup /data/apache/hive/bin/hive --service hiveserver2 &> /data/apache/hive/logs/hiveserver2.log &
# web配置策略
用户 hadoop/hadoop
jdbc:hive2://10.6.103.36:10000
# 授权
# 对库表列授权
ps hive对库授权 hdfs也要对库的路径授权

# 授权模型
common user
能做的
1 可在库下建表 删表 更新数据(alter inser delete等)
2 库的hdfs路径可以查看
不能做的
1 不能删库 删库只能管理员做
# 测试结果
comment user可以删库(空库,非空库管理员也删不掉) --- 不符合要求 看看源码--待完成
wgc库建在mycluster02,用wgc用户在wgc库无法建表 --- ranger在联邦集群中权限控制
# 测试sql
beeline -u "jdbc:hive2://10.6.103.34:10000" -n eda
select count(*) from test.dws_device_install_status;
create table dws_device_install_status_20210128 as select * from test.dws_device_install_status;
create table dws_device_install_status_20210128 as select * from test.dws_device_install_status;

select * from eda.dws_device_install_status_20210128 limit 10;

set mapreduce.job.queuename=root.wgc; ---设置资源队列无效,任务仍会向配置文件中映射的队列提交 eda:eda

# 6、安装yarn插件

##################################################################################################################
# hadoop日志的修改
# 按大小分割和按天分割日志
https://sukbeta.github.io/hadoop-log-segmentation


##################################################################################################################
# 部署spark3
# 1、安装scala
# 配置环境变量
export SCALA_HOME=/data/apache/scala
PATH=$PATH:$HOME/.local/bin:$HOME/bin:$JAVA_HOME/bin:$ZOOKEEPER_HOME/bin:$SCALA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$SPARK_HOME/bin:$SCALA_HOME/bin
source ~/.bash_profile
# 测试
scala
# 2、安装spark
# 1) 配置文件
# spark-defaults.conf spark-env.sh slave
# 2) 将core-site.xml,hdfs-site.xml,hive-env.sh,hive-site.xml拷贝到spark/conf/
# 3) 将jar报上传到hdfs目录
hadoop fs -mkdir -p /spark-jar/jars
hadoop fs -put /data/apache/spark3/jars/* /spark-jar/jars
# 启动
sbin/start-all.sh
# 查看
jps
20982 Master
28366 Worker
# 测试
export HADOOP_USER_NAME=eda;
/data/apache/spark3/bin/spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master yarn \
  --deploy-mode cluster \
  --executor-memory 1G \
  --num-executors 1 \
  /data/apache/spark3/examples/jars/spark-examples_*.jar 10

# 查看yarn任务
yarn top
yarn application -kill application_1528080031923_0067

# 问题1： 长时间running，查看yarn日志：
21/02/20 09:38:12 ERROR YarnAllocator: Failed to launch executor 22 on container container_e24_1611894847967_0014_01_000023
org.apache.spark.SparkException: Exception while starting container container_e24_1611894847967_0014_01_000023 on host 10-6-103-38-vm-jhdxyjd.mob.local
	at org.apache.spark.deploy.yarn.ExecutorRunnable.startContainer(ExecutorRunnable.scala:129)
	at org.apache.spark.deploy.yarn.ExecutorRunnable.run(ExecutorRunnable.scala:68)
	at org.apache.spark.deploy.yarn.YarnAllocator.$anonfun$runAllocatedContainers$4(YarnAllocator.scala:570)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: org.apache.hadoop.yarn.exceptions.InvalidAuxServiceException: The auxService:spark_shuffle does not exist
	at sun.reflect.GeneratedConstructorAccessor33.newInstance(Unknown Source)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.hadoop.yarn.api.records.impl.pb.SerializedExceptionPBImpl.instantiateExceptionImpl(SerializedExceptionPBImpl.java:171)
	at org.apache.hadoop.yarn.api.records.impl.pb.SerializedExceptionPBImpl.instantiateException(SerializedExceptionPBImpl.java:182)
	at org.apache.hadoop.yarn.api.records.impl.pb.SerializedExceptionPBImpl.deSerialize(SerializedExceptionPBImpl.java:106)
	at org.apache.hadoop.yarn.client.api.impl.NMClientImpl.startContainer(NMClientImpl.java:211)
	at org.apache.spark.deploy.yarn.ExecutorRunnable.startContainer(ExecutorRunnable.scala:125)
# 处理：在yarn服务配置添加spark_shuffle等，重启yarn服务
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle,spark_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
        <value>org.apache.spark.network.yarn.YarnShuffleService</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.spark_shuffle.classpath</name>
        <value>/data/apache/spark3/yarn/spark-3.0.1-yarn-shuffle.jar</value>
    </property>

# 问题2：
org.apache.hadoop.yarn.exceptions.YarnRuntimeException: java.lang.ClassNotFoundException: org.apache.spark.network.yarn.YarnShuffleService
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.AuxServices.initAuxService(AuxServices.java:482)
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.AuxServices.serviceInit(AuxServices.java:761)
	at org.apache.hadoop.service.AbstractService.init(AbstractService.java:164)
	at org.apache.hadoop.service.CompositeService.serviceInit(CompositeService.java:109)
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.ContainerManagerImpl.serviceInit(ContainerManagerImpl.java:327)
	at org.apache.hadoop.service.AbstractService.init(AbstractService.java:164)
	at org.apache.hadoop.service.CompositeService.serviceInit(CompositeService.java:109)
	at org.apache.hadoop.yarn.server.nodemanager.NodeManager.serviceInit(NodeManager.java:494)
	at org.apache.hadoop.service.AbstractService.init(AbstractService.java:164)
	at org.apache.hadoop.yarn.server.nodemanager.NodeManager.initAndStartNodeManager(NodeManager.java:962)
	at org.apache.hadoop.yarn.server.nodemanager.NodeManager.main(NodeManager.java:1042)
Caused by: java.lang.ClassNotFoundException: org.apache.spark.network.yarn.YarnShuffleService
	at java.net.URLClassLoader.findClass(URLClassLoader.java:382)
# 处理 缺少jar包 cp /data/apache/spark3/yarn/spark-3.0.1-yarn-shuffle.jar /data/apache/hadoop/share/hadoop/yarn/lib/


################################################################################################################
# 部署flink on yarn
# 1、下载
# https://flink.apache.org/zh/downloads.html
# 2、下载hadoop依赖
# Pre-bundled Hadoop 2.8.3 (asc, sha512) 参考 https://www.cnblogs.com/javazyh/p/12170151.html
# 将hadoop的依赖包放在flink的lib下即可 测试hadoop2.8的依赖可以在hadoop3.0使用，若没有放这个jar则会报错：
Caused by: java.lang.ClassNotFoundException: org.apache.hadoop.yarn.exceptions.YarnException org.apache.hadoop.conf.Configuration
# 3、部署
# 3种模式 application mode、Pre-Job mode、Session mode

export HADOOP_USER_NAME=eda
# 启动一个长期运行的Flink集群，启动一个yarn session，后面所有的flink任务都可提交到该session
bin/yarn-session.sh -n 8 -jm 1024 -tm 1024 -s 4 -nm FlinkOnYarnSession -d
#-n 指定TaskManager数量
#-jm 指定JobManager使用内存
#-m 指定JobManager地址
#-tm 指定TaskManager使用内存
#-D 指定动态参数
#-d 客户端分离，指定后YarnSession部署到yarn之后，客户端会自行关闭。
#-j 指定执行jar包
#-s,--slots <arg>                Number of slots per TaskManager
#-nm,--name <arg>                Set a custom name for the application on YARN
# 测试
/data/apache/flink/bin/flink run /data/apache/flink/examples/batch/WordCount.jar --input hdfs://mycluster01/user/eda/zoo.cfg

# yarn-cluster模式 即向yarn提交一个app,独立app
/data/apache/flink/bin/flink run -m yarn-cluster /data/apache/flink/examples/batch/WordCount.jar --input hdfs://mycluster01/user/eda/zoo.cfg


bin/flink run-application -t yarn-application \
-Djobmanager.memory.process.size=1024m \
-Dtaskmanager.memory.process.size=2048m \
-Dyarn.provided.lib.dirs="hdfs://mycluster01/user/eda/flink/libs" \
hdfs://mycluster01/user/eda/WordCount.jar


bin/flink run-application -t yarn-application \
-Djobmanager.memory.process.size=1024m \
-Dtaskmanager.memory.process.size=2048m \
/data/apache/flink/examples/batch/WordCount.jar \
--input hdfs://mycluster01/user/eda/zoo.cfg \
--output hdfs://mycluster01/user/eda/result


bin/flink run-application -t yarn-application \
-Djobmanager.memory.process.size=1024m \
-Dtaskmanager.memory.process.size=2048m \
-Dyarn.provided.lib.dirs="hdfs://mycluster01/user/eda/flink/remote-flink-dist-dir/flink" \
hdfs://mycluster01/user/eda/WordCount.jar \
--input hdfs://mycluster01/user/eda/zoo.cfg \
--output hdfs://mycluster01/user/eda/result


bin/flink run examples/streaming/SocketTextStreamWordCount.jar \
  --hostname localhost \
  --port 9000