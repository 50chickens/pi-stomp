#!/bin/bash
set -e #exit on any error

function dot_source_os_release_file() 
{
    echo -e "${blueText}Getting OS configuration from /etc/os-release"
    . /etc/os-release #get VERSION_CODENAME
    echo -e "${greenText}VERSION_CODENAME is ${VERSION_CODENAME}\e[0m"
    if ([ -z "${VERSION_CODENAME}" ]); then
        echo "VERSION_CODENAME is empty, cannot continue."
        exit 1
    fi
}
# function configure_pistomp_powershell_script()
# {
#     pwsh -File "$configure_pistomp_powershell_script_filename" -dtOverlay $dtOverlay
#     #fail on error
#     if [ $? -ne 0 ]; then
#         echo -e "${redText}Pistomp configuration script failed\e[0m"
#         exit 1
#     fi

# }
function git_clone_or_pull_repos() 
{
    echo "Checking out or pulling latest code from git repos..."
    #noop for now, assume repos are already cloned.
}
function run_configure_host_bash_script() 
{
#run configure-host.sh with sudo (not sudo -E) to do OS configuration tasks that need root.
    HOST_CONFIG_SCRIPT="./bash/configure-host.sh"
    if [ ! -f "$HOST_CONFIG_SCRIPT" ]; then
        echo -e "${redText}File $HOST_CONFIG_SCRIPT not found. Cannot continue.\e[0m"
        exit 1
    fi
    chmod +x "$HOST_CONFIG_SCRIPT"
    echo "Running $HOST_CONFIG_SCRIPT with sudo..."
    sudo "$HOST_CONFIG_SCRIPT"
}
run_configure_powershell_script_audio()
{
    sudo pwsh -File "./powershell/configure.ps1" -ShouldBeRoot -InstallAudio
    #fail on error
    if [ $? -ne 0 ]; then
        echo -e "${redText}Audio services configuration script failed\e[0m"
        exit 1
    fi
}
run_configure_powershell_script_cockpit()
{
    sudo pwsh -File "./powershell/configure.ps1" -ShouldBeRoot -InstallCockpit
    #fail on error
    if [ $? -ne 0 ]; then
        echo -e "${redText}Cockpit configuration script failed\e[0m"
        exit 1
    fi
}
run_configure_powershell_script_audioPackages()
{
    sudo pwsh -File "./powershell/configure.ps1" -ShouldBeRoot -InstallAudioPackages
    #fail on error
    if [ $? -ne 0 ]; then
        echo -e "${redText}Audio packages installation script failed\e[0m"
        exit 1
    fi
}
run_configure_powershell_script_createPythonVirtualEnvironment()
{
    pwsh -File "./powershell/configure.ps1" -CreatePythonVirtualEnvironment
    #fail on error
    if [ $? -ne 0 ]; then
        echo -e "${redText}Python virtual environment setup script failed\e[0m"
        exit 1
    fi
}
invoke-configure-powershell_script_create_systemd_services()
{
    sudo pwsh -File "./powershell/configure.ps1" -ShouldBeRoot -CreateAudioServicesSystemd
    if [ $? -ne 0 ]; then
        echo -e "${redText}Audio services systemd configuration script failed\e[0m"
        exit 1
    fi
}
invoke-configure-powershell_script_userdata_files()
{
    pwsh -File "./powershell/configure.ps1" -InstallUserDataFiles
    if [ $? -ne 0 ]; then
        echo -e "${redText}User data files installation script failed\e[0m"
        exit 1
    fi
}
invoke-configure-powershell_script_start_systemd_services()
{
    sudo pwsh -File "./powershell/configure.ps1" -ShouldBeRoot -StartAudioServices
    if [ $? -ne 0 ]; then
        echo -e "${redText}Starting audio services systemd services script failed\e[0m"
        exit 1
    fi
}


#set -e #exit on any error
greenText="\e[32m"
redText="\e[31m"
blueText="\e[34m"
yellowText="\e[33m"
#dtOverlay="iqaudio-codec"
#dtOverLay="iqaudio-dacplus"
#alsaStateFile="hifiberry"
#dtOverlay="hifiberry-dacplusadcpro"
#dtOverlay="hifiberry-dac"
#dtOverlay="audioinjector-wm8731"
#dtOverlay="audioinjector-ultra"
# configTxtPath="/boot/firmware/config.txt"
# base_directory="$HOME/pi-stomp/scripts"
# base_powershell_directory="$HOME/pi-stomp/scripts/powershell"
# configure_host_powershell_script_filename="./powershell/configure-host.ps1" #powershell that needs root/sudo.
# configure_pistomp_powershell_script_filename="./powershell/configure-pistomp.ps1" #powershell that does pistomp specific configuration.
# configure_audioservices_powershell_script_filename="./powershell/configure-host-audioservices.ps1" #powershell that creates/starts the audio services.

SYSTEM_INCLUDES="./bash/includes/system.sh"
if [ ! -f "$SYSTEM_INCLUDES" ]; then
    echo -e "${redText}File $SYSTEM_INCLUDES not found. Cannot continue.\e[0m"
    exit 1
fi
. "$SYSTEM_INCLUDES" #all of the functions in here need root.

echo "----------------------------------------"
echo "Starting host configuration script..."
echo "----------------------------------------"

echo "Current user is $(whoami)"

test_if_were_non_root_user
test_we_can_sudo
switch_to_correct_directory
echo -e "----------------------------------------"
git_clone_or_pull_repos 
echo -e "----------------------------------------"
dot_source_os_release_file # get VERSION_CODENAME and run PowerShell scripts
echo -e "----------------------------------------"
run_configure_host_bash_script #run this script as sudo to do OS configuration tasks that need root.
echo -e "----------------------------------------"
#run_configure_powershell_script_audio
echo -e "----------------------------------------"
#run_configure_powershell_script_cockpit
echo -e "----------------------------------------"
#run_configure_powershell_script_audioPackages
echo -e "----------------------------------------"
#run_configure_powershell_script_createPythonVirtualEnvironment
echo -e "----------------------------------------"
invoke-configure-powershell_script_create_systemd_services
echo -e "----------------------------------------"
#invoke-configure-powershell_script_userdata_files
echo -e "----------------------------------------"
invoke-configure-powershell_script_start_systemd_services
echo -e "----------------------------------------"

# #invoke-configure-host_powershell_script
# echo -e "----------------------------------------"
# echo "running pistomp installation powershell scripts..."
# #configure_pistomp_powershell_script
# echo -e "----------------------------------------"
# #invoke-configure-audioservices_powershell_script
# echo -e "----------------------------------------"
# echo "All done!"