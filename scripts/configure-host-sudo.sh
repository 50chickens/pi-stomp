#!/bin/bash
set -e #exit on any error
greenText="\e[32m"
redText="\e[31m"
blueText="\e[34m"
CONFIGURE_HOST_INCLUDES="./configure-host-includes.sh"
if [ ! -f "$CONFIGURE_HOST_INCLUDES" ]; then
    echo -e "${redText}File $CONFIGURE_HOST_INCLUDES not found. Cannot continue.\e[0m"
    exit 1
fi
. "$CONFIGURE_HOST_INCLUDES"

test_if_root
test_if_were_in_root_directory
install_backports
install_powershell
install_dotnet