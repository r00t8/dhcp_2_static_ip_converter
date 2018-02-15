#!/usr/bin/env bash

#getting ip address assigned by dhcp
ip_addr=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
ip_network=$(echo ${ip_addr%.*})
ip_gateway=$ip_network.1
ip_netmask=$(ifconfig | grep -w inet |grep -v 127.0.0.1| awk '{print $4}' | cut -d ":" -f 2)

#getting dhcp assigned dns servers
I=$(wc -l /etc/resolv.conf | cut -d\/ -f1);
N=$[I-2];
tail -n$N /etc/resolv.conf > /etc/resolv.conf.sed
cat /etc/resolv.conf.sed | awk '{print $2}' > /etc/resolv.conf.awk
#creating dns lines to use in ifcfg-eth0
counter=1
filename=/etc/resolv.conf.awk
while read -r line
do
  #printf "%010d %s" $counter $line >> /etc/resolv.conf.awk.2
  printf "DNS%d=%s" $counter $line >> /etc/resolv.conf.awk.2
  printf "\n" >> /etc/resolv.conf.awk.2
  let counter=$counter+1
done < "$filename"
#backing up ifcfg-eth0
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.backup
#updating dhcp to static in ifcfg-eth
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/ifcfg-eth0
#updating uuid of eth0
guid=$(uuidgen)
sed -i '/^UUID/c\UUID='$guid'' /etc/sysconfig/network-scripts/ifcfg-eth0
echo IPADDR=$ip_addr >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo NETMASK=$ip_netmask >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo GATEWAY=$ip_gateway >> /etc/sysconfig/network-scripts/ifcfg-eth0
cat /etc/resolv.conf.awk.2
cat /etc/resolv.conf.awk.2 >> /etc/sysconfig/network-scripts/ifcfg-eth0
#deletign tmp files
rm -rf /etc/resolv.conf.sed /etc/resolv.conf.awk /etc/resolv.conf.awk.2
echo "################################################################################"
echo "############ IP ADDRESS SUCCESSFULLY CHANGED FROM DHCP TO STATIC ###############"
echo "############################# MACHINE WILL BE REBOOTED #########################"
echo "######################## NEW IP ADDRESS IS $ip_addr ############################"
echo "################################################################################"
#restarting network service
systemctl restart network
