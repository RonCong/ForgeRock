#!/bin/bash

echo "Where do you want to create your directory"
read ds
if [[ ! -d "$ds" ]]
then
    	sudo mkdir -p -- "$ds"
	sudo chmod 744 "$ds"
	sudo chown -R rong_cong:rong_cong "$ds" 
    	echo "DS Directory created"
else
       	echo "Dir exists"
fi

#Create directory for backend DB
echo "What's the name of database directory"
read db
if [[ ! -d "/opt/ldapdb/$db" ]]
then
        sudo mkdir -p -- "/opt/ldapdb/$db"
        sudo chmod 744 "/opt/ldapdb/$db"
        sudo chown -R rong_cong:rong_cong "/opt/ldapdb/$db"     
        echo "DB Directory created"
else
        echo "Dir exists"
fi

#Create log diretcory
echo "What's the name of log directory"
read log
if [[ ! -d "/opt/ldaplogs/$log" ]]
then
        sudo mkdir -p -- "/opt/ldaplogs/$log"
        sudo chmod 744 "/opt/ldaplogs/$log"
        sudo chown -R rong_cong:rong_cong "/opt/ldaplogs/$log"     
        echo "log Directory created"
else
        echo "Dir exists"
fi
echo "dspath=$ds;dbpath='$db';logpath='$log'" > /opt/script/opendj.properities
sudo chown -R rong_cong:rong_cong "/opt/script/opendj.properities"
