#!/bin/bash
#Configure by copying grbl_rpi.conf.temp from the templates folder to
# grbl_rpi.conf in the folder containing grbl_rpi_setup_network.sh and
# grbl_rpi_setup_update.shsetting. Modify script settings in 
# grbl_rpi.conf

#helper function to output error message and exit
function fail {
    printf '%s\n' "$1" >&2
    exit "${2-1}"
}

#load config file and set defaults
source $(dirname $(realpath $0))/grbl_rpi.conf
[ -z "$GIT_DIRECTORY" ] && GIT_DIRECTORY=""
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="master"
[ -z "$GRBL_REPO" ] && GRBL_REPO="https://github.com/gnea/grbl"

#install update
sudo apt-get update

#install git
sudo apt-get install -y git
#setup grbl git repository
mkdir $HOME/$GIT_DIRECTORY
git -C $HOME/$GIT_DIRECTORY clone --branch $GIT_BRANCH $GRBL_REPO

#install arduino cli
sh $(dirname $(realpath $0))/dependencies/install.sh
echo 'export PATH=$PATH:$HOME/bin' >> $HOME/.bashrc
export PATH=$PATH:$HOME/bin
arduino-cli core install arduino:avr

#install minicom
sudo apt-get install -y minicom

#remove setup script from crontab
crontab -l > setupcron
sudo sed -i '/grbl_rpi_setup_update\.sh/d' setupcron
if [[ -z "$(cat setupcron | xargs)" ]]; then crontab -r; else crontab setupcron; fi
rm setupcron

#reboot
sudo reboot
