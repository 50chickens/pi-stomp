#!/bin/bash
#these things need to be done as root

set -e #exit on any error

function remove_audio_packages {
    pulseaudio=$(dpkg-query -W -f='${Status}' pulseaudio 2>/dev/null | grep -c "ok installed" || true)
    fluidsynth=$(dpkg-query -W -f='${Status}' fluidsynth 2>/dev/null | grep -c "ok installed" || true)

    if [ $pulseaudio -eq 0 ] && [ $fluidsynth -eq 0 ]; then
        echo "Neither pulseaudio nor fluidsynth is installed. Nothing to remove."
    else
        echo "Removing pulseaudio and fluidsynth..."
        apt purge --auto-remove -y 'pulseaudio*'
        apt purge --auto-remove -y 'fluidsynth*'
    fi

}
function disable_ipv6 {
    #test if ipv6 is already disabled
    ipv6_disabled=$(sysctl net.ipv6.conf.all.disable_ipv6 | grep -c "1" || true)
    if [ $ipv6_disabled -eq 1 ]; then
        echo "IPv6 is already disabled, skipping"
        return
    fi
    #disable ipv6 on reboot 
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p  

    #disable ipv6 now
    echo "Disabling IPv6..."
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1    
}

function install_powershell() {
    #test for pwsh command
    if command -v pwsh &> /dev/null
    then
        echo "PowerShell found, skipping install"
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

}

function install_dotnet() {
    #test for dotnet command 
    if command -v dotnet &> /dev/null
    then
        echo "dotnet found, skipping install"
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
}
echo "starting configure-host.sh."
#test if we're running as root
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

#get the value that ~ resolves to for the user who invoked sudo
USER_HOME=$(eval echo "~")
echo "User home directory is $USER_HOME"
#fail if the user's home directory is not /root (means sudo -E was used).
if [ "$USER_HOME" != "/root" ]; then
    echo "Don't use sudo -E."
    exit 1
fi

pushd .
cd ~ #should be root now.

. /etc/os-release
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list

#test if either pulseaudio or fluidsynth is installed
remove_audio_packages
disable_ipv6

apt -y update
apt -y upgrade

install_powershell
install_dotnet

popd #return to previous directory - should be pi-stomp directory

#cd /home/pistomp/pi-stomp && sudo -E pwsh -File /home/pistomp/pi-stomp/configure-host.ps1