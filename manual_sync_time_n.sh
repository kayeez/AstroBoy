#!/bin/bash
#定义函数
function ssh_ntpdate(){
#表示需要同步的hostname
   hn=$1
#表示目标ntp服务器hostname
   aim=$2

#执行时间同步操作
   ssh ${hn} '/usr/sbin/ntpdate -u ${aim}'
   ssh ${hn} 'service ntpd restart'
}
currDir=`dirname $0`
#表示同步的主节点 可以是ip或者hostname
   master=$1
#当前登录用户的用户名
   w=`whoami`
#必须是root用户才能运行这个脚本
if [ $w != 'root' ];then
   echo 'must be root user to run this script!'
   exit 1
fi
#必须指定主ntp服务器
if [ "${master}" == "" ]
then
  echo 'must specify the master ntp_server'
  echo 'useage:'
  echo "${0} master_ntp"
  exit 1
fi
keyword=`head -1 $currDir/hostname-keyword`
if [ $? == 1 ];then
  echo 'find ./hostname-keyword file error!'
  exit 1
fi

ys=`grep ${keyword} /etc/hosts |awk '{ print $2}'`
for s in $ys
do 
   if [ $s != $master ]
   then
     ssh_ntpdate $s $master
   fi
done


