#!/bin/bash
source opendj.properities
echo "Do you want to create your directory? Enter key to confirm, Esc to exit!"
read -n 1 key
if [ "$key" == $"" ]; then
	echo "You pressed enter!"
	if [[ ! -d "$ds" || "$db" || "$log" ]]; then
		sudo mkdir -p -- "$ds"
		sudo mkdir -p -- "$db"
		sudo mkdir -p -- "$log"
		sudo chmod -R 744 "/opt"
		sudo chown -R rong_cong:rong_cong "/opt"
		echo "DS Directories created"
	else
		echo "At least one or more Directories exists"
	fi
elif [ "$key" == $'\e' ]; then
	echo "Exit the program"
fi
