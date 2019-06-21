#!/bin/bash
startTime=`date +%s`

echo "开始时间：$(date '+%Y-%m-%d %H:%M:%S')"

os=`awk '{if($1=="CentOS"){if(match($4,/^6/)||match($3,/^6/)){print 6}else if(match($4,/^7/)||match($3,/^7/)){print 7}}}' /etc/centos-release`
if [ "" == $os ]
then
  echo '不支持的操作系统版本，只支持CentOS 6和CentOS 7'
  exit 1
fi
echo "当前操作系统版本CentOS $os"
currDir=`dirname $0`
source $currDir/functions.sh
ip_file=$1

#判断是否是root用户
checkCurrentUserIsRoot
if [ $? != 0 ]
then 
   exit 1
fi
#判断是否传入Hostname和IP地址文件
if [ "${ip_file}" == "" ]
then
   echo 'please input a file which  includes ip ,hostname,root-password(eg: master 192.168.1.110 1234)'
   echo 'each line only contain one record,and sepearator is tab space!'
   exit 1
fi
#判断传入的参数是否为文件
if [ ! -f ${ip_file} ]
then
   echo ${ip_file}' is not a regular file'
   exit 1
fi

#检测依赖文件是否存在
echo ''
echo '检测脚本依赖'
echo ''
checkDependencyFile
if [ $? != 0 ]
then
   exit 1
fi
#检测jdk安装包是否存在
echo "检测jdk安装包是否存在"
jdkFiles=`ls -l $currDir/res/ |grep jdk |awk 'END{print NR}'`
if [ $jdkFiles != 1 ] ;then
   echo 'jdk安装包缺失，或拥有多个安装包，退出！'
   exit 1
fi
 httpHome=/var/www/html


#打印一行分隔符
echoLineSeparator 1 '开始进行hostname配置，请不要手动打断！'
#所有的节点ip
total_ips=`awk '{print $1}' $ip_file`
#当前所在节点ip
mip=`ip addr |grep inet|grep brd |awk '{print $2}' |awk -F / '{print $1}'`
#除开当前节点ip
other_ips=`grep -v $mip ${ip_file} |awk '{print $1}' `

allHostNames=`awk '{print $2}' $ip_file`

echoLineSeparator 1 '开始配置节点之间root用户免密登录,请不要手动打断！'
   #遍历节点，在每个节点执行ssh-keygen命令
   for i in $total_ips
   do
       psw=`getRootPSWByIP $ip_file $i`
       $currDir/expect_ssh.exp root $i  'ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa' $psw  
   done
   #将其他节点的id_rsa.pub文件copy到当前节点
   for i in $other_ips
   do
       psw=`getRootPSWByIP $ip_file $i`
     $currDir/expect_scp_from_remote.exp root $i $psw  /root/.ssh/id_rsa.pub /root/.ssh/id_scp$i  
   done
   #在当前节点构建/root/.ssh/authorized_key 文件
      cat /root/.ssh/id_scp* /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
   #发送authorized_key到每个节点下
      for i in $other_ips
      do
        psw=`getRootPSWByIP $ip_file $i`
        $currDir/expect_scp_to_remote.exp root $i $psw /root/.ssh/authorized_keys /root/.ssh/
      done
   #修改/root/.ssh 文件夹权限
   for i in $total_ips
   do
       $currDir/expect_ssh.exp root $i  'chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys' $psw
   done


echoLineSeparator 1 '完成各个节点之间root用户的免密登录，即将进行下一步！'

echoLineSeparator 1 '开始配置每个节点的hosts文件'
keyword=`head -1 $currDir/hostname-keyword`
if [ $? != 0 ];then
  echo 'find ./hostname-keyword file error!'
  exit 1
fi
hsNR=`grep $keyword /etc/hosts | awk  'END {print NR}'`
if [ $hsNR == 0 ] ;then
   tmpHs=`awk '{print $1}' ${ip_file}`
   for t in $tmpHs
   do
       awk -F " " -v currH=$t '{if(NF > 0){printf("执行命令: ssh %s \"echo \47%s %s\47 >> /etc/hosts\"\n",currH,$1,$2); printf("ssh %s \"echo \47%s %s\47 >> /etc/hosts\"\n",currH,$1,$2) | "sh";close("sh")}}' $ip_file
       
   done
else
  echo  "need to clear /etc/hosts file, delete line contains '${keyword}'"
fi
echoLineSeparator 1 '完成配置每个节点的hosts文件'
echoLineSeparator 1 '测试节点之间免密登录'
for i in $allHostNames
do
    echo "ssh $i"
    $currDir/expect_test_ssh_no_psw.exp $i
done


echoLineSeparator 1 '准备关闭防火墙'
for i in $total_ips
do
       psw=`getRootPSWByIP $ip_file $i`
       if [ "6" == "$os" ]
       then
          $currDir/expect_ssh.exp root $i  "service iptables stop  && chkconfig iptables off"  $psw
       elif [ "7" == "$os" ]
       then
         $currDir/expect_ssh.exp root $i  "systemctl stop firewalld && systemctl disable firewalld && systemctl status firewalld && chkconfig firewalld off" $psw
       fi
           
        $currDir/expect_ssh.exp root $i "sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"

done
mineRepo=/etc/yum.repos.d/ambari.repo

currHostName=`hostname`
echo "清空$mineRepo文件"

echo '' > $mineRepo
echo '[base]' >> $mineRepo
echo "name=centos$os Base" >> $mineRepo
echo "baseurl=http://$currHostName/cdrom" >> $mineRepo
echo "gpcheck=1" >> $mineRepo
echo "gpkey=http://$currHostName/cdrom/RPM-GPG-KEY-CentOS-$os" >> $mineRepo
echo "enabled=1" >> $mineRepo
echo "priority=1" >> $mineRepo

echo "" >> $mineRepo
echo "" >> $mineRepo


echo '完成yum源配置！！！！配置文件类容如下：'
cat $mineRepo
for i in $allHostNames
do
   if [ "$currHostName" != "$i" ] ;then
     ssh $i 'rm -f /etc/yum.repos.d/*.repo'
   fi
done


distributeFilesToNodes $mineRepo $mineRepo
executeCommandOnEachNode 'yum clean all && yum list > /root/yum-list-log.txt 2>&1'
#加载GPG-KEY

echo "加载所有的GPG-KEY"
executeCommandOnEachNode "rpm --import http://$currHostName/cdrom/RPM-GPG-KEY-CentOS-$os"

echoLineSeparator 1 '配置Ntp时间同步服务'
sed -i "s/server n.*/server $currHostName/g" $currDir/conf/slave-ntp.conf
for i in $allHostNames
do
   ntpRPM=`ssh $i 'rpm -qa|grep ntp'`
  if [ "" == "$ntpRPM" ] ;then
   ssh $i 'yum install -y ntp'
  fi
  if [ "$currHostName" == "$i" ] ;then
     rm -f /etc/ntp.conf &&   cp $currDir/conf/master-ntp.conf /etc/ntp.conf
     echo "当前节点(${i})为ntp服务的主节点"
    service ntpd start && /usr/sbin/ntpdate -u localhost &&    service ntpd restart
  else
     echo "当前节点(${i})为ntp服务的从节点，将于主节点进行时间同步"
    scp $currDir/conf/slave-ntp.conf   $i:/etc/ntp.conf
    ssh $i   "service ntpd start && /usr/sbin/ntpdate -u $currHostName &&  service ntpd restart"
  fi

done
executeCommandOnEachNode 'chkconfig ntpd on && service ntpd restart'


echoLineSeparator 1  '安装自带JDK'
executeCommandOnEachNode "rpm -qa|grep java |awk '{print \"rpm -e --nodeps \"\$0}' |sh"
jdkF=`ls $currDir/res/jdk*.rpm |awk -F / 'END{print $NF}'`
echo '当前节点安装JDK'
rpm -ivh $currDir/res/$jdkF
distributeFilesToNodes  $currDir/res/$jdkF /root
executeCommandOnOtherNodes "rpm -ivh /root/$jdkF"
if [ $os == 7 ] ;then
   echoLineSeparator 1 'CentOS 7 需要卸载冲突的依赖snappy包'
   executeCommandOnEachNode 'yum remove -y snappy-1.1.0-3.el7.x86_64'
   executeCommandOnEachNode 'yum install -y snappy-1.0.5-1.el6.x86_64'
fi
echoLineSeparator 1 '完成自动配置，请手动依次完成以下操作！'

endTime=`date +%s`

echo "结束时间：$(date '+%Y-%m-%d %H:%M:%S')"

spend=`expr $endTime - $startTime`
echo "完成自动配置耗时：$spend秒"

