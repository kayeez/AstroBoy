#!/bin/bash
currDir=`dirname $0`
#目标节点
keyword=`head -1 $currDir/hostname-keyword`
if [ $? == 1 ];then
  echo 'find $currDir/hostname-keyword file error!'
  exit 1
fi
hs=`grep $keyword /etc/hosts |awk '{ print $2 }'`
exeCmd=$1
if [ "" == "$exeCmd" ]
then
  echo 'usage:'
  echo "$0 exeCmd"
  echo '必须要有参数exeCmd(每个节点执行的命令)'
  exit 1
fi

 for s in $hs 
 do
   echo "*******************在节点$s执行命令：[$exeCmd]******************"
   
   ssh $s $exeCmd 

   echo '*****************************************************************'
done


