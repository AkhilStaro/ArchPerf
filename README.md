# ArchPerf Installer Script

This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a desktop environment, all the support packages (network, bluetooth, audio, printers, etc.), along with all my preferred applications and utilities. The shell scripts in this repo allow the entire process to be automated.)

## Boot Arch ISO

From initial Prompt type the following commands:

```
pacman -Sy git
git clone https://github.com/AkhilStaro/ArchPerf
cd ArchPerf
./ArchPerf.sh
```

### System Description (My Edits, New Fatures)
This is my edited version of ArchTitus

I've completely removed the kde customization, and added new features:

1. Being able to choose between different audio servers

2. Able to choose between DHClient and NetworkManager

3. The script also asks you if you want to use printer and bluetooth with the device

4. The script also lets you choose which fonts and extra packages you want to install

5. The script also install python and java8 libraries which you might need later to run some applications

6. The scripts have been rewritten in a organised manner and with simplified comments

7. The script only install efibootmgr if you are using uefi.

8. the script has removed all the aur packages because it was pretty much bloat.


The main feature about this is that it removes all the bloat packages including :

cmatrix

cronie

All The Fonts Titus added which were uneeded

The full list of packages this script install :          
mesa            
xorg        
xorg-server            
xorg-apps             
xorg-drivers           
xorg-xkill             
xorg-xinit           
xterm          
binutils           
dosfstools             
linux-headers               
usbutils           
autoconf        
automake       
xdg-user-dirs            
bison             
ntp               
--END OF MINIMAL INSTALL--                
bash-completion           
bridge-utils            
btrfs-progs                        
dialog        
dnsmasq          
dtc          
exfat-utils         
flex           
fuse2         
fuse3              
gcc          
gparted         
gptfdisk       
grub-customizer            
gst-plugins-good           
htop              
libdvdcss            
libtool          
lsof           
lzop        
m4        
make          
neofetch        
ntfs-3g             
ntp             
openbsd-netcat           
openssh       
p7zip            
patch         
pkgconf          
ufw            
unrar          
unzip        
which          
python-notify2         
python-psutil        
python-pyqt5        
python-pip         
java-environment-common           
java-runtime-common           
jbig2dec          
jdk8-openjdk         
jfsutils       
jre8-openjdk
jre8-openjdk-headless             
js78             
json-c           
json-glib             

### Future Features
2. The script will let you choose window managers too
3. The script will let you choose a config to appy on your installation
4. Not sure about this one but, if possible the script will let you clone your own config files from github and alppy them
5. Add my own rice(customization) of Qtile+xfce hybrid

### No Wifi

You can check if the WiFi is blocked by running `rfkill list`.
If it says **Soft blocked: yes**, then run `rfkill unblock wifi`

After unblocking the WiFi, you can connect to it. Go through these 5 steps:

#1: Run `iwctl`

#2: Run `device list`, and find your device name.

#3: Run `station [device name] scan`

#4: Run `station [device name] get-networks`

#5: Find your network, and run `station [device name] connect [network name]`, enter your password and run `exit`. You can test if you have internet connection by running `ping google.com`, and then Press Ctrl and C to stop the ping test.

## Credits

- Original packages script was a post install cleanup script called ArchMatic located here: https://github.com/rickellis/ArchMatic
- Thank you to all the folks that helped during the creation from YouTube Chat! Here are all those Livestreams showing the creation: <https://www.youtube.com/watch?v=IkMCtkDIhe8&list=PLc7fktTRMBowNaBTsDHlL6X3P3ViX3tYg>
