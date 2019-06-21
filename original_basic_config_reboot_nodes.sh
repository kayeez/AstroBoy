#!/bin/bash
echo -n  "该脚本运行完成会重启所有节点,是否继续！(y/n)"
read confirm
if [ "y" != "$confirm" ] ;then
   exit 0
fi
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
mountCommand="mount -o loop "
if [ $os == 7 ]
then
 mountCommand="mount "
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
echo ''
echo '检测安装包依赖'
echo ''
checkCentOS_ISORes $os
if [ $? != 0 ]
then
  echo '检测ISO依赖失败！！！'
  exit 1
fi

echo '检测ISO依赖成功！！'


echoLineSeparator 1 '检测依赖通过，准备挂载系统iso镜像文件，安装expect 和httpd '

 mount_iso_file=`ls $currDir/res/CentOS-$os*.iso` 
 if [ -e /mnt/cdrom -a -d /mnt/cdrom ]
 then
   #文件夹已经存在了
   #检测是否已经有挂载的镜像文件
   deviceName=`df -h | grep '/mnt/cdrom' |awk '{print $1}'`
   if [ "" != "$deviceName" ]
   then
     echo '检测到/mnt/cdrom文件夹上有挂载，将取消这个挂载'
     u_msg=`umount $deviceName`
     echo "mount返回值：$?"
     echo "mount msg:$u_msg"
     if [ "" != "$u_msg" ]
     then
        echo '取消挂载/mnt/cdrom上的设备失败！'
        echo '请手动取消挂载，重新执行该脚本！'
        exit 1
     fi
     echo '取消挂载成功，将重新挂载需要的iso文件'
     $mountCommand $mount_iso_file /mnt/cdrom
     if [ $? != 0 ]
     then
       echo 'mount fail,please check mount command excuting output log!!'
     exit 1
      fi

   else
     #没有在/mnt/cdrom上挂载有设备
     echo '没有在/mnt/cdrom上有挂载设备，但是该文件夹已存在'
     echo '重命名该文件件为/mnt/cdrom.bak'
     mv /mnt/cdrom /mnt/cdrom.bak
     ls -l /mnt
     mkdir -p /mnt/cdrom
     echo "ready to mount file $mount_iso_file to /mnt/cdrom directory!!"
     $mountCommand $mount_iso_file /mnt/cdrom
     if [ $? != 0 ]
     then
       echo 'mount fail,please check mount command excuting output log!!'
     exit 1
      fi

   fi 
 else
   #文件夹不存在
   echo '文件夹/mmt/cdrom不存在'
   mkdir -p /mnt/cdrom
   if [ $? != 0 ]
   then
      echo '创建文件夹/mnt/cdrom失败，请查看命令返回log'
      exit  1
   fi

   echo "ready to mount file $mount_iso_file to /mnt/cdrom directory!!"
   $mountCommand $mount_iso_file /mnt/cdrom
   if [ $? != 0 ]
   then
     echo 'mount fail,please check mount command excuting output log!!'
   exit 1
   fi
 fi
 
echoLineSeparator 1 '挂载镜像成功，准备配置当前节点yum源'

echo '移除 /etc/yum.repos.d文件夹下的所有repo文件'
rm -f /etc/yum.repos.d/*.repo
mineRepo=/etc/yum.repos.d/ambari.repo
echo "[base]"                                        >> $mineRepo
echo "name=centos$os Base"                           >> $mineRepo         
echo "baseurl=file:///mnt/cdrom"                     >> $mineRepo   
echo "gpgcheck=1"                                    >> $mineRepo          
echo "gpgkey=file:///mnt/cdrom/RPM-GPG-KEY-CentOS-$os" >> $mineRepo
echo "enabled=1"                                     >> $mineRepo       
echo "priority=1"                                    >> $mineRepo

echo 1 'mineRepo内容如下'
cat $mineRepo
yum clean all && yum list > $currDir/log.txt 2>&1

if [ $? != 0 ]
then
  exit 1
fi

 
   echoLineSeparator 1 '检测是否安装expect，如果没安装则自动安装'
   expDep=`rpm -qa|grep expect`
   if [ "" == "$expDep" ] ;then
     echo 'Dependency Check ,current host has not installed [expect]'
     yum install -y expect
     if [ $? != 0 ]
     then
       exit 1
     fi
   fi
   echoLineSeparator 1 '检测是否安装http ,如果没有安装则自动安装'
   httpdDep=`rpm -qa|grep -v 'httpd-tools' |grep httpd`
    if [ "" == "$httpdDep" ] ;then
     echo 'Dependency Check ,current host has not installed [httpd]'
     yum install -y httpd   
     if [ $? != 0 ]
     then
       exit 1
     fi
     chkconfig httpd on    
   fi
   echoLineSeparator 1 '必要依赖工具安装成功!!'
 
   echoLineSeparator 1 '在/var/www/html中创建资源文件夹'
  
    httpHome=/var/www/html
    subDirArray=('cdrom')
   
   for((i=0;i<${#subDirArray[@]};i++))
   do
     sub=${subDirArray[$i]}
     echo "子文件夹：$sub"
     if [ -e $httpHome/$sub ]
     then
       echo "文件(夹)$httpHome/$sub已经存在，将移除文件(夹)"
       echo "rm -rf  $httpHome/$sub "   
       rm -rf $httpHome/$sub 
       
     fi 
        mkdir $httpHome/$sub
    

   done
   ls -l  $httpHome
   echo "挂载成功，copy /mnt/cdrom 到$httpHome目录下"
     cp -r /mnt/cdrom /var/www/html
   
   echo "service httpd restart" 
    service httpd restart
    chkconfig httpd on
#打印一行分隔符
echoLineSeparator 1 '开始进行hostname配置，请不要手动打断！'
#所有的节点ip
total_ips=`awk '{print $1}' $ip_file`
#当前所在节点ip
mip=`ip addr |grep inet|grep brd |awk '{print $2}' |awk -F / '{print $1}'`
#除开当前节点ip
other_ips=`grep -v $mip ${ip_file} |awk '{print $1}' `

allHostNames=`awk '{print $2}' $ip_file`
#配置所有节点的hostname
    for i in $total_ips
    do 
       tmpHs=`getHostNameByIP $ip_file $i`
       psw=`getRootPSWByIP $ip_file $i`
       if [ $tmpHs == "" ]
       then
         echo "can not set empty hostname to $i"
         exit 1
       fi
       if [ "6" == "$os" ]
       then
          #替换hostname命令
          repCMD="sed -i  's/^HOSTNAME.*/HOSTNAME=$tmpHs/g' /etc/sysconfig/network"
          echo $repCMD
          $currDir/expect_ssh.exp root $i  "$repCMD"  $psw
          if [  $? != 0 ]
          then
             exit 1
          fi  
       elif [ "7" == "$os" ]
       then
         $currDir/expect_ssh.exp root $i  "echo $tmpHs > /etc/hostname" $psw
       fi
      
    done    
#打印一行分隔符
echoLineSeparator 1 '完成hostname配置，即将进行下一步！'
echoLineSeparator 1 '修改每个节点系统内核参数'
for i in $total_ips
do
 
    psw=`getRootPSWByIP $ip_file $i`
    if [ "6" == "$os" ]
       then
          #修改内核参数
          $currDir/expect_ssh.exp root $i  "echo '*          soft   nproc     60000' > /etc/security/limits.d/90-nproc.conf"  $psw
          $currDir/expect_ssh.exp root $i  "echo 'root       soft    nproc     unlimited' >> /etc/security/limits.d/90-nproc.conf"  $psw

       elif [ "7" == "$os" ]
       then
          $currDir/expect_ssh.exp root $i  "echo '*          soft   nproc     60000' > /etc/security/limits.d/20-nproc.conf"  $psw
          $currDir/expect_ssh.exp root $i  "echo 'root       soft    nproc     unlimited' >> /etc/security/limits.d/20-nproc.conf"  $psw 
       fi

          $currDir/expect_ssh.exp root $i  "echo '*  soft nofile  65536' >> /etc/security/limits.conf"  $psw 
          $currDir/expect_ssh.exp root $i  "echo '*  hard nofile  65536' >> /etc/security/limits.conf"  $psw   
  
done

#重启服务器
endTime=`date +%s`

echo "结束时间：$(date '+%Y-%m-%d %H:%M:%S')"

spend=`expr $endTime - $startTime`
echo "完成自动配置耗时：$spend秒"
echo '需要重启服务器.....'
for i in $other_ips
do
  if [ "$mip" != "$i" ] ;then
    echo "ssh $i 'reboot now'"
    psw=`getRootPSWByIP $ip_file $i`
    $currDir/expect_ssh.exp root $i  "reboot now"  $psw
          
  fi
done
echo "重启当前节点"
reboot now
