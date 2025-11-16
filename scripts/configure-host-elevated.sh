#!/bin/bash
set -e #exit on any error

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please run with sudo."
    exit 1
fi
echo "Current working directory: $(pwd)."

#get the value that ~ resolves to for the user who invoked sudo
USER_HOME=$(eval echo "~")
echo "User home directory is $USER_HOME"
#check that the script is being run with sudo -E by checking if we are in /root
if [ "$USER_HOME" == "/root" ]; then
    echo "You need to run this script with sudo -E to keep the users home directory."
    exit 1
fi

install_packages_and_update()
{
    echo "Adding backports repository and installing required packages..."
    . /etc/os-release
    echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list
    apt-get -y install gettext wget libunwind8
    apt purge --auto-remove -y 'pulseaudio*'
    apt purge --auto-remove -y 'fluidsynth*'
    apt autoremove -y
    apt -y update
    apt -y upgrade
    
} 

install_pwsh()
{
    if [ ! -f /usr/bin/pwsh ]; then
        echo "PowerShell not found, installing..."
        mkdir -p /opt/microsoft/powershell/7
        wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/powershell-7.5.4-linux-arm64.tar.gz
        tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
        chmod +x /opt/microsoft/powershell/7/pwsh
        ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
        rm /tmp/powershell.tar.gz  
    else
        echo "PowerShell found, skipping install."
        pwsh -Command 'Write-Host "hello world from $($host.version)"'
    fi
}

install_dotnet()
{
    if [ ! -f /usr/local/bin/dotnet ]; then
        echo "dotnet not found, installing..."

        tempDir=$(mktemp -d)
        echo "Downloading dotnet install script to ${tempDir}/dotnet-install.sh"
        curl -sSL https://dot.net/v1/dotnet-install.sh -o ${tempDir}/dotnet-install.sh
        chmod 755 ${tempDir}/dotnet-install.sh
        export DOTNET_INSTALL_DIR=/opt/microsoft/dotnet
        export DOTNET_ROOT=/opt/microsoft/dotnet
        ${tempDir}/dotnet-install.sh --verbose --channel 9.0 
        ${tempDir}/dotnet-install.sh --verbose --channel 8.0 
        ln -s /opt/microsoft/dotnet/dotnet /usr/local/bin/dotnet
        echo "dotnet installed to /opt/microsoft/dotnet. cleaning up temp files in ${tempDir}"
        rm -rf ${tempDir}   

    else
        echo "dotnet found, skipping install."
    fi
}

disable_ipv6_on_boot()
{
    echo "ipv6.disable=1" >> /boot/cmdline.txt
}

echo "----------------------------------------"
echo "Starting elevated host configuration script..."
echo "----------------------------------------"
echo "Disabling IPv6 on boot..."
disable_ipv6_on_boot
echo "installing required packages and updating system..."
install_packages_and_update
echo "installing PowerShell..."
install_pwsh
echo "installing .NET SDK..."
install_dotnet
echo "----------------------------------------"
echo "elevated host configuration script complete."