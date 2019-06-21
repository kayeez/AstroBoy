#!/bin/bash
currDir=`dirname $0`
#目标节点
keyword=`head -1 $currDir/hostname-keyword`
if [ $? == 1 ];then
  echo 'find $currDir/hostname-keyword file error!'
  exit 1
fi
hs=`grep ${keyword} /etc/hosts |awk '{ print $2 }'`
localName=`hostname`
srcFile=$1
destFile=$2
if [ "" == "$srcFile" -o "" == "$destFile" ]
then
  echo 'usage:'
  echo "$0 srcFile destFile"
  echo '必须要有参数srcFile(目标文件或者文件夹),destFile（拷贝到目标节点位置）'
  exit 1
fi

#如果分发文件目标不存在，则退出
if [ ! -e $srcFile ] ;then
   echo '分发文件(夹)不存在！'
   exit 1
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


