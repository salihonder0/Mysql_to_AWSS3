#!/bin/bash

db_host=`grep -i 'db_host' transfer.conf` 
db_host_parsed=`echo "$db_host" | cut -d'"' -f 2` 