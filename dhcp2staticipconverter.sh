#!/usr/bin/env bash

#getting ip address assigned by dhcp
ip_addr=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
ip_network=$(echo ${ip_addr%.*})
ip_gateway=$(/sbin/ip route | awk '/default/ { print $3 }')
ip_netmask=$(ifconfig | grep -w inet |grep -v 127.0.0.1| awk '{print $4}' | cut -d ":" -f 2)
ip_ethernet=$(ip route get 8.8.8.8 | awk '{ print $5; exit }')
declare -a array=(`cat /etc/resolv.conf |grep nameserver|awk -F" " '{print $2}'`)
no_nameservers=$(cat /etc/resolv.conf |grep nameserver|awk -F" " '{print $2}' | wc -l)
guid=$(uuidgen $ip_ethernet)

if [ -f /etc/redhat-release ]; then
	ethernet_file=/etc/sysconfig/network-scripts/ifcfg-$ip_ethernet
	if [[ -f "$ethernet_file" ]]; then
		#backing up ifcfg-eth0
		mv -f $ethernet_file $ethernet_file.backup
		echo TYPE=Ethernet > $ethernet_file
		echo BOOTPROTO=static >> $ethernet_file
		echo NAME=$ip_ethernet >> $ethernet_file
		echo UUID=$guid >> $ethernet_file
		echo DEVICE=$ip_ethernet >> $ethernet_file
		echo ONBOOT=yes >> $ethernet_file
		echo IPADDR=$ip_addr >> $ethernet_file
		echo NETMASK=$ip_netmask >> $ethernet_file
		echo GATEWAY=$ip_gateway >> $ethernet_file
		
		for (( i = 0; i < $no_nameservers; i++ )); do
			dno=$((i+1))
			echo DNS$dno=${array[$i]} >> $ethernet_file
		done
		echo "################################################################################"
		echo "############ IP ADDRESS SUCCESSFULLY CHANGED FROM DHCP TO STATIC ###############"
		echo "############################# MACHINE WILL BE REBOOTED #########################"
		echo "######################## NEW IP ADDRESS IS $ip_addr ############################"
		echo "################################################################################"
		#restarting network service
		systemctl restart network
	else
		echo "Ethernet Configuration file NOT FOUND!" && exit 0
  	fi
fi

if [ -f /etc/lsb-release ]; then
  echo "Support for Debian/Ubuntu Coming soon !"
fi
