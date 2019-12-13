#!/bin/bash
startTime=`date +%s`
echo "Start Time ：$(date '+%Y-%m-%d %H:%M:%S')"
currDir=`cd $(dirname $0) && pwd`
doraemonHome=/opt/doraemon
doraemonEnvFile=$doraemonHome/doraemon.env
hadoopTmpDir=/opt/hadoop/tmpDir
hadoopNameNodeDataDir=/opt/hadoop/namenode
hadoopDataNodeDataDir=/opt/hadoop/datanode
hdfsMaster=node1
yarnMaster=node2
hiveMetastoreNode=node3
for i in `echo $hadoopNameNodeDataDir |awk -F ',' '{for(i=1;i<=NF;i++){print $i}}'`
do
  $currDir/executeCommandOnEachNode.sh "rm -rf $i && mkdir -p $i && chown -R hadoop:hadoop $i"
done

for i in `echo $hadoopDataNodeDataDir |awk -F ',' '{for(i=1;i<=NF;i++){print $i}}'`
do
  $currDir/executeCommandOnEachNode.sh "rm -rf $i && mkdir -p $i && chown -R hadoop:hadoop $i"
done

$currDir/executeCommandOnEachNode.sh "rm -rf $hadoopTmpDir && mkdir -p $hadoopTmpDir && chown -R hadoop:hadoop $hadoopTmpDir"
$currDir/executeCommandOnEachNode.sh "rm -rf $doraemonHome && mkdir  -p $doraemonHome"
$currDir/executeCommandOnEachNode.sh "sed -i \"/doraemon.env/d\" /etc/profile && sed -i \"/doraemon.env/d\" /home/hadoop/.bash_profile"
packageKeyWordArr=(hadoop hive hbase kafka zookeeper)
pkgCheckSuccess=1
for((i=0;i<${#packageKeyWordArr[@]};i++))
do
    pkg=${packageKeyWordArr[$i]}
    pkgCount=`ls $currDir/res |grep $pkg |wc -l`
    if  [ "0" == "$pkgCount" ]
    then
       echo "error: $pkg package not found!"
       pkgCheckSuccess=0
    elif [ "1" -lt "$pkgCount" ]
    then
       echo "error: duplicated $pkg package found!"
       pkgCheckSuccess=0
    else
       echo "$pkg pakcage ${currDir}/res/`ls ${currDir}/res |grep $pkg`"
    fi
done
if [ "0" == "$pkgCheckSuccess" ]
then
  exit 1
fi
rm -rf $doraemonHome && mkdir $doraemonHome && rm -f $doraemonEnvFile
echo 'export JAVA_HOME=/usr/java/defalut' >>  $doraemonEnvFile
pathEnv="\$JAVA_HOME/bin"
for((i=0;i<${#packageKeyWordArr[@]};i++))
do
    pkg=${packageKeyWordArr[$i]}
    pkgPath="${currDir}/res/`ls ${currDir}/res |grep $pkg`"
    echo "unpacking: tar -zxf $pkgPath -C $doraemonHome"
    tar -zxf $pkgPath -C $doraemonHome
    pkgDirFullName=`ls $doraemonHome|grep $pkg`
    echo "mv $doraemonHome/$pkgDirFullName $doraemonHome/$pkg"
    mv $doraemonHome/$pkgDirFullName $doraemonHome/$pkg
    upperCasePkg=`echo "$pkg" |tr '[a-z]' '[A-Z]'`
    pkgEnv="export ${upperCasePkg}_HOME=$doraemonHome/$pkg"
    echo $pkgEnv
    echo $pkgEnv >> $doraemonEnvFile
    pathEnv="${pathEnv}:\$${upperCasePkg}_HOME/bin"
done
echo $doraemonEnv
echo "export PATH=\$PATH:$pathEnv" >> $doraemonEnvFile
source $doraemonEnvFile
echo 'modify hadoop config file'
cp $HADOOP_HOME/etc/hadoop/core-site.xml $HIVE_HOME/conf/hive-site.xml
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/hdfs-site.xml -f $currDir/conf/hdfs-site.properties
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/core-site.xml -f $currDir/conf/core-site.properties
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/yarn-site.xml -f $currDir/conf/yarn-site.properties
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/mapred-site.xml -f $currDir/conf/mapred-site.properties

sed -i 's/@/=/g' $HADOOP_HOME/etc/hadoop/mapred-site.xml
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/hdfs-site.xml -p dfs.name.dir=$hadoopNameNodeDataDir
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/hdfs-site.xml -p dfs.data.dir=$hadoopDataNodeDataDir
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/core-site.xml -p hadoop.tmp.dir=$hadoopTmpDir
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/core-site.xml -p fs.defaultFS=hdfs://$hdfsMaster:9000
$currDir/propertyUtil -c $HADOOP_HOME/etc/hadoop/yarn-site.xml -p yarn.resourcemanager.hostname=$yarnMaster
sed -i  '/^# export JAVA/c\ export JAVA_HOME=\/usr\/java\/default' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo '' > $HADOOP_HOME/etc/hadoop/slaves
allHostNames=`sed '/^$/d' $currDir/host_file | awk '{print $2}'`
for i in $allHostNames
do
  echo "$i" >> $HADOOP_HOME/etc/hadoop/slaves
done

yum install -y postgresql postgresql-server postgresql-contrib
if [ "0" == "`ls /var/lib/pgsql|wc -l`" ]
then
  postgresql-setup initdb
fi
hiveDbExists=`su postgres -c "psql -c \"\\l\"" |awk -F '|' '{print $1}'|grep hive|wc -l`
if [ "0" == "$hiveDbExists" ]
then
  su postgres -c "psql -c \"create database hive\""
fi
su postgres -c "psql -c \"create user hive with password 'hive'\" && psql -c \"GRANT ALL PRIVILEGES ON DATABASE hive TO hive\""
$currDir/propertyUtil -c $HIVE_HOME/conf/hive-site.xml -f $currDir/conf/hive-site.properties
$currDir/propertyUtil -c $HIVE_HOME/conf/hive-site.xml -p javax.jdo.option.ConnectionURL=jdbc:postgresql://`hostname`:5432/hive
$currDir/propertyUtil -c $HIVE_HOME/conf/hive-site.xml -p hive.metastore.uris=thrift://$hiveMetastoreNode:9083

doraemonTarPath=/opt/doraemon.tar.gz
rm -f $doraemonTarPath && cd $doraemonHome && tar -czf  $doraemonTarPath ./* && $currDir/distributeFilesToNodes.sh $doraemonTarPath $doraemonTarPath
cd $currDir
for i in $allHostNames
do
  if [ "`hostname`" != "$i" ]
  then
    echo "unpacking doraemon ... on node $i"
    ssh $i "tar -zxf $doraemonTarPath -C $doraemonHome"
    echo "unpacking finished!"
  fi
done
$currDir/executeCommandOnEachNode.sh "echo \"source $doraemonEnvFile\" >> /etc/profile && echo  \"source $doraemonEnvFile\" >> /home/hadoop/.bash_profile"

$currDir/executeCommandOnEachNode.sh "chown -R hadoop:hadoop $doraemonHome"
endTime=`date +%s`

echo "End Time:$(date '+%Y-%m-%d %H:%M:%S')"

spend=`expr $endTime - $startTime`
echo "Spend $spend seconds!!!!! DONE!!"
