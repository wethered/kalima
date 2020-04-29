#!/bin/bash
echo 

#DESCRIPTION: Creation script for Kalima.

verbose=

case "$1" in
-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
    verbose=1
    shift ;;
esac

if [ "$verbose" = 1 ]; then
    exec 4>&2 3>&1
else
    exec 4>/dev/null 3>/dev/null
fi

# echo "verbose" >&3
# echo "normal"

SCRIPTPATH=$(dirname $(readlink -f $0))
INSTALLPATH="/usr/share/kalima"
BINPATH="/usr/bin/kalima"

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


function VMWAREmountShare () {

  #Are we in VMWare? -  Mount the VMWare Shared Folders
if [ $(which vmhgfs-fuse) ]; then
  ([ $(vmware-hgfsclient) == $project_name ]) >&3
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoError "Please make sure '$project_name' is an actual Shared Folder in VMWare."
     exit
   else
     [ ! -d  $project_home ] && mkdir "$project_home"
     vmhgfs-fuse -o auto_unmount .host:/$project_name $project_home
     echoAction "Mounting $project_home"
     sleep 2
     
     echoAction "Making project file structure @ '$project_home'"
     mkdir -p "$project_home/0_logs/" "$project_home/1_evidence/" "$project_home/2_scripts/" "$project_home/3_downloads/" "$project_home/4_random/" "$project_home/5_notes/" >&3

     echoAction "Enabling auto-mount of '$project_home' at boot time"
(mkdir ~/.config/autostart ; \
 echo "[Desktop Entry]
      Encoding=UTF-8
      Version=0.9.4
      Type=Application
      Name=vmhgfs-fuse
      Comment=VMWare Shared Folders
      Exec=vmhgfs-fuse -o auto_unmount,nonempty .host:/$project_name $project_home
      OnlyShowIn=XFCE;
      RunHook=0
      StartupNotify=false
      Terminal=false
      Hidden=false" > ~/.config/autostart/vmhgfs-fuse.desktop) >&3
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Auto-mount could not be enabled"
fi
  
  fi

else
  echoError "This project was designed with VMWare in mind, if you're using something else tweak the code! I'm going to give up now..."
  exit 1
fi

}


echoSection "===== + Building + ====="

# Check sudo
sudo -v

# ensure this is the right kali version (2020.1)
if [ $(lsb_release -r | awk -F" " '{ print $2 }') ==  "2020.1" ]; then
   echoInfo "This is Kali 2020.1..." >&3
else
   echoError "This has been tested on Kali 2020.1 only... bye!"
   exit 1
fi



echoAction "Performing 'apt update'"
sudo apt-get -y update >&3


if [ ! -d  $INSTALLPATH ]; then
   echoAction "Creating sctipt structure @ '$INSTALLPATH'";
   sudo mkdir $INSTALLPATH >&3
   sudo cp -R $SCRIPTPATH/scripts $INSTALLPATH >&3

fi


echoAction "Asking bootstrap questions"
if [ ! -f $INSTALLPATH/project_name ]; then
   read -p 'Project codename: ' project_name 
   sudo bash -c "echo $project_name > $INSTALLPATH/project_name"
 
   project_home=$HOME/$project_name
   sudo bash -c "echo $project_home > $INSTALLPATH/project_home"
else
   project_name=$(cat $INSTALLPATH/project_name)
   project_home=$(cat $INSTALLPATH/project_home)
fi


if [ ! -f $INSTALLPATH/kalima_hostname ]; then

   read -p 'Kali hostname: ' hostnameVar
   sudo bash -c "echo $hostnameVar > $INSTALLPATH/kalima_hostname"

else
   hostnameVar=$(cat $INSTALLPATH/kalima_hostname)
fi

if [ ! -f ~/.cobaltstrike.license ]; then

   read -p 'Cobalt Strike key: ' CSKEY
   echo $CSKEY > ~/.cobaltstrike.license
else
  CSKEY=$(cat ~/.cobaltstrike.license)
fi

if [ "$(sudo chage -li $USER | grep "Last password change" | awk -F":" '{print $2}' | xargs)" != "$(date '+%Y-%m-%d')" ]; then
   sudo passwd $USER
fi



echoAction "Creating script loader @ '$BINPATH'"

echo "#!/bin/bash
function usage() {
  echo \"
  Kalima - Evil Evil stuff!

  Usage: \$0 [options]

OPTIONS:
\"
cd $INSTALLPATH/scripts
ls -1A | while read file; do echo -e \"\$file \n\t \$(grep \"#DESCRIPTION:\" \$file | sed 's/#DESCRIPTION: //g')\";done
cd - > /dev/null 2>&1
}
if [ -f $INSTALLPATH/scripts/\$1 ] 
  then
    bash $INSTALLPATH/scripts/\$@
  else
    usage
    exit 1
fi
" > $SCRIPTPATH/kalima-script.sh
sudo bash -c "mv $SCRIPTPATH/kalima-script.sh $BINPATH"
sudo chmod +x $BINPATH

echoAction "Cleaning up useless directories"
rm -rf ~/Desktop ~/Documents ~/Music ~/Pictures ~/Public ~/Templates ~/Videos >&3
mkdir -p ~/Tools ~/Tools/nse >&3


(mount | grep -o $project_name) > /dev/null 2>&1
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     VMWAREmountShare
   else
     echoAction "All data should be stored under $project_home."
  fi


if [ "$(which subl)" == "" ]; then
echoAction "Installing Sublime Text 3"
  (curl -sSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -; \
  sudo apt-get install apt-transport-https; \
  sudo bash -c "echo 'deb https://download.sublimetext.com/ apt/stable/' > /etc/apt/sources.list.d/sublime-text.list"; \
  sudo apt-get update; \
  sudo apt-get install sublime-text) >&3
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoError "Sublime Text 3 could not be installed"
  fi
else
  echoInfo "Sublime Text 3 already installed"
fi



if [ ! -d /opt/java ]; then
  echoAction "Installing Oracle Java 8"
  (sudo mkdir -p /opt/java; \
  curl -Lo java.tgz $(curl -s https://www.java.com/en/download/linux_manual.jsp | grep -E ".*x64.*javadl" | grep -v "RPM" | sed "s/.*href=\"//g;s/\".*//g" | head -n 1) 2>&1 ; \
  tar xzf java.tgz; \
  javaver="$(tar tf java.tgz | head -n1 | tr -d "/")"; \
  sudo mv $javaver /opt/java; \
  sudo update-alternatives --install "/usr/bin/java" "java" "/opt/java/$javaver/bin/java" 1; \
  sudo update-alternatives --set java /opt/java/$javaver/bin/java;rm java.tgz) >&3
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoError "Java could not be installed"
  fi
else
  echoInfo "Oracle Java 8 already installed"
fi

if [[ $CSKEY =~ ^.{4}-.{4}-.{4}-.{4}$ ]]; then

  if [ ! -d ~/Tools/cobaltstrike ]; then
    echoAction "Installing Cobalt Strike"
    (curl -L https://www.cobaltstrike.com$(curl -s 'https://www.cobaltstrike.com/download' -XPOST -H 'Referer: https://www.cobaltstrike.com/download' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://www.cobaltstrike.com' -H 'Host: www.cobaltstrike.com' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Connection: keep-alive' -H 'Accept-Language: en-us' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/604.3.5 (KHTML, like Gecko) Version/11.0.1 Safari/604.3.5' --data "dlkey=$CSKEY" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep /downloads/ | cut -d '.' -f 1).tgz -o cobaltstrike.tgz 2>&1 && \
    tar xzf cobaltstrike.tgz -C ~/Tools/ && \
    rm cobaltstrike.tgz && \
    cd ~/Tools/cobaltstrike && ./update 2>&1 && cd -) >&3
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
       echoError "Cobalt Strike could not be installed"
       rm cobaltstrike.tgz 2>&3
    fi
  else
    echoInfo "Cobalt Strike already installed"
  fi
else
  echoError "Invalid Cobalt Strike key. skipping!"
fi

if [ "$(which bettercap)" == "" ]; then

  echoAction "Installing extra hacking tools"
  (curl -sSL https://raw.githubusercontent.com/hdm/scan-tools/master/nse/banner-plus.nse > ~/Tools/nse/banner-plus.nse; \
  git clone https://github.com/bitsadmin/wesng.git ~/Tools/wesng; \
  sudo apt-get install -y bettercap bettercap-caplets bettercap-ui python3-impacket impacket-scripts seclists libnetfilter-queue1 asciinema python3-setuptools python3-distutils python3-pip bloodhound vlc ufw xclip terminator crackmapexec sslyze sslscan eyewitness gobuster build-essential >&3; \
  sudo pip3 -q install pwntools; \
  sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc) 2>&3
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoError "Hacking Tools could not be installed"
  fi
else
  echoInfo "Hacking tools already installed"
fi

if [ "$(which fish)" == "" ]; then
  echoAction "Installing Fish Shell" 
  (sudo apt-get -y update >&3 && \
   sudo apt-get install git fish python2 python3 curl tmux mosh golang pipenv python3-pip -y >&3 && \
   sudo pip3 -q install virtualfish && \
   sudo chsh -s /usr/bin/fish $USER) 2>&3
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
     echoError "Fish Shell could not be installed"
  fi

else
  echoInfo "Fish Shell already installed"
fi

exit 1


echoAction "Installing Oh-My-Fish"
(git clone -q https://github.com/oh-my-fish/oh-my-fish /tmp/oh-my-fish && /tmp/oh-my-fish/bin/install --offline --noninteractive --yes && echo 'set -g VIRTUALFISH_PYTHON "/usr/bin/python"' >>  /root/.config/omf/before.init.fish && echo 'set -g VIRTUALFISH_PLUGINS "auto_activation"' >>  /root/.config/omf/before.init.fish && echo 'set -g VIRTUALFISH_HOME $HOME/.local/share/virtualenvs/' >>  /root/.config/omf/before.init.fish && echo "set -xg GOPATH $HOME/Tools/go" >>  /root/.config/omf/init.fish && fish -c "omf install extract rvm virtualfish") > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Oh-My-Fish could not be installed"
fi

echoAction "Installing Gyarados (Theme) for Oh-My-Fish"
(/usr/bin/fish -c "omf install https://github.com/rTD-JP/gyarados" && /usr/bin/fish -c "omf theme gyarados") > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Gyarados could not be installed"
fi


echoSection "===== + Customizing + ====="

echoAction "Adding Obey2 greeting"
(cp scripts/obey2 ~/.config/fish/obey2 && echo set fish_greeting >> ~/.config/fish/config.fish;echo "~/.config/fish/obey2" >> ~/.config/fish/config.fish;chmod +x ~/.config/fish/obey2) > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Obey2 could not be installed"
fi



echoAction "Configuring terminator"
mkdir -p ~/.config/terminator
echo "[global_config]
[keybindings]
[profiles]
  [[default]]
    cursor_color = \"#aaaaaa\"
    use_custom_command = True
    custom_command = set -l recording (cat ~/.config/kalima/record_session); if test \"\$recording\" = \"true\"; clear && env ASCIINEMA_REC=1 asciinema rec (cat ~/.config/kalima/project_home)/1_evidence/screenshot_(date +%F_%H-%M-%S).cast; else; clear && exec fish; end;
  [[non-kalima]]
    cursor_color = \"#aaaaaa\"
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = Terminal
      parent = window0
      profile = default
      directory = /root
[plugins]" > ~/.config/terminator/config

ERROR=$?
if [ $ERROR -ne 0 ]; then
   echoError "Terminator could not be configured."
fi




WMver=$(echo "$XDG_DATA_DIRS" | grep -Eo 'xfce|kde|gnome')

if [ $WMver == "xfce" ]; then
    echoInfo "This is XFCE"
    
    echoAction "Configuring screen recording"
    sed -i "s,autosave_video_dir.*$,autosave_video_dir = $(cat ~/.config/kalima/project_home)/1_evidence/,g" ~/.config/kazam/kazam.conf
    sed -i 's/autosave_video =.*$/autosave_video = True/' ~/.config/kazam/kazam.conf

    echoAction "Configuring screenshots"
    xfconf-query -c xfce4-keyboard-shortcuts  -p /commands/custom/Print -s "xfce4-screenshooter -r -o /root/.config/kalima/scripts/screenshot"

    mkdir -p ~/.local/share/xfce4/helpers
    echo "[Desktop Entry]
    NoDisplay=true
    Version=1.0
    Encoding=UTF-8
    Type=X-XFCE-Helper
    X-XFCE-Category=TerminalEmulator
    X-XFCE-CommandsWithParameter=/usr/bin/terminator \"%s\"
    Name=kalima
    X-XFCE-Commands=/usr/bin/terminator
    Icon=kalima" > /root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop

    echo "TerminalEmulator=custom-TerminalEmulator" > /root/.config/xfce4/helpers.rc
    echo "false" > ~/.config/kalima/record_session
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/image-style -s 0
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/color-style -s 0
    xfconf-query -c xfce4-desktop --create -p /backdrop/screen0/monitorVirtual1/workspace0/rgba1 -s 0.000000 -s 0.000000 -s 0.000000 -s 1.000000  -t string -t string -t string  -t string

  elif [ $WMver == "gnome" ]; then
    echoInfo "This is GNOME"
    echoAction "Configuring screenshots"
    dconf write /org/gnome/gnome-screenshot/auto-save-directory "'file:///$project_home/1_evidence/'"
    dconf write /org/gnome/gnome-screenshot/last-save-directory "'file:///$project_home/1_evidence/'"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/screencast "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/screenshot "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/screenshot-clip "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/window-screenshot "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/window-screenshot-clip "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/area-screenshot-clip "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/area-screenshot "''"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'gnome-screenshot -a'"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'Print'"
    dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'custom-screenshot'"

    echoAction "Configuring screen recording"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/pipeline "'vp9enc min_quantizer=0 max_quantizer=5 cpu-used=3 deadline=1000000 threads=%T ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 ! webmmux'"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/file-resolution-height "480"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/active-custom-gsp "true"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/file-resolution-width "640"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/quality-index "0"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/file-resolution-type "999"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/fps "3"
    dconf write /org/gnome/shell/extensions/EasyScreenCast/file-folder "'$project_home/1_evidence/'"

    echoAction "Performing last changes to shell"
    dconf write /org/gnome/shell/favorite-apps "['org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'terminator.desktop', 'sublime_text.desktop']"
    dconf write /org/gnome/desktop/background/picture-uri "'file:///usr/share/backgrounds/gnome/Dark_Ivy.jpg'"

    
  elif [ $WMver == "KDE" ]; then
    echoInfo "There are no customizations for KDE yet."
  
  else
    echoError "Window Manager could not be detected!"  
    
fi

echoAction "Randomizing MAC address (on eth0)"
sudo macchanger -r eth0 >&3

echoAction "Changing hostname to $hostameVar"
sudo bash -c "sed -i 's/kali/$hostnameVar/g' /etc/hosts&&echo $hostnameVar > /etc/hostname"

if [ "$verbose" = 1 ]; then
    echoInfo "All done - Now reboot for all changes to take effect..."
else
    echoInfo "Rebooting..."
fi


