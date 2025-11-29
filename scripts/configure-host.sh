#!/bin/bash

#set -e #exit on any error
greenText="\e[32m"
redText="\e[31m"
blueText="\e[34m"

dtOverlay="iqaudio-codec"
#dtOverLay="iqaudio-dacplus"
#dtOverlay="hifiberry-dacplus"
#dtOverlay="hifiberry-dac"
#dtOverlay="audioinjector-wm8731"
#dtOverlay="audioinjector-ultra"

function git_clone_or_pull_repos{
    git clone https://github.com/50chickens/audio-linux.git
}

. ./configure-host-includes.sh
echo "----------------------------------------"
echo "Starting host configuration script..."
echo "----------------------------------------"
expected_dir="$HOME/pi-stomp/scripts"
configure_host_elevated_script_filename="./configure-host-elevated.ps1"
configure_host_script_filename="./configure-host.ps1"

echo "Current user is $(whoami)"

test_if_were_non_root_user
test_we_can_sudo
switch_to_correct_directory
git_clone_or_pull_repos
# get VERSION_CODENAME and run PowerShell scripts
echo -e "----------------------------------------"
echo "${blueText}Getting OS configuration from /etc/os-release"
. /etc/os-release #get VERSION_CODENAME
echo -e "${greenText}VERSION_CODENAME is ${VERSION_CODENAME}\e[0m"
if ([ -z "${VERSION_CODENAME}" ]); then
    echo "VERSION_CODENAME is empty, cannot continue."
    exit 1
fi
echo -e "----------------------------------------"
#run configure-host-sudo.sh with sudo (not sudo -E) to do tasks that need root
HOST_CONFIG_SUDO_SCRIPT="./configure-host-sudo.sh"
if [ ! -f "$HOST_CONFIG_SUDO_SCRIPT" ]; then
    echo -e "${redText}File $HOST_CONFIG_SUDO_SCRIPT not found. Cannot continue.\e[0m"
    exit 1
fi
chmod +x "$HOST_CONFIG_SUDO_SCRIPT"
echo "Running $HOST_CONFIG_SUDO_SCRIPT with sudo..."
sudo "$HOST_CONFIG_SUDO_SCRIPT"
echo "----------------------------------------"
invoke-elevated-powershell
echo "----------------------------------------"
echo "running audio installation powershell scripts..."
pwsh -File "$configure_host_script_filename" -workingDirectory "$(pwd)" -dtOverlay $dtOverlay
echo "All done!"