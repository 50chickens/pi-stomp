#!/bin/bash
#these things need to be done as root

set -e #exit on any error
greenText="\e[32m"
redText="\e[31m"
blueText="\e[34m"

function remove_audio_packages {
    pulseaudio=$(dpkg-query -W -f='${Status}' pulseaudio 2>/dev/null | grep -c "ok installed" || true)
    fluidsynth=$(dpkg-query -W -f='${Status}' fluidsynth 2>/dev/null | grep -c "ok installed" || true)

    if [ $pulseaudio -eq 0 ] && [ $fluidsynth -eq 0 ]; then
        echo -e "${greenText}Neither pulseaudio nor fluidsynth is installed. Nothing to remove.\e[0m"
    else
        echo -e "${redText}Removing pulseaudio and fluidsynth...\e[0m"
        apt purge --auto-remove -y 'pulseaudio*'
        apt purge --auto-remove -y 'fluidsynth*'
    fi

}
function disable_ipv6 {
    #test if ipv6 is already disabled
    ipv6_disabled=$(sysctl net.ipv6.conf.all.disable_ipv6 | grep -c "1" || true)
    
    if [ $ipv6_disabled -eq 1 ]; then
        echo -e "${greenText}IPv6 is already disabled, skipping\e[0m" #print in green text
        return
    fi
    echo -e "${redText}ipv6 is present. Disabling on reboot.\e[0m"

    #disable ipv6 on reboot 
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p  

    #disable ipv6 now
    echo -e "${redText}Disabling IPv6 in current session. This may disrupt network connectivity temporarily.\e[0m"
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1    
}

function install_powershell() {
    #test for pwsh command
    if command -v pwsh &> /dev/null
    then
        echo -e "${greenText}PowerShell found, skipping install but testing pwsh.\e[0m"
        pwsh -Command 'Write-Host "hello world from $($host.version)"'
        if [ $? -ne 0 ]; then
            echo -e "${redText}PowerShell says it's installed but it's not working\e[0m"
            exit 1
        fi
        echo -e "${greenText}PowerShell is working correctly.\e[0m"
        return
    fi
    # Install PowerShell
    apt install -y wget libunwind8  
    sudo mkdir -p /opt/microsoft/powershell/7
    wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/powershell-7.5.4-linux-arm64.tar.gz
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
    chmod +x /opt/microsoft/powershell/7/pwsh
    if [ -L /usr/bin/pwsh ]; then
        rm /usr/bin/pwsh
    fi
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
    rm /tmp/powershell.tar.gz
    pwsh -Command 'Write-Host "hello world from $($host.version)"'
    if [ $? -ne 0 ]; then
        echo -e "${redText}PowerShell installation failed\e[0m"
        exit 1
    fi

}

function install_dotnet() {
    #test for dotnet command 
    if command -v dotnet &> /dev/null
    then
        echo -e "${greenText}dotnet found, skipping install but testing dotnet.\e[0m"
        pwsh -Command 'Write-Host "dotnet version from pwsh: $(dotnet --version)"'
        if [ $? -ne 0 ]; then
            echo -e "${redText}dotnet command is available but is not working correctly.\e[0m"
            exit 1
        fi
        echo -e "${greenText}dotnet is working correctly.\e[0m"
        return
    fi
    apt-get -y install gettext
    curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
    chmod 755 dotnet-install.sh
    export DOTNET_INSTALL_DIR=/opt/microsoft/dotnet
    export DOTNET_ROOT=/opt/microsoft/dotnet
    ./dotnet-install.sh --verbose --channel 9.0
    if [ -L /usr/local/bin/dotnet ]; then
        rm /usr/local/bin/dotnet
    fi
    ln -s /opt/microsoft/dotnet/dotnet /usr/local/bin/dotnet
    rm dotnet-install.sh
    pwsh -Command 'Write-Host "dotnet version from pwsh: $(dotnet --version)"'
    if [ $? -ne 0 ]; then
        echo -e "${redText} dotnet installation failed\e[0m"
        exit 1
    fi
}
echo -e "${blueText}starting configure-host.sh.\e[0m"
#test if we're running as root
if [ "$EUID" -ne 0 ]
    then echo -e "${redText}Please run as root\e[0m"
    exit
fi

#get the value that ~ resolves to for the user who invoked sudo
USER_HOME=$(eval echo "~")
echo "User home directory is $USER_HOME"
#fail if the user's home directory is not /root (means sudo -E was used).
if [ "$USER_HOME" != "/root" ]; then
    echo -e "${redText} Don't use sudo -E.\e[0m"
    exit 1
fi

pushd .
cd ~ #should be root now.

. /etc/os-release
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list

#test if either pulseaudio or fluidsynth is installed
echo -e "${blueText}Checking for audio packages to remove...\e[0m"
remove_audio_packages
echo -e "${blueText}Disabling IPv6 if enabled...\e[0m"
disable_ipv6
echo -e "${blueText}Updating and upgrading packages...\e[0m"
apt -y update
echo -e "${blueText}Upgrading packages...\e[0m"
apt -y upgrade
echo -e "${blueText}Installing PowerShell if not present...\e[0m"
install_powershell
echo -e "${blueText}Installing dotnet if not present...\e[0m"
install_dotnet
echo -e "${blueText}Disabling IPv6 on boot...\e[0m"
disable_ipv6_on_boot
echo -e "${blueText}Configuration complete. Returning to previous directory.\e[0m"
popd #return to previous directory - should be pi-stomp directory

#test if folder is ~pistomp/pi-stomp
if [ ! -d "/home/pistomp/pi-stomp" ]; then
    echo -e "${redText}Directory /home/pistomp/pi-stomp not found. Please run this script from the pi-stomp directory as the pistomp user with sudo.\e[0m"
    exit 1
fi
echo -e "${blueText}Running configure-host.ps1 with pwsh...\e[0m"
#test if ./configure-host.ps1 exists
if [ ! -f "./configure-host.ps1" ]; then
    echo -e "${redText}File ./configure-host.ps1 not found. Please run this script from the pi-stomp directory.\e[0m"
    exit 1
fi
sudo -E pwsh -File ./configure-host.ps1