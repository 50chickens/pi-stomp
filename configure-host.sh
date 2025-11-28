
echo -e "${blueText}starting configure-host.sh.\e[0m"
#test if we're running as root

#test if folder is ~pistomp/pi-stomp
if [ ! -d "/home/pistomp/pi-stomp" ]; then
    echo -e "${redText}Directory /home/pistomp/pi-stomp not found. Please run this script from the pi-stomp directory as the pistomp user with sudo.\e[0m"
    exit 1
fi
echo -e "${blueText}Running configure-host.ps1 with pwsh...\e[0m"
#test if ./configure-host.ps1 exists
$configureScript="./configure-hostaudio.ps1"
if [ ! -f $configureScript ]; then
    echo -e "${redText}File $configureScript not found. Please run this script from the pi-stomp directory.\e[0m"
    exit 1
fi
#sudo -E pwsh -File $configureScript