sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1

. /etc/os-release
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list
apt update


#powershell

sudo apt install -y wget libssl1.1 libunwind8
sudo mkdir -p /opt/microsoft/powershell/7
wget -O /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/powershell-7.5.3-linux-arm64.tar.gz
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
sudo chmod +x /opt/microsoft/powershell/7/pwsh
sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
rm /tmp/powershell.tar.gz
pwsh -Command "write-host 'hello world from $($host.version)'"

### dotnet install 
apt-get -y install libunwind8 gettext
curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
chmod 755 dotnet-install.sh
export DOTNET_INSTALL_DIR=/opt/dotnet
export DOTNET_ROOT=/opt/dotnet
./dotnet-install.sh --verbose --channel 9.0 
./dotnet-install.sh --verbose --channel 8.0 

ln -s /opt/dotnet/dotnet /usr/local/bin

