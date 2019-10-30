#!/bin/bash

echoError() {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${RED}[!]${NC} $1\n"
}
echoInfo() {
  YELLOW='\033[0;33m'
  NC='\033[0m' # No Color
  printf "${YELLOW}[i]${NC} $1\n"
}
echoAction() {
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
  printf "${GREEN}[+]${NC} $1\n"
}
echoSection() {
  CYAN='\033[0;36m'
  NC='\033[0m' # No Color
  printf "${CYAN}$1${NC}\n"
}

echoSection "===== + Silencing + ====="

echoAction "Disabling the Gnome automatic software downloads"
gsettings --version > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "gsettings not installed. Moving on."
else
   gsettings set org.gnome.software download-updates false
   gsettings set org.gnome.software download-updates-notify false
   gsettings set org.gnome.software allow-updates false
fi

echoAction "Removing unattended upgrades"
(DEBIAN_FRONTEND=noninteractive apt purge unattended-upgrades -y -qqq) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Could not remove unattended-upgrades. Please verify and remove manually."

fi

echoAction "Killing NTP"
(systemctl disable systemd-timesyncd && systemctl stop systemd-timesyncd && timedatectl set-ntp 0) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Could not disable NTP"
fi

echoAction "Killing RPCBind"
systemctl -q disable rpcbind 2>&1 && systemctl -q stop rpcbind
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Could not disable RPCBind"
fi

echoAction "Disabling ICMP echo replies"
(echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/systectl.conf && sysctl -p) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Could not kill ICMP echo replies"
fi

echoAction "Disabling IPv6"
(echo 'net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf;sysctl -p) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Could not kill ICMP echo replies"
fi

echoAction "Disabling network-manager services"
(systemctl -q stop network-manager.service && systemctl -q disable network-manager.service) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Could not disable network-manager"
fi

if ! grep -Fq "mozilla.org" /etc/hosts
then
echoAction "Silencing firefox (DNS Blackhole in /etc/hosts)"
echo "

# Silencing for Firefox
127.0.0.2 detectportal.firefox.com
127.0.0.2 self-repair.mozilla.org
127.0.0.2 blocklist.addons.mozilla.org
127.0.0.2 firefox.settings.services.mozilla.com
127.0.0.2 content-signature.cdn.mozilla.net
127.0.0.2 safebrowsing.google.com
127.0.0.2 safebrowsing-cache.google.com
127.0.0.2 support.mozilla.org" >> /etc/hosts
fi

echoAction "Silencing Burp (ip tables & /etc/hosts)"
iptables -A OUTPUT -d 54.246.133.196 -j REJECT
iptables -A OUTPUT -p udp --dport 53 -m string --string "portswigger" --algo bm -j DROP
iptables -A OUTPUT -p tcp --dport 53 -m string --string "portswigger" --algo bm -j DROP

if ! grep -Fq "portswigger.net" /etc/hosts
then
echo "

# Silencing for Burp
::1       portswigger.net
127.0.0.1 portswigger.net" >> /etc/hosts
fi

echoAction "Enabling UFW and denying all incoming AND outgoing"
(ufw default deny incoming; \
ufw default deny outgoing; \
ufw enable) > /dev/null 2>&1

echoInfo "Run 'ufw disable' to disable the firewall"
