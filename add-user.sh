#!/bin/bash

# Author: Anthony Datu
# User creation, docker installation
# Docker group creation and adding user to docker group
# Comes as a no warranty

### REQUIRED PARAMETER ###
user=$1
home="/home/$user"

if [ ${#user} -eq 0 ]
then
	echo "Please pass username as a parameter"
	echo "Exiting the script now"
	exit 1
fi

echo "Creating user account ( $user ), begins..."

if [ ! -d $home ]
then
	useradd -d $home -m $user
	if [ $? -eq 0 ]
	then 
		mkdir -p "$home/.ssh"
		touch "$home/.ssh/authorized_keys"
	else
		echo "Something went wrong during user creation"
		exit 1
	fi
else
	echo "$home directory exists, continuing..."
fi

os=$(awk -F '=' '$1 ~ /^ID$/ {print $2}' /etc/*release*)

if [ "$os"="centos" ]
then
	# Check if docker exists
	docker=$(which docker)
	if [ $? -gt 0 ]
	then
		echo "Installing docker..."
		yum install docker -y
	else
		echo "docker already in $(which docker), skipping.." 
	fi
else
	#This is for debian systems
	docker=$(which docker)
	if [ $? -gt 0 ]
	then
		echo "Installing docker..."
		apt-get install docker -y
	else
		echo "docker already in $(which docker), skipping.."
	fi	
fi 

if [ $? -eq 0 ] && [ -f "$user/.ssh/authorized_keys" ]
then 
	usermod -aG docker $user
	if [ $? -gt 0 ]
	then
		echo "Adding docker group"
		groupadd docker
		gpasswd -a $user docker

		if [ $? -eq 0 ]
		then
			echo "$user successfully added to the docker group"
		fi
	fi
else
	echo "Error: check if docker is installed and $user exists"
fi

if [ -f "$home/.ssh/authorized_keys" ]
then 
echo "Adding public key..."
cat << EOF > "$home/.ssh/authorized_keys"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCu6XhwDolUWYV735OoLtpG/15cBc43877xRnMTtd0hucyV8OfZ2AxKUivP80CIjJfFfw+ut9sf6HRRPuSWtauyFhC8hZW7ATEogO9LhQl0gVNm+DVcmbRZ/35XA2O87eppP+JqqV+ZQKRtOKUWIOmiaXyqaqmnDyNYSt/JrgF63fIeUb8aC5g8eiu7tidiUUrGU1Hl6t3seJSAy9EZrWPByKSibZyOiR+EoEEocAELlm878YHTuT5Ml2Dxr9/s/2IEYb4klJUvIniAF+BsXAmpPjI11cxTjTQ5EBE345ZP6G+1SCSgoeX1dLz/Kg1NthywaM2PBJXOPxInErDdk5i3
EOF
fi

#Changing owner
if [ -d $home ]
then
	echo "Changing owner to $user"
	chown -R $user:$user $home
	echo "Changing chmod of authorized_keys"
	chmod 600 "$home/.ssh/authorized_keys"
fi
