#!/usr/bin/env bash
# This script will ask the user for Their Prefrences

# Generate a Config File Containing The User Settings/Prefrences
# Which Will Be needed Later
SAVE_CONF=$CONFIGS_DIR/install_conf.conf
if [ ! -f $SAVE_CONF ]; then # check for file
    touch -f $SAVE_CONF # create file if not exists
fi

# Set Options In The install_conf.conf File
set_option() {
    if grep -Eq "^${1}.*" $SAVE_CONF; then # check if option exists
        sed -i -e "/^${1}.*/d" $SAVE_CONF # delete option if exists
    fi
    echo "${1}=${2}" >>$SAVE_CONF # add option
}

# Give User A Set Of Options To Select
# Selected Option Can Be Moved With The Arrow Keys And Choosen With Return
select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "$2   $1 "; }
    print_selected()   { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }
    key_input()         {
                        local key
                        IFS= read -rsn1 key 2>/dev/null >&2
                        if [[ $key = ""      ]]; then echo enter; fi;
                        if [[ $key = $'\x20' ]]; then echo space; fi;
                        if [[ $key = "k" ]]; then echo up; fi;
                        if [[ $key = "j" ]]; then echo down; fi;
                        if [[ $key = "h" ]]; then echo left; fi;
                        if [[ $key = "l" ]]; then echo right; fi;
                        if [[ $key = "a" ]]; then echo all; fi;
                        if [[ $key = "n" ]]; then echo none; fi;
                        if [[ $key = $'\x1b' ]]; then
                            read -rsn2 key
                            if [[ $key = [A || $key = k ]]; then echo up;    fi;
                            if [[ $key = [B || $key = j ]]; then echo down;  fi;
                            if [[ $key = [C || $key = l ]]; then echo right;  fi;
                            if [[ $key = [D || $key = h ]]; then echo left;  fi;
                        fi
    }
    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

        curr_idx=$(( $curr_col + $curr_row * $colmax ))

        for option in "${options[@]}"; do

            row=$(( $idx/$colmax ))
            col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_selected "$option"
            else
                print_option "$option"
            fi
            ((idx++))
        done
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local return_value=$1
    local lastrow=`get_cursor_row`
    local lastcol=`get_cursor_col`
    local startrow=$(($lastrow - $#))
    local startcol=1
    local lines=$( tput lines )
    local cols=$( tput cols )
    local colmax=$2
    local offset=$(( $cols / $colmax ))

    local size=$4
    shift 4

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row
        # user key control
        case `key_input` in
            enter)  break;;
            up)     ((active_row--));
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++));
                    if [ $active_row -ge $(( ${#options[@]} / $colmax ))  ]; then active_row=$(( ${#options[@]} / $colmax )); fi;;
            left)     ((active_col=$active_col - 1));
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)     ((active_col=$active_col + 1));
                    if [ $active_col -ge $colmax ]; then active_col=$(( $colmax - 1 )) ; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $(( $active_col + $active_row * $colmax ))
}

logo () {
# This will be shown on every set as user is progressing
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
    Please Select Preset Setting For Your System
"
}

filesystem () {
# This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
echo -ne "
Please Select your desired filesystem for both boot and root
"
options=("btrfs" "ext4" "luks" "exit")
select_option $? 1 "${options[@]}"

case $? in
0) set_option FS btrfs;;
1) set_option FS ext4;;
2)
while true; do
  echo -ne "Please enter your luks password: \n"
  read -s luks_password # read password without echo

  echo -ne "Please repeat your luks password: \n"
  read -s luks_password2 # read password without echo

  if [ "$luks_password" = "$luks_password2" ]; then
    set_option LUKS_PASSWORD $luks_password
    set_option FS luks
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done
;;
3) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}

timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "
System detected your timezone to be '$time_zone' \n"
echo -ne "Is this correct?
"
options=("Yes" "No")
select_option $? 1 "${options[@]}"

case ${options[$?]} in
    y|Y|yes|Yes|YES)
    echo "${time_zone} set as timezone"
    set_option TIMEZONE $time_zone;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :"
    read new_timezone
    echo "${new_timezone} set as timezone"
    set_option TIMEZONE $new_timezone;;
    *) echo "Wrong option. Try again";timezone;;
esac
}

keymap () {
echo -ne "
Please select key board layout from this list"
# These are default key maps as presented in official arch repo archinstall
options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

select_option $? 4 "${options[@]}"
keymap=${options[$?]}

echo -ne "Your key boards layout: ${keymap} \n"
set_option KEYMAP $keymap
}

drivessd () {
echo -ne "
Is this an ssd? yes/no:
"

options=("Yes" "No")
select_option $? 1 "${options[@]}"

case ${options[$?]} in
    y|Y|yes|Yes|YES)
    set_option MOUNT_OPTIONS "noatime,compress=zstd,ssd,commit=120";;
    n|N|no|NO|No)
    set_option MOUNT_OPTIONS "noatime,compress=zstd,commit=120";;
    *) echo "Wrong option. Try again";drivessd;;
esac
}

# selection for disk type
diskpart () {
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
    Please make sure you know what you are doing because
    after formating your disk there is no way to get data back
------------------------------------------------------------------------

"

PS3='
Select the disk to install on: '
options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

select_option $? 1 "${options[@]}"
disk=${options[$?]%|*}

echo -e "\n${disk%|*} selected \n"
    set_option DISK ${disk%|*}

drivessd
}

userinfo () {
read -p "Please enter your username: " username
set_option USERNAME ${username,,} # convert to lower case as in issue #109
while true; do
  echo -ne "Please enter your password: \n"
  read -s password # read password without echo

  echo -ne "Please repeat your password: \n"
  read -s password2 # read password without echo

  if [ "$password" = "$password2" ]; then
    set_option PASSWORD $password
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done
read -rep "Please enter your hostname: " nameofmachine
set_option NAME_OF_MACHINE $nameofmachine
while true; do
  echo -ne "Please enter your root password: \n"
  read -s rpassword # read password without echo

  echo -ne "Please repeat your root password: \n"
  read -s rpassword2 # read password without echo

  if [ "$rpassword" = "$rpassword2" ]; then
    set_option RPASSWORD $rpassword
    break
  else
    echo -e "Password do not match. Please try again: \n"
  fi
done
}

extra_packages () {
read -p "Please enter your desired packages/fonts to install(pacman only, seperated with spaces): " expackages
set_option EXPACKAGES $expackages
}

region () {
echo -ne "
NOTE: IMPORTANT TO PUT THE RIGHT REGION OR PACKAGE DOWNLOAD MIGHT FAIL)

   Country                Code		Country                Code		Country                Code
   ---------------------- ----		---------------------- ----             ---------------------- ----
1. Australia                AU          24.Hong Kong             HK		47.Pakistan              PK
2. Austria                  AT		25.Hungary               HU		48.Paraguay              PY
3. Bangladesh               BD		26.Iceland               IS		49.Poland                PL
4. Belarus                  BY		27.India                 IN		50.Portugal              PT
5. Belgium                  BE		28.Indonesia             ID		51.Romania               RO
6. Bosnia and Herzegovina   BA		29.Iran                  IR		52.Russia                RU
7. Brazil                   BR		30.Ireland               IE		53.R??union               RE
8. Bulgaria                 BG		31.Israel                IL		54.Serbia                RS
9. Cambodia                 KH		32.Italy                 IT		55.Singapore             SG
10.Canada                   CA		33.Japan                 JP		56.Slovakia              SK
11.Chile                    CL		34.Kazakhstan            KZ		57.Slovenia              SI
12.China                    CN		35.Kenya                 KE		58.South Africa          ZA
13.Colombia                 CO		36.Latvia                LV		59.South Korea           KR
14.Croatia                  HR		37.Lithuania             LT		60.Spain                 ES
15.Czechia                  CZ		38.Luxembourg            LU		61.Sweden                SE
16.Denmark                  DK		39.Mexico                MX		62.Switzerland           CH
17.Ecuador                  EC		40.Moldova               MD		63.Taiwan                TW
18.Estonia                  EE		41.Monaco                MC		64.Thailand              TH
19.Finland                  FI		42.Netherlands           NL		65.Turkey                TR
20.France                   FR		43.New Caledonia         NC		66.Ukraine               UA
21.Georgia                  GE		44.New Zealand           NZ		67.United Kingdom        GB
22.Germany                  DE		45.North Macedonia       MK		68.United States         US
23.Greece                   GR		46.Norway                NO		69.Vietnam               VN

"
read -p "Please enter your region to download packages from(enter the region code only: " user_region
regon=("GE" "NZ" "GB" "DE" "MK" "US" "GR" "NO" "VN")
while true; do
if [[ "$user_region" =~ ^(AU|HK|PK|AT|HU|PY|BD|IS|PL|BY|IN|PT|BE|ID|RO|BA|IR|RU|BR|IE|RE|BG|IL|RS|KH|IT|SG|CA|JP|SK|CL|KZ|SI|CN|KE|ZA|CO|LV|KR|HR|LT|ES|CZ|LU|SE|DK|MX|CH|EC|MD|TW|EE|MC|TH|FI|NL|TR|FR|NC|UA|GE|NZ|GB|DE|MK|US|GR|NO|VN)$ ]]; then
    set_option REGION $user_region
break
else
    read -p "Please enter your region to download packages from(enter the region code only: " user_region
fi
done
}

aurhelper () {
  # Let the user choose AUR helper from predefined list
  echo -ne "Please enter your desired AUR helper:\n"
  options=(paru yay picaur aura trizen pacaur none)
  select_option $? 4 "${options[@]}"
  aur_helper=${options[$?]}
  set_option AUR_HELPER $aur_helper
}

desktopenv () {
  # Let the user choose Desktop Enviroment from predefined list
  echo -ne "Please select your desired Desktop Enviroment:\n"
  options=(gnome kde cinnamon xfce mate budgie lxde deepin openbox server)
  select_option $? 4 "${options[@]}"
  desktop_env=${options[$?]}
  set_option DESKTOP_ENV $desktop_env
}

networkset () {
  echo -ne "Please select your desired Network Setup:\n"
  options=(NetworkManager Dhclient)
  select_option $? 4 "${options[@]}"
  network_set=${options[$?]}
  set_option NETWORK_SET $network_set
}

audioserv () {
  echo -ne "Please select your desired Audio Server:\n"
  options=(pulseaudio pipewire)
  select_option $? 4 "${options[@]}"
  audio_serv=${options[$?]}
  set_option AUDIO_SERV $audio_serv
}

bluetooth () {
  echo -ne "Do you want Bluetooth on this device:\n"
  options=(Yes No)
  select_option $? 4 "${options[@]}"
  bluetooth=${options[$?]}
  set_option BLUETOOTH $bluetooth
}

printercomp () {
  echo -ne "Do you want to use Printer on this device:\n"
  options=(Yes No)
  select_option $? 4 "${options[@]}"
  printer_comp=${options[$?]}
  set_option PRINTING $printer_comp
}

favshell () {
  echo -ne "Please select your Favourite Shell(If you don't know, choose bash):\n"
  options=(fish zsh bash)
  select_option $? 4 "${options[@]}"
  fav_shell=${options[$?]}
  set_option FAV_SHELL $fav_shell
}

dualboot () {
  echo -ne "Are you dual booting on this device:\n"
  options=(Yes No)
  select_option $? 4 "${options[@]}"
  dual_boot=${options[$?]}
  set_option DUALBOOT $dual_boot
}

kernel () {
  echo -ne "Please select your desired kernel:\n"
  options=(linux linux-hardened linux-lts linux-zen)
  select_option $? 4 "${options[@]}"
  kernel_=${options[$?]}
  set_option KERNEL $kernel_
}

installtype () {
  echo -ne "Please select type of installation:\n\n
  Full install: Installs full featured desktop enviroment, with added apps and themes needed for everyday use\n
  Minimal Install: Installs only apps few selected apps to get you started\n"
  options=(FULL MINIMAL)
  select_option $? 4 "${options[@]}"
  install_type=${options[$?]}
  set_option INSTALL_TYPE $install_type
}

# Starting functions
clear
logo
userinfo
clear
logo
region
clear
logo
desktopenv
clear
logo
networkset
clear
logo
aurhelper
clear
logo
installtype
clear
logo
kernel
clear
logo
diskpart
clear
logo
favshell
clear
logo
dualboot
clear
logo
filesystem
clear
logo
clear
logo
audioserv
clear
logo
timezone
clear
logo
bluetooth
clear
logo
printercomp
clear
logo
keymap
clear
logo
extra_packages