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

curl 'https://vscode.download.prss.microsoft.com/dbazure/download/stable/e3a5acfb517a443235981655413d566533107e92/code_1.104.2-1758714550_arm64.deb' -o code.deb

export HOME=/home/pistomp/data
export LV2_PATH=/home/pistomp/.lv2
export LV2_PLUGIN_DIR=/home/pistomp/.lv2
export LV2_PEDALBOARDS_DIR=/home/pistomp/data/.pedalboards
export MOD_DEV_ENVIRONMENT=0
export MOD_DEVICE_WEBSERVER_PORT=80
export MOD_LOG=0
export MOD_APP=0
export MOD_LIVE_ISO=0
export MOD_SYSTEM_OUTPUT=1
export MOD_DATA_DIR=/home/pistomp/data
export MOD_USER_FILES_DIR=/home/pistomp/data/user-files
export MOD_HTML_DIR=/usr/local/share/mod/html
export JACK_PROMISCUOUS_SERVER=jack
export PATCHSTORAGE_API_URL=https://patchstorage.com/api/beta/patches
export PATCHSTORAGE_PLATFORM_ID=8046
export PATCHSTORAGE_TARGET_ID=8280
