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
showSqlList=`hive -e "use $db;show tables"|awk -v databaseName=$db '{print "ALTER@TABLE@"databaseName"."$0"@SET@TBLPROPERTIES(\047numRows\047=\047-1\047);"}'`
showSqlJoin=''
for i in $showSqlList
do
   echo ''
   showSqlJoin="$showSqlJoin`echo $i|sed 's/@/ /g'`"
done
echo "$showSqlJoin"|awk -F \; '{for(i=1;i<=NF;i++){print $i}}'
hive -e "$showSqlJoin"
