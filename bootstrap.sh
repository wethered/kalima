#!/bin/bash

# ensure running as root, if not, sudo and execute script again
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
fi

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

echoSection "===== + Building + ====="

echoInfo "Performing 'apt update'"
apt -qqq -y update

echoAction "Setting Hi-DPI"
gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "[{'Gdk/WindowScalingFactor', <2>}]"
gsettings set org.gnome.desktop.interface scaling-factor 2

echoInfo "Asking bootstrap questions"
read -p 'Kali hostname: ' hostnameVar&&sed -i 's/kali/$hostnameVar/g' /etc/hosts&&echo $hostnameVar > /etc/hostname
read -p 'Cobalt Strike key: ' CSKEY
passwd


echoAction "Cleaning up useless directories"
rm -rf ~/Documents ~/Music ~/Pictures ~/Public ~/Templates ~/Videos    



echoAction "Installing Oracle Java 8"
(wget -q -O java.tgz $(curl -s https://www.java.com/en/download/linux_manual.jsp | grep -E ".*x64.*javadl" | grep -v "RPM" | sed "s/.*href=\"//g;s/\".*//g" | head -n 1) && tar xzf java.tgz;javaver="$(tar tf java.tgz | head -n1 | tr -d "/")";[ ! -d /opt/java ] && mkdir /opt/java;mv $javaver /opt/java;update-alternatives --install "/usr/bin/java" "java" "/opt/java/$javaver/bin/java" 1;update-alternatives --set java /opt/java/$javaver/bin/java;rm java.tgz) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Java could not be installed."
fi


echoAction "Installing Cobalt Strike"
(echo $CSKEY > ~/.cobaltstrike.license;wget -q https://www.cobaltstrike.com$(curl -s 'https://www.cobaltstrike.com/download' -XPOST -H 'Referer: https://www.cobaltstrike.com/download' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://www.cobaltstrike.com' -H 'Host: www.cobaltstrike.com' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Connection: keep-alive' -H 'Accept-Language: en-us' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/604.3.5 (KHTML, like Gecko) Version/11.0.1 Safari/604.3.5' --data "dlkey=$CSKEY" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep /downloads/ | cut -d '.' -f 1).tgz -O cobaltstrike.tgz;[ ! -d ~/Tools ] && mkdir ~/Tools;tar xzf cobaltstrike.tgz -C ~/Tools/ && rm cobaltstrike.tgz && cd ~/Tools/cobaltstrike && ./update && cd - 2>&1>/dev/null) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Cobalt Strike could not be installed."
   rm cobaltstrike.tgz
fi

echoAction "Installing various hacking tools"
(git clone -q https://github.com/SecureAuthCorp/impacket.git ~/Tools/impacket;cd ~/Tools/impacket/;python setup.py install --quiet;cd - 2>&1 >/dev/null; \
pip3 -q install pwntools; \
DEBIAN_FRONTEND=noninteractive apt -qqq install -y bloodhound vlc ufw xclip terminator  crackmapexec sslyze sslscan eyewitness gobuster build-essential; \
wget -q -O bettercap2.zip https://github.com$(curl -Ls https://github.com/bettercap/bettercap/releases/latest | grep -E -o '/bettercap/bettercap/releases/download/v[0-9.*]+/bettercap_linux_amd64_v[0-9.*]+zip' | head -n 1);[ ! -d ~/Tools/bettercap ] && mkdir ~/Tools/bettercap;unzip -qq bettercap2.zip -d ~/Tools/bettercap/;rm -rf bettercap2.zip;git clone -q https://github.com/bettercap/caplets.git ~/Tools/bettercap/caplets; \
sed -i 's/geteuid/getppid/' /usr/bin/vlc) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Hacking Tools could not be installed."
fi


echoAction "Installing Sublime Text 3"
(wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -;apt -qqq install apt-transport-https;echo "deb https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list;apt -qqq update;apt -qqq install sublime-text) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Sublime Text 3 could not be installed."
fi



echoAction "Installing Fish & Oh-My-Fish"
(apt -qqq update&&apt -qqq install git fish python2 python3 curl tmux mosh golang pipenv python-pip -y && pip -q install virtualfish && gpg --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && curl -sSL https://get.rvm.io | bash -s stable && curl -s https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish && /usr/bin/fish -c "fisher add kennethreitz/fish-pipenv" && echo "set pipenv_fish_fancy yes" >> /root/.config/fish/config.fish && git clone -q https://github.com/oh-my-fish/oh-my-fish /tmp/oh-my-fish && /tmp/oh-my-fish/bin/install --offline --noninteractive --yes && echo 'set -g VIRTUALFISH_PYTHON "/usr/bin/python"' >>  /root/.config/omf/before.init.fish && echo 'set -g VIRTUALFISH_PLUGINS "auto_activation"' >>  /root/.config/omf/before.init.fish && echo 'set -g VIRTUALFISH_HOME $HOME/.local/share/virtualenvs/' >>  /root/.config/omf/before.init.fish && echo "set -xg GOPATH $HOME/Tools/go" >>  /root/.config/omf/init.fish && /usr/bin/fish -c "omf install mars extract rvm virtualfish" && chsh -s /usr/bin/fish) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Fish could not be installed."
fi


echoAction "Adding Obey2 greeting"
(cp scripts/obey2 ~/.config/fish/obey2 && echo set fish_greeting >> ~/.config/fish/config.fish;echo "~/.config/fish/obey2" >> ~/.config/fish/config.fish;chmod +x ~/.config/fish/obey2) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Obey2 could not be installed."
fi

echoAction "Performing last changes to shell"
dconf write /org/gnome/shell/favorite-apps "['org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'terminator.desktop', 'sublime_text.desktop']"
dconf write /org/gnome/desktop/background/picture-uri "'file:///usr/share/backgrounds/gnome/Dark_Ivy.jpg'"

echoInfo "Goodbye!"
sleep 3;reboot
