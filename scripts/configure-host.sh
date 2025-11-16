#!/bin/bash

set -e
WORK_DIR="$HOME/pi-stomp/scripts"
# ensure the working directory exists
if [ ! -d "$WORK_DIR" ]; then
    echo "Working directory $WORK_DIR does not exist"
    exit 1
fi
echo "Working directory is $WORK_DIR"
# if current directory is not WORK_DIR, change to WORK_DIR
if [ "$(pwd)" != "$WORK_DIR" ]; then
    echo "Changing to working directory $WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to change directory to $WORK_DIR"; exit 1; }
fi
echo "Current directory is $(pwd)"
# test that ./configure-host-elevated.sh is executable, if not set them
if [ ! -x ./configure-host-elevated.sh ]; then
    echo "Setting execute permissions on ./configure-host-elevated.sh"
    sudo chmod 755 ./configure-host-elevated.sh
fi
echo "----------------------------------------"
echo "configure-host-elevated.sh has execute permissions."
echo "Running elevated configuration script..."

sudo -E ./configure-host-elevated.sh

# get VERSION_CODENAME and run PowerShell scripts

. /etc/os-release #get VERSION_CODENAME
pwsh -File "$WORK_DIR/configure-host-elevated.ps1" -VERSION_CODENAME "${VERSION_CODENAME}" -workingDirectory "$WORK_DIR" #all of the things that need sudo
pwsh -File "$WORK_DIR/configure-host.ps1" -VERSION_CODENAME "${VERSION_CODENAME}" -workingDirectory "$WORK_DIR"


