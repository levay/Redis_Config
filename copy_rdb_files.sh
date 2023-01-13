#!/bin/bash
pass='I5erzz^a'
#Find all the master IP and master port in a files (master_ip.txt master_port.txt)
redis-cli -a $pass -p 7002 cluster nodes | grep master | awk '{print $2}' | cut -d'@' -f1 | sed 's/:/ /g' | awk '{print $1}' > master_ip.txt
redis-cli -a $pass -p 7002 cluster nodes | grep master | awk '{print $2}' | cut -d'@' -f1 | sed 's/:/ /g' | awk '{print $2}' > master_port.txt

#ssh to all the master servers to copy the rdb files to s3 bucket
while IFS= read -r master_ip && IFS= read -r master_port <&3; do
  echo "*** Copy the rdp files from: $master_ip to s3://reco-ml-feature-store Bucket ***"
  #Timestamp variables to create directories in s3 bucket
  year=$(date +"%Y")
  month=$(date +"%m")
  date=$(date +"%d")
  epoch_time=$(date +"%s")
  ###################################
  #example ssh command #
  #ssh -o StrictHostKeyChecking=no -i db-team.pem ubuntu@10.10.49.89 "aws s3 cp /mnt/vol1/redis-data/redis-6.2.6/7004/data/dump.rdb s3://reco-ml-feature-store/redis/prod/rdb/
  ssh -n -o StrictHostKeyChecking=no -i db-team.pem ubuntu@$master_ip "aws s3 cp /mnt/vol1/redis-data/redis-6.2.6/$master_port/data/dump.rdb 's3://reco-ml-feature-store/redis/prod/rdb/year=$year/month=$month/day=$date/$master_ip-dump-$epoch_time.rdb'";
  if [ $? -eq 0 ]; then
     echo "$master_ip RDB file Uploaded successfully "
  else
     echo "$master_ip RDB file Upload failed"
  fi
done < master_ip.txt 3< master_port.txt

#Delete the 2 days old rdb files from s3
yesterday=$(date -d "2 days ago" +%d)
aws s3 rm --recursive s3://reco-ml-feature-store/redis/prod/rdb/year=$year/month=$month/day=$yesterday/

#cleanup the master_ip.txt and master_port files
if [ -f master_port.txt ]
then
        echo "files found"
        echo "Remove the files"
        rm master_port.txt master_ip.txt
