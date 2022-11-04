#!/bin/bash

db_host=`grep -i 'db_host' transfer.conf` 
db_host_parsed=`echo "$db_host" | cut -d'"' -f 2` 

db_user=`grep -i 'db_user' transfer.conf` 
db_user_parsed=`echo "$db_user" | cut -d'"' -f 2` 

db_pass=`grep -i 'db_pass' transfer.conf` 
db_pass_parsed=`echo "$db_pass" | cut -d'"' -f 2` 

db_name=`grep -i 'db_host' transfer.conf` 
db_name_parsed=`echo "$db_name" | cut -d'"' -f 2` 

## Dump location on server and other variables

server_dump_location=`grep -i 'db_host' transfer.conf` 
server_dump_location_parsed=`echo "$server_dump_location" | cut -d'"' -f 2` 

log_path=`grep -i 'db_user' transfer.conf` 
log_path_parsed=`echo "$log_path" | cut -d'"' -f 2` 

log_location=`grep -i 'db_pass' transfer.conf` 
log_location_parsed=`echo "$log_location" | cut -d'"' -f 2` 

s3_bucket=`grep -i 'db_host' transfer.conf` 
s3_bucket_parsed=`echo "$s3_bucket" | cut -d'"' -f 2` 


time_stamp="$(date +"%d-%b-%Y-%H_%M_%S")"


# Check If diretory is present or not, If not then create it.
echo "##################################################################" >> $log_location_parsed
if [ -d $server_dump_location_parsed ]; then
    echo "Directory Alredy Exists" >> $log_location_parsed
elif [ -d $log_path_parsed ]; then
    echo "Log Directory Alredy Exists" >> $log_location_parsed
else
    mkdir $server_dump_location_parsed $log_path_parsed
    echo "Directory Was not there, hence created $server_dump_location_parsed and $log_path_parsed" >> $log_location_parsed
fi


slack_url=`grep -i 'slack_url' transfer.conf` 
slack_url_parsed=`echo "$slack_url" | cut -d'"' -f 2` 

## Server backup initialization
echo "Taking the backup of sample wordpress database, Started at: $time_stamp" >> $log_location_parsed
mysqldump -h $db_host_parsed -u $db_user_parsed -p$db_pass_parsed $db_name_parsed > $server_dump_location_parsed/$db_name_parsed-$time_stamp.sql
if [ $? -eq 0 ]; then
    echo "Backup Successfully Done" >> $log_location_parsed
else
    echo "Backup Failed, Please check" >> $log_location_parsed
    exit 1
fi
echo "Backup Completed at: $time_stamp" >> $log_location_parsed

# Push Dump to S3 bucket.
echo "Pushing test wordpress db dump to S3 at $time_stamp" >> $log_location_parsed
aws s3 cp $server_dump_location_parsed $s3_bucket_parsed --recursive
echo "Moved mysql dump to S3 at $time_stamp" >> $log_location_parsed
echo "#################################################################" >> $log_location_parsed

# Delete the Mysql Dump from the Server
sudo rm -rf $server_dump_location_parsed/$db_name_parsed-*

# Or, # Clear Dumps from the Server Older than 1 Weeks.

# find $server_dump_location/* -mtime +7 -exec rm {} \;

# Notification to Slack

curl -X POST -H 'Content-type: application/json' --data '{"text":"'"Backup of Sample Wordpress database has completed at $time_stamp"'"}' $slack_url_parsed

### complete command
# curl -X POST -H 'Content-type: application/json' --data '{"text":"'"Message $time_stamp"'"}' https://hooks.slack.com/services/xxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx