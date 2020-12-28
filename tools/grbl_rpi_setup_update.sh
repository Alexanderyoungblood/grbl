#!/bin/bash
# Configure by copying grbl_rpi.conf.temp from the templates folder to
#  grbl_rpi.conf in the folder containing grbl_rpi_setup_network.sh and
#  grbl_rpi_setup_update.sh. Modify script settings in 
#  grbl_rpi.conf

# sleep to wait for network connection to come up (avoid busy waiting)
sleep 60

# helper function to output error message and exit
function fail {
    printf '%s\n' "$1" >&2
    exit "${2-1}"
}

# load config file and set defaults
source $(dirname $(realpath $0))/grbl_rpi.conf
[ -z "$GIT_DIRECTORY" ] && GIT_DIRECTORY=""
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="master"
[ -z "$GRBL_REPO" ] && GRBL_REPO="https://github.com/gnea/grbl"
[ -z "$ARDUINO_DIR" ] && ARDUINO_DIR=$HOME
SCRIPT_DIR=$(dirname $(realpath $0))
GRBL_REPO_NAME=$(basename $GRBL_REPO)

# install update
sudo apt-get update

# install git
sudo apt-get install -y git
# setup grbl git repository
mkdir $HOME/$GIT_DIRECTORY
git -C $HOME/$GIT_DIRECTORY clone --branch $GIT_BRANCH $GRBL_REPO
# set git daemon to execute on boot
crontab -l > setupcron
echo "@reboot git daemon --base-path=$HOME/$GIT_DIRECTORY/$GRBL_REPO_NAME --export-all" >> setupcron
crontab setupcron
rm setupcron

# install arduino cli
(cd $ARDUINO_DIR; sh $SCRIPT_DIR/dependencies/install.sh)
echo 'export PATH=$PATH:'$ARDUINO_DIR'/bin' >> $HOME/.bashrc
export PATH=$PATH:$ARDUINO_DIR/bin
arduino-cli core install arduino:avr
mkdir $HOME/Arduino
mkdir $HOME/Arduino/libraries


# install minicom
sudo apt-get install -y minicom

# remove setup script from crontab
crontab -l > setupcron
sudo sed -i '/grbl_rpi_setup_update\.sh/d' setupcron
if [[ -z "$(cat setupcron | xargs)" ]]; then crontab -r; else crontab setupcron; fi
rm setupcron

# reboot
sudo reboot
