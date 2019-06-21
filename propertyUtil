#!/bin/bash
# <property><name></name><value>true</value></property>
shellName=$0

function Usage(){
  echo "Usage:"
  echo "$shellName -c ConfigFilePath [-f PropListFile -p PropName=PropValue]"
}

function updateProperty(){
  propName=$1
  propValue=$2
  propFile=$3
  matchLine=`sed -n "/$propName/=" $propFile`
  if [ "" != "$matchLine" ] ;then
      startLine=`head -$matchLine $propFile|sed -n '/<property>/='|awk 'END{print $0}'`
      endIndex=`tail -n +$matchLine $propFile|sed -n '/<\/property>/='|head -1`
      endLine=$(($startLine+endIndex-1))
      echo "******${propName} matched*********"
      echo matchLine:$matchLine
      echo startLine:$startLine
      echo endIndex:$endIndex
      echo endLine:$endLine
      echo "********************"
      sed -i "${startLine},${endLine}d" $propFile 
  fi
  sed -i '/<\/configuration>/d' $propFile
  cat >> $propFile << EOF
  <property>
     <name>${propName}</name>
     <value>${propValue}</value>
  </property>
EOF


  #echo "<property><name>${propName}</name><value>${propValue}</value></property>" >> $propFile
  echo "</configuration>" >> $propFile
 
}


while getopts "f:p:c:" opt; do
    case $opt in
       f)
         declare prop_list_file=$OPTARG
         ;;
       p)
         declare prop=$OPTARG
         ;;
       c)
         declare config_file=$OPTARG
         ;;
    esac
done

#echo prop_list_file:$prop_list_file
#echo prop:$prop
#echo config_file=$config_file

if [ "" == "$config_file" ] ;then
  Usage
  exit 1
fi
if [ ! -e $config_file ] ;then
  Usage
  echo "$config_file not exists!"
  exit 1
fi

if [ ! -f $config_file ] ;then
  Usage
  echo "$config_file is not a regular file!"
  exit 1
fi

if [ "" != "$prop_list_file" ] ;then
   for p in `cat $prop_list_file|sed '/^$/d'|grep '='`
   do
     propName=`echo $p|awk -F '=' '{print $1}'`
     propValue=`echo $p|awk -F '=' '{print $2}'`
     updateProperty $propName $propValue $config_file
   done
fi
if [ "" != "$prop" ] ;then
   propName=`echo $prop|awk -F '=' '{print $1}'`
   propValue=`echo $prop|awk -F '=' '{print $2}'`
   updateProperty $propName $propValue $config_file
fi

echo "$config_file Updated:"
cat $config_file

