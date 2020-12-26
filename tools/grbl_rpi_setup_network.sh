#!/bin/bash
# Configure by copying grbl_rpi.conf.temp from the templates folder to
#  grbl_rpi.conf in the folder containing grbl_rpi_setup_network.sh and
#  grbl_rpi_setup_update.sh. Modify script settings in 
#  grbl_rpi.conf

# helper function to output error message and exit
function fail {
    printf '%s\n' "$1" >&2
    exit "${2-1}"
}

# load config file and set defaults
source $(dirname $(realpath $0))/grbl_rpi.conf
[ -z "$NETWORK_SSID" ] && fail "NETWORK_SSID required"
[ -z "$NETWORK_PASSWORD" ] && fail "NETWORK_PASSWORD required"
[ -z "$GRBL_PUBKEY" ] && fail "GRBL_PUBKEY required"
[ -z "$NEW_HOSTNAME" ] && NEW_HOSTNAME=$(hostname)
OLD_HOSTNAME=$(hostname)
SCRIPT_DIR=$(dirname $(realpath $0))

# setup wifi connection
echo "
network={
    ssid=\"$NETWORK_SSID\"
    psk=\"$NETWORK_PASSWORD\"
}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

# add pubkey to authorized keys
mkdir $HOME/.ssh
touch $HOME/.ssh/authorized_keys
echo $GRBL_PUBKEY >> $HOME/.ssh/authorized_keys

# disable password login
sudo sed -i 's/#PasswordAuthentication\syes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# change hostname
sudo sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname
sudo sed -i "s/127.0.1.1.*$OLD_HOSTNAME\$/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

# setup crontab to execute next setup script after reboot
crontab -l > setupcron
echo "@reboot $SCRIPT_DIR/grbl_rpi_setup_update.sh" >> setupcron
crontab setupcron
rm setupcron

# reboot
sudo reboot
