#!/bin/bash

/usr/local/bin/redis-cli -p 8001 cluster nodes|grep master | awk '{print $2}' | cut -d'@' -f1 | sed 's/:/ /g' | awk '{print $1}' > master_ip.txt

/usr/local/bin/redis-cli -p 8001 cluster nodes|grep master | awk '{print $2}' | cut -d'@' -f1 | sed 's/:/ /g' | awk '{print $2}' > master_port.txt

#trap "
#   echo "Compress all the log files into one"
#   tar -C . -czvf client_list_logs.tar.gz *.log
#   echo "Deleting the uncompress files"
#   rm *.log
#   echo "Done!"
#" SIGINT


while true
do
        while IFS= read -r master_ip && IFS= read -r master_port <&3; do
                echo "*** Infinite loop is running press Ctrl-C to break the script"
                /usr/local/bin/redis-cli -h $master_ip -p $master_port client list >> $master_ip-$master_port.log

        done < master_ip.txt 3< master_port.txt
done
