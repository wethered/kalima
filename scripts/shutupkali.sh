#!/bin/bash

# ensure running as root, if not, sudo and execute script again
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi


# Burp
iptables -A OUTPUT -d 54.246.133.196 -j REJECT
iptables -A OUTPUT -p udp --dport 53 -m string --string "portswigger" --algo bm -j DROP
iptables -A OUTPUT -p tcp --dport 53 -m string --string "portswigger" --algo bm -j DROP

if ! grep -Fq "portswigger.net." /etc/hosts
then
bash -c 'echo "::1         portswigger.net." >> /etc/hosts'
bash -c 'echo "127.0.0.1 portswigger.net." >> /etc/hosts'
fi

 

# Network Manager
pkill dhclient
systemctl -q disable network-manager.service
systemctl -q stop network-manager.service

 

# NTP
systemctl -q disable openntpd.service
systemctl -q stop openntpd.service

#RPCBIND
systemctl disable rpcbind
systemctl stop rpcbind

#Software Updates
gsettings set org.gnome.software download-updates false
apt purge unattended-upgrades -y

# NTP (in Kali Rolling)
systemctl disable systemd-timesyncd
systemctl stop systemd-timesyncd

 

# SSH
systemctl -q disable ssh.service
systemctl -q stop ssh.service



# kill ntp client
timedatectl set-ntp 0

# kill icmp reply and ipv6
sysctl net.ipv4.icmp_echo_ignore_all=1
sysctl net.ipv6.conf.all.disable_ipv6=1
sysctl net.ipv6.conf.default.disable_ipv6=1
sysctl net.ipv6.conf.lo.disable_ipv6=1

 

#WARNING FOR MAC & HOSTNAME
macchanger -r eth0
RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "${RED}DON'T FORGET TO CHANGE THE MAC AND HOSTNAME TO SOMETHING THAT MAKES SENSE${NC}"

 

# remove dns server
echo >/etc/resolv.conf

echo  NOW REBOOT! Use ${RED}'ss -tulpen;ip addr | grep inet'${NC} to check if you're actually gone dark.
