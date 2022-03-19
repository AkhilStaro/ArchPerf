#!/usr/bin/env bash
echo -ne "
----------------------------------------------------
     _    ____   ____ _   _ ____  _____ ____  _____ 
    / \  |  _ \ / ___| | | |  _ \| ____|  _ \|  ___|
   / _ \ | |_) | |   | |_| | |_) |  _| | |_) | |_   
  / ___ \|  _ <| |___|  _  |  __/| |___|  _ <|  _|  
 /_/   \_\_| \_\\____|_| |_|_|   |_____|_| \_\_|    
----------------------------------------------------
	     Nice Arch Linux Installer
               SCRIPTHOME : ArchPerf
"

echo -ne "
----------------------------------------------------
               Installing AUR Helper
----------------------------------------------------
"
source $HOME/ArchPerf/configs/user_pref.conf

sed -n '/'$INSTALL_TYPE'/q;p' ~/ArchPerf/pkg-files/${DESKTOP_ENV}.txt | while read line
do
  if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]
  then
    # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
    continue
  fi
  echo "INSTALLING: ${line}"
  sudo pacman -S --noconfirm --needed ${line}
done


if [[ ! $AUR_HELPER == none ]]; then
  cd ~
  git clone "https://aur.archlinux.org/$AUR_HELPER.git"
  cd ~/$AUR_HELPER
  makepkg -si --noconfirm
  # sed $INSTALL_TYPE is using install type to check for MINIMAL installation, if it's true, stop
  # stop the script and move on, not installing any more packages below that line
  sed -n '/'$INSTALL_TYPE'/q;p' ~/ArchPerf/pkg-files/aur-pkgs.txt | while read line
  do
    if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
      # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
      continue
    fi
    echo "INSTALLING: ${line}"
    $AUR_HELPER -S --noconfirm --needed ${line}
  done
fi

export PATH=$PATH:~/.local/bin

# Theming DE if user chose FULL installation
if [[ $INSTALL_TYPE == "FULL" ]]; then
  if [[ $DESKTOP_ENV == "openbox" ]]; then
    cd ~
    git clone https://github.com/stojshic/dotfiles-openbox
    ./dotfiles-openbox/install-titus.sh
  fi
fi

echo -ne "
-------------------------------------------------------------------------
           Installing your desired shell and making it default
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed ${FAV_SHELL}
chsh -s /usr/bin/$FAV_SHELL

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
exit
