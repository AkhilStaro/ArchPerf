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
----------------------------------------------------
"

source $HOME/ArchPerf/configs/install_conf.conf

echo -ne "
-------------------------------------------------------------------------
                           Network Setup 
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed ${NETWORK_SET}

if [[  ${NETWORK_SET} == NetworkManager ]]; then
  sudo pacman -S -noconfirm --needed networkmanager network-manager-applet
  systemctl enable --now NetworkManager
fi

if [[  ${NETWORK_SET} == Dhclient ]]; then
  netdevice=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}')
  pacman -S -noconfirm --needed dhclient
  systemctl enable --now dhclient@"$netdevice"
echo -ne "Your dhclient might need some configuration, for now the script has only turned on the dhc service"
fi

echo -ne "
-------------------------------------------------------------------------
                           Bluetooth Setup
-------------------------------------------------------------------------
"
if [[  ${BLUETOOTH} == Yes ]]; then
  sudo pacman -S -noconfirm --needed bluez bluez-libs bluez-utils
  systemctl enable --now bluetooth
fi

echo -ne "
-------------------------------------------------------------------------
                            Audio Setup
-------------------------------------------------------------------------
"
if [[  ${AUDIO_SERV} == pipewire ]]; then
  pacman -S -noconfirm --needed pipewire pipewire-pule pipewire-alsa pipewire-media-session
  systemctl --user enable --now pipewire
  systemctl --user enable --now pipewire-pulse.service
  systemctl --user enable --now pipewire-pulse.socket
else
  pacman -S --noconfirm --needed pulseaudio pulseaudio-bluetooth pulseaudio-alsa pulseaudio-lirc pulseaudio-zeroconf pavucontrol

  systemctl --user enable --now pulseaudio
fi

echo -ne "
-------------------------------------------------------------------------
                           Printing Setup
-------------------------------------------------------------------------
"
if [[  ${PRINTING} == Yes ]]; then
  sudo pacman -S -noconfirm --needed cups
  systemctl enable --now cups
fi

if [[  ${DUALBOOT} == Yes ]]; then
echo -ne "
-------------------------------------------------------------------------
                            DualBoot Setup
-------------------------------------------------------------------------
"
  sudo pacman -S -noconfirm --needed os-prober
fi

echo -ne "
-------------------------------------------------------------------------
                    Setting up mirrors for optimal download 
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed pacman-contrib curl
pacman -S --noconfirm --needed reflector rsync grub arch-install-scripts git
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

nc=$(grep -c ^processor /proc/cpuinfo)
echo -ne "
-------------------------------------------------------------------------
                    You have " $nc" cores. And
			changing the makeflags for "$nc" cores. Aswell as
				changing the compression settings.
-------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi

echo -ne "
-------------------------------------------------------------------------
                    Setup Language to US and set locale  
-------------------------------------------------------------------------
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
# Set keymaps
localectl --no-ask-password set-keymap ${KEYMAP}

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

echo -ne "
-------------------------------------------------------------------------
                    Installing Base System  
-------------------------------------------------------------------------
"
# sed $INSTALL_TYPE is using install type to check for MINIMAL installation, if it's true, stop
# stop the script and move on, not installing any more packages below that line
if [[ ! $DESKTOP_ENV == server ]]; then
  sed -n '/'$INSTALL_TYPE'/q;p' $HOME/ArchPerf/pkg-files/pacman-pkgs.txt | while read line
  do
    if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
      # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
      continue
    fi
    echo "INSTALLING: ${line}"
    sudo pacman -S --noconfirm --needed ${line}
  done
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing Microcode
-------------------------------------------------------------------------
"
# determine processor type and install microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi

echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"
# Graphics Drivers find and install
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed nvidia xf86-video-noveau libva-mesa-driver
	nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed xf86-video-amdgpu xf86-video-ati vulkan-radeon libva-mesa-driver
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed libva-intel-driver vulkan-intel intel-media-driver
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --needed --noconfirm libva-intel-driver vulkan-intel intel-media-driver
fi

#SETUP IS WRONG THIS IS RUN
if ! source $HOME/ArchPerf/configs/user_pref.conf; then
	# Loop through user input until the user gives a valid username
	while true
	do 
		read -p "Please enter username:" username
		# username regex per response here https://unix.stackexchange.com/questions/157426/what-is-the-regex-to-validate-linux-users
		# lowercase the username to test regex
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then 
			break
		fi 
		echo "Incorrect username."
	done 
# convert name to lowercase before saving to user_pref.conf
echo "username=${username,,}" >> ${HOME}/ArchPerf/configs/user_pref.conf

    #Set Password
    read -p "Please enter password:" password
echo "password=${password,,}" >> ${HOME}/ArchPerf/configs/user_pref.conf

    # Loop through user input until the user gives a valid hostname, but allow the user to force save 
	while true
	do 
		read -p "Please name your machine:" name_of_machine
		# hostname regex (!!couldn't find spec for computer name!!)
		if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then 
			break 
		fi 
		# if validation fails allow the user to force saving of the hostname
		read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force 
		if [[ "${force,,}" = "y" ]]
		then 
			break 
		fi 
	done 

    echo "NAME_OF_MACHINE=${name_of_machine,,}" >> ${HOME}/ArchPerf/configs/user_pref.conf
fi

echo -ne "
-------------------------------------------------------------------------
                Installing Your Desired Extra Packages
-------------------------------------------------------------------------
"
  sudo pacman -S -noconfirm --needed ${EXPACKAGES}

echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"
if [ $(whoami) = "root"  ]; then 
    echo "$USERNAME created, home directory created, default shell set to /bin/bash"

# use chpasswd to enter $USERNAME:$password
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "$USERNAME password set"

    echo "root:$RPASSWORD" | chpasswd
    echo "root password set"

	cp -R $HOME/ArchPerf /home/$USERNAME/
    chown -R $USERNAME: /home/$USERNAME/ArchPerf
    echo "ArchPerf copied to home directory"

# enter $NAME_OF_MACHINE to /etc/hostname
	echo $NAME_OF_MACHINE > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi
if [[ ${FS} == "luks" ]]; then
# Making sure to edit mkinitcpio conf if luks is selected
# add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
# making mkinitcpio with linux kernel
    mkinitcpio -p linux
fi

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 2-user.sh
-------------------------------------------------------------------------
"