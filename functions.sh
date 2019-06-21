

#输出N行**，分隔行
function echoLineSeparator(){
    loop=$1
    if [ "$loop" == "" ]
    then
     $loop=1
    fi

    for((i=1;i<=$loop;i++))
    do
       echo ''
       echo "*********************$2****************************"
       echo ''
    done
    
   return 0
}

#检测当前用户是否是root用户
function checkCurrentUserIsRoot(){
   currUser=`whoami`
   if [ "$currUser" != "root" ]
   then
     echo 'Must be root user to continue!'
     return 1
   fi
     return 0
}

#创建用户：账户为ben，密码为1234
function makeUserBen(){
   CheckCurrentUserIsRoot 
   c=$?
   if [  c == 1]
   then 
      return 1
   else
     useradd ben
     echo '1234' | passwd --stdin ben
   fi

   return 0
}

#配置每每个节点的hostname
function configHostname(){
   file=$1
   lines= `awk '{print "ssh root@$2 \'echo $1 >> /etc/hostname \' " }' $file`
   for i in $lines
   do
    sh $i
  done
}

function checkOS_ISORes(){
  currDir=`dirname $0`
  os_file_prefix=$1
  os_version=$2
  if [ "" == "$os_version" ]
  then
     echo "$0 need to specify the os_version"
     return 1
  fi
 if [ "" == "$os_file_prefix" ]
  then
     echo "$0 need to specify the os file prefix"
     return 1
  fi

  iso_file="$currDir/res/${os_file_prefix}-$os_version*.iso"
   echo "checking ${os_file_prefix} iso package $iso_file"
    echo ''
    echo ''
    curr_file_count=`ls -l $iso_file |awk 'END{ print NR}'`
    if [ $curr_file_count == 0 ]
    then
       echo "        can't find any iso package like [$iso_file],checking failed!!"
       return 1
    elif [ $curr_file_count -gt 1 ]
    then
      echo "         find more than one iso  package like dir[$iso_file],checking failed"
      ls -l $iso_file
      return 1
    else
      f=`ls -l $iso_file`
      echo '         find only one iso package!!!'
      echo "         **********[$f]*****************"
    fi
    echo ''
    echo ''
    echo "checking Res package $iso_file finish!! checking successful!! "
  
   return 0
}


function checkRes(){
  currDir=`dirname $0`
  os_version=$1
  if [ "" == "$os_version" ]
  then
     echo "$0 need to specify the os_version"
     return 1
  fi
  
  ambari_file="$currDir/res/ambari-*-$os_version.tar.gz"
  hdp_file="$currDir/res/HDP-*-$os_version-rpm.tar.gz"
  hdp_util_file="$currDir/res/HDP-UTILS-*-$os_version.tar.gz"
  
  file_array=($ambari_file $hdp_file $hdp_util_file)
  for((n=0;n<${#file_array[@]};n++))
  do
    i=${file_array[$n]}
    echo "checking Res package $i"
    echo ''
    echo ''
    curr_file_count=`ls -l $i |awk 'END{ print NR}'`
    if [ $curr_file_count == 0 ]
    then
       echo "        can't find any dependency package like [$i],checking failed!!"
       return 1
    elif [ $curr_file_count -gt 1 ]
    then
      echo "         find more than one dependency package like dir[$i],checking failed"
      ls -l $i
      return 1
    else
      f=`ls -l $i`
      echo '         find only one dependency package!!!'
      echo "         **********[$f]*****************"
    fi
    echo ''
    echo ''
    echo "checking Res package $i finish!! checking successful!! "
  done
  return 0

}





#检测依赖文件是否存在，如果不存在返回1，存在返回0
function checkDependencyFile(){
   currDir=`dirname $0`
   if [ ! -e $currDir/expect_ssh.exp ]
   then
        echo "can not find Dependency File $currDir/expect_ssh.exp !"
        return  1
   fi
   if [ ! -e $currDir/expect_scp_from_remote.exp ]
   then
        echo "can not find Dependency File $currDir/expect_scp_from_remote.exp !"
        return  1
   fi
   if [ ! -e $currDir/expect_scp_to_remote.exp ]
   then
        echo "can not find Dependency File $currDir/expect_scp_to_remote.exp !"
        return  1
   fi
   if [ ! -e $currDir/expect_test_ssh_no_psw.exp ]
   then
        echo "can not find Dependency File $currDir/expect_test_ssh_no_psw.exp !"
        return  1
   fi

   if [ ! -e $currDir/executeCommandOnEachNode.sh ] 
   then
	echo "can not find Dependency File $currDir/exeuteCommandOnEachNode.sh !"
        return  1
   fi
   if [ ! -e $currDir/hostname-keyword ]
   then
         echo "can not find Dependency File $currDir/hostname-keyword !"
        return  1
   fi
   if [ ! -e $currDir/host_file ]
   then
         echo "can not find Dependency File $currDir/host_file !"
        return  1
   fi 
    if [ ! -e $currDir/conf/master-ntp.conf ]
   then
         echo "can not find Dependency File $currDir/conf/master-ntp.conf !"
        return  1
   fi
   if [ ! -e $currDir/conf/slave-ntp.conf ]
   then
         echo "can not find Dependency File $currDir/conf/slave-ntp.conf !"
        return  1
   fi

 
   return 0
}

#在每个节点上执行相同的命令
function executeCommandOnEachNode(){
currDir=`dirname $0`
#目标节点
keyword=`head -1 $currDir/hostname-keyword`
if [ $? == 1 ];then
  echo "find $currDir/hostname-keyword file error!"
  return 1
fi
hs=`grep ${keyword} /etc/hosts | awk '{ print $2 }'`
exeCmd=$1
if [ "" == "$exeCmd" ]
then
  echo 'usage:'
  echo "$0 exeCmd"
  echo '必须要有参数exeCmd(每个节点执行的命令)'
  return 1
fi
echo "在每个节点上执行相同的命令$exeCmd"
 for s in $hs
 do
   echo "*******************在节点$s执行命令：[$exeCmd]******************"

   ssh $s $exeCmd
   
   echo '*****************************************************************'
done




}

#在其他节点上执行相同的命令
function executeCommandOnOtherNodes(){

currDir=`dirname $0`
#目标节点
keyword=`head -1 $currDir/hostname-keyword`
if [ $? == 1 ];then
  echo "find $currDir/hostname-keyword file error!"
  return 1
fi
hs=`grep ${keyword} /etc/hosts | awk '{ print $2 }'`
exeCmd=$1
if [ "" == "$exeCmd" ]
then
  echo 'usage:'
  echo "$0 exeCmd"
  echo '必须要有参数exeCmd(每个节点执行的命令)'
  return 1
fi

echo "在其他节点上执行相同的命令$exeCmd"

currHostName=`hostname`
 for s in $hs
 do
   if [ "$s" != "$currHostName" ] ;then
      echo "*******************在节点$s执行命令：[$exeCmd]******************"
   
      ssh $s $exeCmd
   
      echo '*****************************************************************'

   fi
   
done




}




#从当前节点分发文件到其他节点
function distributeFilesToNodes(){
currDir=`dirname $0`
keyword=`head -1 $currDir/hostname-keyword`
if [ $? == 1 ];then
  echo 'find $currDir/hostname-keyword file error!'
  return 1
fi
hs=`grep ${keyword} /etc/hosts | awk '{ print $2 }'`
localName=`hostname`
srcFile=$1
destFile=$2
if [ "" == "$srcFile" -o "" == "$destFile" ]
then
  echo 'usage:'
  echo "$0 srcFile destFile"
  echo '必须要有参数srcFile(目标文件或者文件夹),destFile（拷贝到目标节点位置）'
  return 1
fi

#如果分发文件目标不存在，则退出
if [ ! -e $srcFile ] ;then
   echo '分发文件(夹)不存在！'
   return 1
fi

if [ -d $srcFile ] ;then
 #是文件夹，则需要在命令上添加-r参数
 for s in $hs 
 do
    #排除当前节点
    if [ "$localName" != "$s" ] ;then
      scp -r $srcFile $s:$destFile
    fi
 done
elif [ -f $srcFile ] ;then
 #是文件，则不需要在命令上添加-r参数
 for s in $hs
 do
    #排除当前节点
    if [ "$localName" != "$s" ] ;then
       scp  $srcFile $s:$destFile
    fi
 done

fi

}

#根据ip地址获取root密码
function getRootPSWByIP(){
  ip_file=$1
  ip=$2
  psw=`awk -v ip=$ip '{if(NF>0 && ip==$1){print $3}}' $ip_file`
  echo $psw
  return 0
}
#根据ip地址获取hostname
function getHostNameByIP(){
  ip_file=$1
  ip=$2
  hn=`awk -v ip=$ip '{if(NF>0 && ip==$1){print $2}}' $ip_file`
  echo $hn
  return 0

}
