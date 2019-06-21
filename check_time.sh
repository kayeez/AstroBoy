#!/bin/bash
currDir=`dirname $0`
keyword=`head -1 $currDir/hostname-keyword`
echo "keyword:$keyword"
if [ $? == 1 ];then
  echo 'find $currDir/hostname-keyword file error!'
  exit 1
fi
hs=`grep ${keyword} /etc/hosts |awk '{ print $2 }' `
echo "checking timing sync..."
echo "$hs"
echo '*********各个节点的服务器时间******************'
for s in $hs
do 
 ssh $s 'hostname && date'
done 
echo '**********各个节点的时间同步状态*****************'
for s in $hs
do
  ssh $s 'hostname && /usr/sbin/ntpq -p'
done
echo '**********各个节点的时间同步状态*****************'
for s in $hs
do
  ssh $s 'hostname && /usr/bin/ntpstat'
done

