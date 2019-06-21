#!/bin/bash
db=$1
scriptName=$0
function usage(){
  msg=$1
  echo "Usage:"
  echo "$scriptName \$database"  
  echo ''
  echo "Error: $msg"
  return 0
}
if [ "" == "$db" ] ;then
  usage "database name can't be null"
  exit 1
fi
showSqlList=`hive -e "use $db;show tables"|awk -v databaseName=$db '{print "show@create@table@"databaseName"."$0";"}'`
showSqlJoin=''
for i in $showSqlList
do
   echo ''
   showSqlJoin="$showSqlJoin`echo $i|sed 's/@/ /g'`"
done

hive -e "$showSqlJoin"|\
  sed 's/CREATE/;CREATE/g'|\
  sed '/LOCATION/d'|\
  sed '/hdfs:/d'|\
  sed '/TBLPROPERTIES/d'|\
  sed '/COLUMN_STATS_ACCURATE/d'|\
  sed '/last_modified_by/d'|\
  sed '/last_modified_time/d'|\
  sed '/numFiles/d'|\
  sed '/numRows/d'|\
  sed '/rawDataSize/d'|\
  sed '/totalSize/d'|\
  sed '/transient_lastDdlTime/d' > ./${db}_ddl.sql

