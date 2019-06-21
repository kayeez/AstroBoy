#!/bin/bash
currDir=`dirname $0`
set -e
echo -n  "Comfirm continue！(y/n)"
read confirm
if [ "y" != "$confirm" ] ;then
   confirm="n"
else
   confirm="y"
fi
diskMapping=`cat $currDir/diskMapping`

echo "Delete Mount Disk Config"
deleteMountConfigCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F - '{print "sed@-i@%/sd"$1"1/d%@/etc/fstab"}'`
for i in $deleteMountConfigCmd
do
   echo $i|sed 's/@/ /g'|sed "s/%/'/g"
   if [ "y" == "$confirm" ] ;then
       echo $i|sed 's/@/ /g'|sed "s/%/'/g"|sh
   fi
done
echo "UnMount Disk Config"
set +e
unmountCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F - '{print "umount@/dev/sd"$1"1"}'`
for i in $unmountCmd
do
   echo $i|sed 's/@/ /g'|sed "s/%/'/g"
   if [ "y" == "$confirm" ] ;then
       echo ''
       echo $i|sed 's/@/ /g'|sed "s/%/'/g"|sh
   fi
done
set -e
echo "Auto Part Disk"
autoPartCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F -  '{print "parted@-s@/dev/sd"$1}'`
#parted -s /dev/sdb mklabel gpt && parted /dev/sdb mkpart primary 1 -1 && parted /dev/sdc p
for i in $autoPartCmd
do
   disk=`echo $i |sed 's/@/ /g'`
   echo '**********************'
   echo "$disk 'mklabel gpt'"
   echo "$disk 'mkpart primary 1 -1'"
   echo "$disk 'p'"
   echo '**********************'
   if [ "y" == "$confirm" ] ;then
      echo ''
       echo "$disk 'mklabel gpt'"|sh
       echo "$disk 'mkpart primary 1 -1'"|sh
       echo "$disk 'p'"|sh
   fi
done
echo "UnMount Disk Config"
set +e
unmountCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F - '{print "umount@/dev/sd"$1"1"}'`
for i in $unmountCmd
do
   echo $i|sed 's/@/ /g'|sed "s/%/'/g"
   if [ "y" == "$confirm" ] ;then
       echo ''
       echo $i|sed 's/@/ /g'|sed "s/%/'/g"|sh
   fi
done
set -e
mkfsCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F - '{print "mkfs.ext3@/dev/sd"$1"1"}'`
echo "Format Disk as File System ext3"
for i in $mkfsCmd
do
   echo $i|sed 's/@/ /g'
   if [ "y" == "$confirm" ] ;then
     echo ''
     echo $i|sed 's/@/ /g'|sh
   fi
done
echo "Mount Disk"
mountCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F - '{print "mkdir@-p@/data/disk"$2"@&&@mount@/dev/sd"$1"1@/data/disk"$2}'`
for i in $mountCmd
do
   echo $i|sed 's/@/ /g'
   if [ "y" == "$confirm" ] ;then
       echo ''
       echo $i|sed 's/@/ /g'|sh
   fi
done
echo "Write Mount Disk Config"
writeMountConfigCmd=`echo $diskMapping|awk '{for(i=1;i<=NF;i++){print $i}}'|awk -F - '{print "sed@-i@%/sd"$1"1/d%@/etc/fstab@&&@echo@%/dev/sd"$1"1@/data/disk"$2"@@@@@@@@@@@@ext3@@@@@defaults@@@@@0@0%@>>@/etc/fstab"}'`
for i in $writeMountConfigCmd
do
   echo $i|sed 's/@/ /g'|sed "s/%/'/g"
   if [ "y" == "$confirm" ] ;then
       echo ''
       echo $i|sed 's/@/ /g'|sed "s/%/'/g"|sh
   fi
done


