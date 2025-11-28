function test_if_were_non_root_user() {
    echo -e "${blueText}Checking if running as root...\e[0m"
    #check if we're running as root or the current home folder is /root. fail if so. we're use sudo where we need to later.
    if [ "$(id -u)" -eq 0 ] || [ "$HOME" == "/root" ]; then
        echo -e "${redText}This script must be run as non-root user with sudo privileges. Please run without sudo.\e[0m"
        exit 1
    fi
    echo -e "${greenText}We're running as non-root user. this is good. we'll sudo as we need to.\e[0m"
}
function test_we_can_sudo() {
    echo -e "${blueText}Testing if we can sudo without a password prompt...\e[0m"
    #test that we can sudo without a password prompt
    sudo -n true
    if [ $? -ne 0 ]; then
        echo -e "${redText}This script requires sudo privileges. Please ensure your user has sudo access without a password prompt.\e[0m"
        exit 1
    fi 
    echo -e "${greenText}Sudo test succeeded. we can sudo without a password prompt.\e[0m"
}

function switch_to_correct_directory() 
{
    echo -e "${blueText}The current directory is $(pwd)"
    echo -e "${blueText}Checking if we're in the expected directory $expected_dir\e[0m"
    if [ "$(pwd)" != "$expected_dir" ]; then
    echo -e "${blueText}Changing to expected directory $expected_dir\e[0m"
    cd "$expected_dir" || { echo -e "${redText}Failed to change directory to $expected_dir\e[0m"; exit 1; }
    fi
    echo -e "${greenText}We're in the expected directory $expected_dir\e[0m"
}

function test_if_were_root() 
{
    if [ "$EUID" -ne 0 ]
        then echo -e "${redText}Please run as root\e[0m"
        exit
    fi
    echo -e "${greenText}We're running as root. this is good.\e[0m"
}

function test_if_were_in_root_directory() {
    #get the value that ~ resolves to for the user who invoked sudo
    USER_HOME=$(eval echo "~")
    echo "User home directory is $USER_HOME"
    #fail if the user's home directory is not /root (means sudo -E was used).
    if [ "$USER_HOME" != "/root" ]; then
        echo -e "${redText} Don't use sudo -E.\e[0m"
        exit 1
    fi
    echo -e "${greenText}We're in the root user's home directory. this is good.\e[0m"
}

function install_backports() {
    echo -e "${blueText}Adding backports repository to apt sources...\e[0m"
    . /etc/os-release
    echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" > \
    /etc/apt/sources.list.d/backports.list
    echo -e "${greenText}Done adding backports repository.\e[0m"
}

function install_powershell() {
    echo -e "${blueText}Installing PowerShell if not present...\e[0m"
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
    pwsh_symlink_path="/usr/bin/pwsh"
    if [ -L $pwsh_symlink_path ]; then
        echo -e "${blueText}Removing existing $pwsh_symlink_path symlink and replacing it.\e[0m"
        rm $pwsh_symlink_path
    fi
    ln -s /opt/microsoft/powershell/7/pwsh $pwsh_symlink_path
    rm /tmp/powershell.tar.gz
    pwsh -Command 'Write-Host "hello world from $($host.version)"'
    if [ $? -ne 0 ]; then
        echo -e "${redText}PowerShell installation failed\e[0m"
        exit 1
    fi
    echo -e "${greenText}PowerShell installation succeeded.\e[0m"
}

function install_dotnet() {
    echo -e "${blueText}Installing dotnet if not present...\e[0m"
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
    dotnet_symlink_path="/usr/bin/dotnet"
    if [ -L $dotnet_symlink_path ]; then
        echo -e "${blueText}Removing existing $dotnet_symlink_path symlink and replacing it.\e[0m"
        rm $dotnet_symlink_path
    fi
    ln -s /opt/microsoft/dotnet/dotnet $dotnet_symlink_path #link to real dotnet binary
    rm dotnet-install.sh
    pwsh -Command 'Write-Host "dotnet version from pwsh: $(dotnet --version)"'
    if [ $? -ne 0 ]; then
        echo -e "${redText} dotnet installation failed\e[0m"
        exit 1
    fi
    echo -e "${greenText} dotnet installation succeeded.\e[0m"
}

disable_ipv6_on_boot()
{
    echo -e "${blueText}Checking if IPv6 is already disabled on boot...\e[0m"
    #test if ipv6.disable=1 is already in /boot/cmdline.txt
    if grep -q "ipv6.disable=1" /boot/cmdline.txt; then
        echo -e "${greenText}IPv6 is already disabled on boot, skipping.\e[0m"
        return
    fi
    echo "ipv6.disable=1" >> /boot/cmdline.txt #only takes effect on next boot
    echo -e "${greenText}IPv6 disabled on boot. changes will take effect on next reboot.\e[0m"
}
