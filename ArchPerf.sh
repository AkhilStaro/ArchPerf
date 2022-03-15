#!/bin/bash

# Find Script Directories
set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/scripts
CONFIGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/configs
set +a
echo -ne "
----------------------------------------------------
     _    ____   ____ _   _ ____  _____ ____  _____ 
    / \  |  _ \ / ___| | | |  _ \| ____|  _ \|  ___|
   / _ \ | |_) | |   | |_| | |_) |  _| | |_) | |_   
  / ___ \|  _ <| |___|  _  |  __/| |___|  _ <|  _|  
 /_/   \_\_| \_\\____|_| |_|_|   |_____|_| \_\_|    
----------------------------------------------------
	     Nice Arch Linux Installer
----------------------------------------------------
"
( bash $SCRIPT_DIR/scripts/ask.sh )|& tee ask.log
      source $CONFIGS_DIR/user_pref.conf
    ( bash $SCRIPT_DIR/scripts/0-preinstall.sh )|& tee 0-preinstall.log
    ( arch-chroot /mnt $HOME/ArchTitus/scripts/1-setup.sh )|& tee 1-setup.log
    if [[ ! $DESKTOP_ENV == server ]]; then
      ( arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/ArchTitus/scripts/2-user.sh )|& tee 2-user.log
    fi
    ( arch-chroot /mnt $HOME/ArchTitus/scripts/3-post-setup.sh )|& tee 3-post-setup.log
    cp -v *.log /mnt/home/$USERNAME

echo -ne "
----------------------------------------------------
     _    ____   ____ _   _ ____  _____ ____  _____ 
    / \  |  _ \ / ___| | | |  _ \| ____|  _ \|  ___|
   / _ \ | |_) | |   | |_| | |_) |  _| | |_) | |_   
  / ___ \|  _ <| |___|  _  |  __/| |___|  _ <|  _|  
 /_/   \_\_| \_\\____|_| |_|_|   |_____|_| \_\_|    
----------------------------------------------------
	     Nice Arch Linux Installer
----------------------------------------------------
  Arch Installed - Eject Install Media And Reboot
"