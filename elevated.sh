. /etc/os-release
echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list
apt update

apt-get install -y -t ${VERSION_CODENAME}-backports cockpit sscg
sudo apt-get install -y gettext nodejs npm make

git clone https://github.com/cockpit-project/cockpit-files.git
cd cockpit-files
make install

#systemctl start cockpit
systemctl disable bluetooth.service
systemctl stop bluetooth.service
systemctl disable dnsmasq.service
systemctl stop dnsmasq.service
systemctl disable cockpit.socket
systemctl stop cockpit.socket

systemctl disable cockpit.service
systemctl stop cockpit.service

systemctl disable exim4.service
systemctl stop exim4.service