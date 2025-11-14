function Test-ImInTheCorrectFolder()
{
    if ((pwd).Path -notlike "*pi-stomp*")
    {
        write-host "You are not in the pi-stomp folder. Please run this script from the pi-stomp folder." -ForegroundColor Red
        exit 1
    }
    else
    {
        write-host "You are in the correct folder." -ForegroundColor Green
    }
}

function New-PythonVenv($venvPath)
{
    # expand ~ to actual home path if provided
    if ($venvPath -imatch "~*") { $venvPath = $venvPath -replace '^~', $HOME }

    if (Test-Path -Path $venvPath -PathType Container)
    {
        Remove-Item -Recurse -Force $venvPath
        Write-Host "Removed existing python virtual environment at $venvPath"
    }
    else
    {
        Write-Host "No existing python virtual environment at $venvPath"
    }

    python3 -m venv $venvPath
    Write-Host "Created python virtual environment at $venvPath"
}

#commands in here are the ones that require root access without using sudo (this script is called with sudo pwsh -c etc.)
function Invoke-ElevatedCommands() 
{
    if (Test-Path -Path "./elevated.ps1" -PathType Leaf) 
    { 
        Write-Host "Found elevated.ps1, running with sudo..." -ForegroundColor Green
    } 
    else 
    { 
        write-host "Could not find elevated.ps1, cannot continue." -ForegroundColor Red
        exit 1
    }
    sudo -E pwsh -c "./elevated.ps1" #things in here run with sudo
}

function Test-ICanSudo()
{
    sudo -n true
    write-host "Checking for root permissions..."
    write-host "sudo -n true returned $LASTEXITCODE"
    if ($LASTEXITCODE -eq 0) 
    { 
        Write-Host "You can sudo root permissions." -ForegroundColor Green
    } 
    else 
    { 
        write-host "You cannot sudo with root permissions. Please run this script with sudo or as root." -ForegroundColor Red
        exit 1
    }
}

function Invoke-PackageInstall()
{
    sudo apt-get -y install virtualenv python3-pip python3-dev python3-zeroconf build-essential libasound2-dev libjack-jackd2-dev liblilv-dev libjpeg-dev zlib1g-dev cmake debhelper dh-autoreconf dh-python gperf intltool ladspa-sdk libarmadillo-dev libavahi-gobject-dev libavcodec-dev libavutil-dev libbluetooth-dev libboost-dev libeigen3-dev libfftw3-dev libglib2.0-dev libglibmm-2.4-dev libgtk2.0-dev libgtkmm-2.4-dev liblrdf0-dev libsamplerate0-dev libsigc++-2.0-dev libsndfile1-dev libzita-convolver-dev libzita-resampler-dev lv2-dev p7zip-full python3-all python3-setuptools libreadline-dev zita-alsa-pcmi-utils hostapd dnsmasq iptables python3-smbus liblo-dev python3-liblo libzita-alsa-pcmi-dev authbind rcconf libfluidsynth-dev lockfile-progs tree
    sudo apt-get -y install liblilv-dev lv2-dev libserd-dev libsord-dev libsratom-dev lilv-utils liblilv-0-0
    sudo apt-get -y install libasound2-dev
    sudo apt install bc bison flex libssl-dev make #required for building linux kernel modules
    #sudo apt-get install -y libjack-jackd2-dev jackd2

    sudo apt update && sudo apt install -y \
    virtualenv python3-venv python3-pip python3-dev python3-all python3-setuptools python3-zeroconf python3-smbus python3-liblo \
    build-essential pkg-config cmake debhelper dh-autoreconf dh-python gperf intltool make \
    libasound2-dev libjack-jackd2-dev libpulse-dev liblilv-dev libserd-dev libsord-dev libsratom-dev lilv-utils liblilv-0-0 lv2-dev \
    libfreetype6-dev libjpeg-dev libpng-dev libtiff5-dev zlib1g-dev libpng-dev libtiff5-dev libreadline-dev libssl-dev libffi-dev \
    libarmadillo-dev libavahi-gobject-dev libavcodec-dev libavutil-dev libbluetooth-dev libboost-dev libeigen3-dev libfftw3-dev \
    libglib2.0-dev libglibmm-2.4-dev libgtk2.0-dev libgtkmm-2.4-dev liblrdf0-dev libsamplerate0-dev libsigc++-2.0-dev libsndfile1-dev \
    libzita-convolver-dev libzita-resampler-dev libzita-alsa-pcmi-dev zita-alsa-pcmi-utils libfluidsynth-dev librtmidi-dev ladspa-sdk liblo-dev \
    p7zip-full authbind hostapd dnsmasq iptables lockfile-progs tree bc bison flex git curl

}
function New-Folders($foldersToCreate, $baseFolder, [switch] $sudo)
{ 
    write-verbose "baseFolder: $baseFolder"
    write-verbose "sudo: $sudo"
    foreach ($folder in $foldersToCreate) 
    {
        if ($baseFolder) 
        { 
            write-verbose "baseFolder is $baseFolder"
            $folder = "$baseFolder/$folder" 
        }
        write-verbose "testing for folder: $folder"
        if (-Not (Test-Path -Path $folder)) 
        {
            if ($sudo) 
            {
                Write-Host "Creating folder: $folder with sudo"
                sudo pwsh -c "New-Item -ItemType Directory -Path $folder -whatif" | Out-Null
                Write-Verbose "Created folder: $folder with sudo"
            } 
            else 
            {
                write-host "Creating folder: $folder"
                New-Item -ItemType Directory -Path $folder | Out-Null
                Write-Verbose "Created folder: $folder"
            }
        } 
        else 
        {
            Write-Host "Folder already exists: $folder"
        }
    }
}

function New-lv2pluginsfolder()
{
    if (Test-Path -Path "~/.lv2")
    {
        Write-Host "~/.lv2 folder already exists"
        remove-item -Recurse -Force ~/.lv2
    }
    if (Test-Path -Path "~/data/.lv2")
    {
        Write-Host "~/data/.lv2 folder already exists .Removing"
        remove-item -force ~/data/.lv2 #remove item won't remove symlinks where the target is missing.
    }
    Write-Host "linking ~/data/.lv2 folder to ~/.lv2"
    ln -s ~/.lv2 ~/data/.lv2
}