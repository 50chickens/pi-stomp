#!/bin/bash
#these things need to be done as root
#sysctl -w net.ipv6.conf.all.disable_ipv6=1 #if you are connected to the host via ssh using ipv6 the connection will drop

set -e #exit on any error

pushd
cd /root
. /etc/os-release
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list
apt purge --auto-remove -y 'pulseaudio*'
apt purge --auto-remove -y 'fluidsynth*'

apt -y update
apt -y upgrade

apt install -y wget libunwind8  

sudo mkdir -p /opt/microsoft/powershell/7
wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/powershell-7.5.4-linux-arm64.tar.gz
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
chmod +x /opt/microsoft/powershell/7/pwsh
ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
rm /tmp/powershell.tar.gz
pwsh -Command 'Write-Host "hello world from $($host.version)"'

### dotnet install 
## do this as root
apt-get -y install gettext
curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
chmod 755 dotnet-install.sh
export DOTNET_INSTALL_DIR=/opt/microsoft/dotnet
export DOTNET_ROOT=/opt/microsoft/dotnet
./dotnet-install.sh --verbose --channel 9.0 
./dotnet-install.sh --verbose --channel 8.0 
ln -s /opt/microsoft/dotnet/dotnet /usr/local/bin/dotnet
rm dotnet-install.sh
pwsh -Command 'Write-Host "dotnet version from pwsh: $(dotnet --version)"'

popd #return to previous directory
