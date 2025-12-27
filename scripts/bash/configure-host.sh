#!/bin/bash
set -e #exit on any error
greenText="\e[32m"
redText="\e[31m"
blueText="\e[34m"
echo -e "${greenText} running configure-host.sh configuration tasks...\e[0m"
SYSTEM_INCLUDES="./bash/includes/system.sh" #we can't pass this in from configure.sh.
if [ ! -f "$SYSTEM_INCLUDES" ]; then
    echo -e "${redText}File $SYSTEM_INCLUDES not found. Cannot continue.\e[0m"
    exit 1
fi
. "$SYSTEM_INCLUDES"

#all of the these functions come from system.sh
echo -e "----------------------------------------"
test_if_were_root
echo -e "----------------------------------------"
test_if_were_in_root_directory
echo -e "----------------------------------------"
install_backports
echo -e "----------------------------------------"
install_powershell
echo -e "----------------------------------------"
install_dotnet
echo -e "----------------------------------------"
disable_ipv6_on_boot
echo -e "----------------------------------------"
echo -e "${greenText}Completed elevated configuration tasks.\e[0m"