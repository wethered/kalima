#!/usr/bin/env bash

# These should be enabled I guess,
# but they are too much of a pain to implement since we rely on errors.

# set -o errexit
# set -o pipefail
# set -o nounset

# Check sudo
sudo -v

# Source necessary constants and functions
working_dir=$(dirname "$(readlink -f "$0")")
install_path="/usr/share/kalima"
user_path="$HOME/.config/kalima"
bin_path="/usr/bin/kalima"

##
# Options
##

# Set up verbose output
# Usage:
#   echo "verbose" >&3
#   echo "normal"
verbose=

case "${1:-}" in
-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
    verbose=1
    shift ;;
esac

if [ "$verbose" = 1 ]; then
    exec 4>&2 3>&1
else
    exec 4>/dev/null 3>/dev/null
fi

##
# Functions
##

# Print helpers
print_newline() {
  printf "\n"
}

print_verbose()
{
  echo "$@" >&3
}

print_section()
{
  printf "\e[36m    %s\e[0m\n" "$@"
}

print_action()
{
  printf "\e[32m[+]\e[0m %s\n" "$@"
}

print_error()
{
  printf "\e[31m[!]\e[0m %s\n" "$@"
}

print_info()
{
  printf "\e[33m[i]\e[0m %s\n" "$@"
}

# This functions check the last return code, and return true if it was an error.
# is_error() might have been a better name, but I like check_error better.
function check_error() {
  local return_code="$?"

  if [ "$return_code" -ne 0 ]; then
    return 0
  else
    return 1
  fi
}

function VMWAREmountShare() {
  #Are we in VMWare? -  Mount the VMWare Shared Folders
  if [ "$(which vmhgfs-fuse)" ]; then
    [ "$(vmware-hgfsclient)" == "$project_name" ] >&3

    if check_error; then
      print_error "Please make sure '$project_name' is an actual Shared Folder in VMWare."
      exit 1
    else
      [ ! -d  "$project_home" ] && mkdir "$project_home"
      vmhgfs-fuse -o auto_unmount ".host:/$project_name" "$project_home"
      print_action "Mounting $project_home"
      sleep 2

      print_action "Making project file structure @ '$project_home'"
      mkdir -p "$project_home/0_logs/" "$project_home/1_evidence/" "$project_home/2_scripts/" "$project_home/3_downloads/" "$project_home/4_random/" "$project_home/5_notes/" >&3

      print_action "Enabling auto-mount of '$project_home' at boot time"
      (mkdir ~/.config/autostart ; \
      echo "[Desktop Entry]
            Encoding=UTF-8
            Version=0.9.4
            Type=Application
            Name=vmhgfs-fuse
            Comment=VMWare Shared Folders
            Exec=vmhgfs-fuse -o auto_unmount \".host:/$project_name\" \"$project_home\"
            OnlyShowIn=XFCE;
            RunHook=0
            StartupNotify=false
            Terminal=false
            Hidden=false" > ~/.config/autostart/vmhgfs-fuse.desktop) >&3

      if check_error; then
        print_error "Auto-mount could not be enabled"
      fi
    fi
  else
    print_error "This project was designed with VMWare in mind, if you're using something else tweak the code! I'm going to give up now..."
    exit 1
  fi
}

function customizeXFCE() {
  print_info "This is XFCE"
    
  print_action "Configuring screen recording"
  mkdir $HOME/.config/kazam
  echo "[DEFAULT]
default = <Section: DEFAULT>

[main]
video_toggled = True
video_source = 0
audio_toggled = False
audio_source = 0
audio_volume = 0
audio2_toggled = False
audio2_source = 0
audio2_volume = 0
codec = 2
counter = 5.0
capture_cursor = True
capture_microphone = False
capture_speakers = False
capture_cursor_pic = True
capture_borders_pic = True
framerate = 15.0
countdown_splash = True
last_x = 60
last_y = 31
advanced = 0
silent = 0
autosave_video = True
autosave_video_dir = $(cat $install_path/project_home)/1_evidence
autosave_video_file = Kazam_screencast
autosave_picture = False
autosave_picture_dir = 
autosave_picture_file = Kazam_screenshot
shutter_sound = True
shutter_type = 0
first_run = False

[keyboard_shortcuts]
pause = <Shift><Control>p
finish = <Shift><Control>f
show = <Shift><Control>s
quit = <Shift><Control>q " > $HOME/.config/kazam/kazam.conf

	

  print_action "Configuring screenshots"
  xfconf-query -c xfce4-keyboard-shortcuts  -p /commands/custom/Print -s "xfce4-screenshooter -r -o $install_path/scripts/screenshot"

  # Replace the default terminal emulator with terminator
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
  Icon=kalima" > ~/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop

  echo "TerminalEmulator=custom-TerminalEmulator" > ~/.config/xfce4/helpers.rc
  echo "false" > "$user_path/record_session"
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/image-style -s 0
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/color-style -s 0
  xfconf-query -c xfce4-desktop --create -p /backdrop/screen0/monitorVirtual1/workspace0/rgba1 -s 0.000000 -s 0.000000 -s 0.000000 -s 1.000000  -t string -t string -t string  -t string
}

function customizeGnome() {
  print_info "This is GNOME"
  print_action "Configuring screenshots"
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

  print_action "Configuring screen recording"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/pipeline "'vp9enc min_quantizer=0 max_quantizer=5 cpu-used=3 deadline=1000000 threads=%T ! queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 ! webmmux'"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/file-resolution-height "480"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/active-custom-gsp "true"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/file-resolution-width "640"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/quality-index "0"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/file-resolution-type "999"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/fps "3"
  dconf write /org/gnome/shell/extensions/EasyScreenCast/file-folder "'$project_home/1_evidence/'"

  print_action "Performing last changes to shell"
  dconf write /org/gnome/shell/favorite-apps "['org.gnome.Nautilus.desktop', 'firefox-esr.desktop', 'terminator.desktop', 'sublime_text.desktop']"
  dconf write /org/gnome/desktop/background/picture-uri "'file:///usr/share/backgrounds/gnome/Dark_Ivy.jpg'"
}

##
# Start building...
##

print_section "===== + Building + ====="

# Ensure this is the right kali version (2020.2)
if [ "$(lsb_release -r | awk -F" " '{ print $2 }')" ==  "2020.2" ]; then
  print_verbose "This is Kali 2020.2..."
else
  print_error "This has been tested on Kali 2020.1 only... bye!"
  exit 1
fi

# Running apt update
print_action "Performing 'apt update'"
sudo apt-get -y update >&3

# Creating script structure
if [ ! -d "${install_path}" ]; then
  print_action "Creating script structure @ '$install_path'";
  sudo mkdir $install_path >&3
  sudo cp -R "${working_dir}/scripts" $install_path >&3
fi

if [ ! -d "${user_path}" ]; then
  print_action "Creating config @ '$user_path'";
  mkdir -p $user_path >&3
fi

# We need this, so Gyarados can check if we are in undercover mode.
touch $HOME/.face

print_action "Asking bootstrap questions"

# Get project name
if [ ! -f "${install_path}/project_name" ]; then
  read -p 'Project codename: ' project_name 
  sudo bash -c "echo $project_name > $install_path/project_name"

  project_home=$HOME/$project_name
  sudo bash -c "echo $project_home > $install_path/project_home"
else
  project_name=$(cat $install_path/project_name)
  project_home=$(cat $install_path/project_home)
fi

# Get hostname
if [ ! -f "${install_path}/kalima_hostname" ]; then
  read -p 'Kali hostname: ' hostnameVar
  sudo bash -c "echo $hostnameVar > $install_path/kalima_hostname"
else
  hostnameVar=$(cat $install_path/kalima_hostname)
fi

# Get CobaltStrike license key
if [ ! -f "${HOME}/.cobaltstrike.license" ]; then
  read -p 'Cobalt Strike key: ' CSKEY
  echo "$CSKEY" > ~/.cobaltstrike.license
else
  CSKEY=$(cat ~/.cobaltstrike.license)
fi

# Prompt for password change if we haven't already changed it
if [ "$(sudo chage -li "$USER" | grep "Last password change" | awk -F":" '{print $2}' | xargs)" != "$(date '+%Y-%m-%d')" ]; then
  sudo passwd "$USER"
fi

# Create kalima script loader
print_action "Creating script loader @ '$bin_path'"

echo "#!/bin/bash
function usage() {
  echo \"
  Kalima - Evil Evil stuff!

  Usage: \$0 [options]

OPTIONS:
\"
cd $install_path/scripts
ls -1A | while read file; do echo -e \"\$file \n\t \$(grep \"#DESCRIPTION:\" \$file | sed 's/#DESCRIPTION: //g')\";done
cd - > /dev/null 2>&1
}
if [ -f $install_path/scripts/\$1 ] 
  then
    bash $install_path/scripts/\$@
  else
    usage
    exit 1
fi
" > "${working_dir}/kalima-script.sh"
sudo bash -c "mv $working_dir/kalima-script.sh $bin_path"
sudo chmod +x $bin_path

# Clean up unnecessary directories and add useful ones
print_action "Cleaning up useless directories"
rm -rf ~/Desktop ~/Documents ~/Music ~/Pictures ~/Public ~/Templates ~/Videos >&3
mkdir -p ~/Tools ~/Tools/nse >&3

# Check if project_home is mounted and mount it if necessary
print_action "Checking if project folder is mounted"
(mount | grep -o "$project_name") > /dev/null 2>&1

if check_error; then
  print_verbose "It wasn't mounted. Let's mount it!"
  VMWAREmountShare
 else
  print_action "All data should be stored under $project_home."
fi


# Install Sublime Text 3
if [ "$(which subl)" == "" ]; then
  print_action "Installing Sublime Text 3"

  (curl -sSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -; \
  sudo apt-get install apt-transport-https; \
  sudo bash -c "echo 'deb https://download.sublimetext.com/ apt/stable/' > /etc/apt/sources.list.d/sublime-text.list"; \
  sudo apt-get update; \
  sudo apt-get install sublime-text) >&3

  if check_error; then
     print_error "Sublime Text 3 could not be installed"
  fi
else
  print_info "Sublime Text 3 is already installed, skipping..."
fi

# Installing Oracle Java 8
if [ ! -d /opt/java ]; then
  print_action "Installing Oracle Java 8"

  (sudo mkdir -p /opt/java; \
  curl -Lo java.tgz "$(curl -s https://www.java.com/en/download/linux_manual.jsp | grep -E ".*x64.*javadl" | grep -v "RPM" | sed "s/.*href=\"//g;s/\".*//g" | head -n 1)" 2>&1 ; \
  tar xzf java.tgz; \
  javaver="$(tar tf java.tgz | head -n1 | tr -d "/")"; \
  sudo mv "$javaver" /opt/java; \
  sudo update-alternatives --install "/usr/bin/java" "java" "/opt/java/$javaver/bin/java" 1; \
  sudo update-alternatives --set java "/opt/java/$javaver/bin/java";rm java.tgz) >&3

  if check_error; then
     print_error "Java could not be installed"
  fi
else
  print_info "Oracle Java 8 is already installed, skipping..."
fi

# Installing CobaltStrike
if [[ $CSKEY =~ ^.{4}-.{4}-.{4}-.{4}$ ]]; then
  if [ ! -d ~/Tools/cobaltstrike ]; then
    print_action "Installing Cobalt Strike"

    (curl -L "https://www.cobaltstrike.com$(curl -s 'https://www.cobaltstrike.com/download' -XPOST -H 'Referer: https://www.cobaltstrike.com/download' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://www.cobaltstrike.com' -H 'Host: www.cobaltstrike.com' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Connection: keep-alive' -H 'Accept-Language: en-us' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/604.3.5 (KHTML, like Gecko) Version/11.0.1 Safari/604.3.5' --data "dlkey=$CSKEY" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep /downloads/ | cut -d '.' -f 1).tgz" -o cobaltstrike.tgz 2>&1 && \
    tar xzf cobaltstrike.tgz -C ~/Tools/ && \
    rm cobaltstrike.tgz && \
    cd ~/Tools/cobaltstrike && ./update 2>&1 && cd -) >&3

    if check_error; then
       print_error "Cobalt Strike could not be installed"
       rm cobaltstrike.tgz 2>&3
    fi
  else
    print_info "Cobalt Strike is already installed, skipping..."
  fi
else
  print_error "Invalid Cobalt Strike key, skipping!"
fi

# Installing extra hacking tools
# bettercap, impacket, seclists, asciinema, bloodhound, ufw, vlc, terminator, sslscan, eyewitness, gobuster, pwntools, etc.
if [ "$(which bettercap)" == "" ]; then
  print_action "Installing extra hacking tools"

  (curl -sSL https://raw.githubusercontent.com/hdm/scan-tools/master/nse/banner-plus.nse > ~/Tools/nse/banner-plus.nse; \
  git clone https://github.com/bitsadmin/wesng.git ~/Tools/wesng; \
  sudo apt-get install -y bettercap bettercap-caplets bettercap-ui python3-impacket impacket-scripts seclists libnetfilter-queue1 asciinema python3-setuptools python3-distutils python3-pip bloodhound vlc ufw xclip terminator crackmapexec sslyze sslscan eyewitness gobuster build-essential >&3; \
  sudo pip3 -q install pwntools; \
  sudo sed -i 's/geteuid/getppid/' /usr/bin/vlc) 2>&3

  if check_error; then
     print_error "Hacking Tools could not be installed"
  fi
else
  print_info "Hacking tools are already installed, skipping..."
fi

# Installing fish shell
# fish, tmux, mosh, etc.
if [ "$(which fish)" == "" ]; then
  print_action "Installing Fish Shell"

  (sudo apt-get -y update >&3 && \
   sudo apt-get install git fish python2 python3 curl tmux mosh golang pipenv python3-pip -y >&3 && \
   sudo pip3 -q install virtualfish && \
   sudo chsh -s /usr/bin/fish "$USER") 2>&3

  if check_error; then
     print_error "Fish Shell could not be installed"
  fi

else
  print_info "Fish Shell is already installed, skipping..."
fi

# Installing Oh-My-Fish
if [ ! -d ~/.config/omf/ ]; then
  print_action "Installing Oh-My-Fish"

  (git clone https://github.com/oh-my-fish/oh-my-fish /tmp/oh-my-fish && \
  /tmp/oh-my-fish/bin/install --offline --noninteractive --yes >&3 && \
  echo 'set -g VIRTUALFISH_PYTHON "/usr/bin/python3"' >>  ~/.config/omf/before.init.fish && echo 'set -g VIRTUALFISH_PLUGINS "auto_activation"' >>  ~/.config/omf/before.init.fish && \
        echo 'set -g VIRTUALFISH_HOME $HOME/.local/share/virtualenvs/' >>  ~/.config/omf/before.init.fish && \
  echo 'set -xg GOPATH $HOME/Tools/go' >>  ~/.config/omf/init.fish && \
  fish -c "omf install extract rvm virtualfish" >&3 ) 2>&3

  if check_error; then
     print_error "Oh-My-Fish could not be installed"
  fi
else
  print_info "Oh-My-Fish is already installed, skipping..."
fi

# Installing Gyarados
if [ "$(fish -c 'omf theme | grep -1 Installed | grep -i gyarados')" == "" ]; then
  print_action "Installing Gyarados Theme (for Oh-My-Fish)"

  (/usr/bin/fish -c "omf install https://github.com/rTD-JP/gyarados" >&3 && \
   /usr/bin/fish -c "omf theme gyarados") >&3

  if check_error; then
     print_error "Gyarados Theme (for Oh-My-Fish) could not be installed"
  fi
else
  print_info "Gyarados Theme (for Oh-My-Fish) already installed"
fi

##
# Start customizing...
##

print_newline
print_section "===== + Customizing + ====="

# Add obey2
if [ ! -f ~/.config/fish/obey2 ]; then
  print_action "Adding Obey2 greeting"

  (cp scripts/obey2 ~/.config/fish/obey2 && echo set fish_greeting >> ~/.config/fish/config.fish;echo "~/.config/fish/obey2" >> ~/.config/fish/config.fish;chmod +x ~/.config/fish/obey2) >&3
  
  if check_error; then
     print_error "Obey2 greeting could not be installed"
  fi
else
  print_info "Obey2 greeting is already installed, skipping..."
fi

# Add terminator profiles
print_action "Configuring terminator"
mkdir -p ~/.config/terminator
echo "[global_config]
  title_transmit_fg_color = \"#2E3440\"
  title_transmit_bg_color = \"#88C0D0\"
  title_receive_fg_color = \"#2E3440\"
  title_receive_bg_color = \"#8FBCBB\"
  title_inactive_fg_color = \"#D8DEE9\"
  title_inactive_bg_color = \"#4C566A\"
[keybindings]
[profiles]
  [[default]]
    background_color = \"#2e3440\"
    cursor_color = \"#D8DEE9\"
    foreground_color = \"#d8dee9\"
    palette = \"#3b4252:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#88c0d0:#e5e9f0:#4c566a:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#8fbcbb:#eceff4\"
    use_custom_command = True
    custom_command = set -l recording (cat $user_path/record_session); if test \"\$recording\" = \"true\"; clear && env ASCIINEMA_REC=1 asciinema rec (cat $install_path/project_home)/1_evidence/screenshot_(date +%F_%H-%M-%S).cast; else; clear && exec fish; end;
  [[New Profile]]
    cursor_color = \"#aaaaaa\"
  [[non-kalima]]
    background_color = \"#2e3440\"
    cursor_color = \"#D8DEE9\"
    foreground_color = \"#d8dee9\"
    palette = \"#3b4252:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#88c0d0:#e5e9f0:#4c566a:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#8fbcbb:#eceff4\"
[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = \"\"
    [[[child1]]]
      type = Terminal
      parent = window0
      profile = default
      directory = /root
[plugins]" > ~/.config/terminator/config

if check_error; then
   print_error "Terminator could not be configured."
fi

# Customize the Window Manager

WMver=$(echo "$XDG_DATA_DIRS" | grep -Eo 'xfce|kde|gnome')

if [ "$WMver" == "xfce" ]; then
  customizeXFCE

elif [ "$WMver" == "gnome" ]; then
  customizeGnome
  
elif [ "$WMver" == "KDE" ]; then
  print_info "There are no customizations for KDE yet."

else
  print_error "Window Manager could not be detected!"  
fi


# Finishing things up
print_action "Randomizing MAC address (on eth0)"
sudo macchanger -r eth0 >&3

print_action "Changing hostname to $hostnameVar"
sudo bash -c "sed -i 's/kali/$hostnameVar/g' /etc/hosts&&echo $hostnameVar > /etc/hostname"

if [ "$verbose" = 1 ]; then
  print_info "All done - Now reboot for all changes to take effect..."
else
  print_info "Rebooting..."
  sudo reboot
fi












