#!/bin/bash

set -e #exit on any error
greenText="\e[32m"
redText="\e[31m"
blueText="\e[34m"

dtOverlay="iqaudio-codec"
alsaDeviceName="IQaudIOCODEC"
alsaStatefilename="iqaudiocodec.state"

. ./configure-host-includes.sh
echo "----------------------------------------"
echo "Starting host configuration script..."

expected_dir="$HOME/pi-stomp/scripts"
echo "Current user is $(whoami)"

test_if_non_root_user
test_we_can_sudo
switch_to_correct_directory

# get VERSION_CODENAME and run PowerShell scripts
echo "----------------------------------------"
echo "Getting OS configuration from /etc/os-release"
. /etc/os-release #get VERSION_CODENAME
echo "VERSION_CODENAME is ${VERSION_CODENAME}"
if ([ -z "${VERSION_CODENAME}" ]); then
    echo "VERSION_CODENAME is empty, cannot continue."
    exit 1
fi

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
echo "Running elevated powershell scripts..." #requires sudo -E to preserve user environment including home directory
sudo -E pwsh -File "$WORK_DIR/configure-host-elevated.ps1" -VERSION_CODENAME "${VERSION_CODENAME}" -workingDirectory "$WORK_DIR" -requiredOverlayName $dtOverlay -requiredAlsaDeviceName $alsaDeviceName #all of the things that need sudo
echo "----------------------------------------"
echo "running audio installation powershell scripts..."
pwsh -File "$WORK_DIR/configure-host.ps1" -VERSION_CODENAME "${VERSION_CODENAME}" -workingDirectory "$WORK_DIR" -alsaStatefilename $alsaStatefilename
echo "All done!"