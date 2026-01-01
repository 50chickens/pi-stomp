param(
        [switch]$shouldBeRoot,
        [switch]$InstallAudio,
        [switch]$InstallAudioPackages,
        [switch]$InstallOptionalPackages,
        [switch]$InstallCockpit,
        [switch]$InstallMainPackages,
        [switch]$InstallOtherPackages,
        [switch]$createPythonVirtualEnvironment,
        [switch]$CreateAudioServicesSystemd,
        [switch]$StartAudioServices,
        [switch]$InstallUserDataFiles
)
$ErrorActionPreference = "Stop"

# Write-host "Audio configuration script started with parameters:"
# Write-host "  dtOverlay: $dtOverlay"
# Write-host "  configTxtPath: $configTxtPath"

# $user = "pistomp"
# $group = "jack"
# $jackUser = "jack"
# $setupfolder = "../../setup"
# $jackFolder = "$setupfolder/mod"
# $servicesToDisable = @("bluetooth","dnsmasq","exim4","fluidsynth")

# $cockPitPackages = @("cockpit","cockpit-packagekit","cockpit-storaged","cockpit-networkmanager")
# $mainPackages = @("virtualenv","python3-pip","python3-dev","python3-zeroconf","build-essential","libasound2-dev","libjack-jackd2-dev","liblilv-dev","libjpeg-dev","zlib1g-dev","cmake","debhelper","dh-autoreconf","dh-python","gperf","intltool","ladspa-sdk","libarmadillo-dev","libavahi-gobject-dev","libavcodec-dev","libavutil-dev","libbluetooth-dev","libboost-dev","libeigen3-dev","libfftw3-dev","libglib2.0-dev","libglibmm-2.4-dev","libgtk2.0-dev","libgtkmm-2.4-dev","liblrdf0-dev","libsamplerate0-dev","libsigc++-2.0-dev","libsndfile1-dev","libzita-convolver-dev","libzita-resampler-dev","lv2-dev","p7zip-full","python3-all","python3-setuptools","libreadline-dev","zita-alsa-pcmi-utils","hostapd","dnsmasq","iptables","python3-smbus","liblo-dev","python3-liblo","libzita-alsa-pcmi-dev","authbind","libfluidsynth-dev","lockfile-progs","tree")
# $otherPackages = @("liblilv-dev","lv2-dev","libserd-dev","libsord-dev","libsratom-dev","lilv-utils","liblilv-0-0")
# $optionalPackages = @("virtualenv", "python3-venv", "python3-pip", "python3-dev", "python3-all", "python3-setuptools", "python3-zeroconf", "python3-smbus", "python3-liblo", "build-essential", "pkg-config", "cmake", "debhelper", "dh-autoreconf", "dh-python", "gperf", "intltool", "make", "libasound2-dev", "libjack-jackd2-dev", "libpulse-dev", "liblilv-dev", "libserd-dev", "libsord-dev", "libsratom-dev", "lilv-utils", "liblilv-0-0", "lv2-dev", "libfreetype6-dev", "libjpeg-dev", "libpng-dev", "libtiff5-dev", "zlib1g-dev", "libpng-dev", "libtiff5-dev", "libreadline-dev", "libssl-dev", "libffi-dev", "libarmadillo-dev", "libavahi-gobject-dev", "libavcodec-dev", "libavutil-dev", "libbluetooth-dev", "libboost-dev", "libeigen3-dev", "libfftw3-dev", "libglib2.0-dev", "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev", "liblrdf0-dev", "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev", "libzita-convolver-dev", "libzita-resampler-dev", "libzita-alsa-pcmi-dev", "zita-alsa-pcmi-utils", "libfluidsynth-dev", "librtmidi-dev", "ladspa-sdk", "liblo-dev", "p7zip-full", "authbind", "hostapd", "dnsmasq", "iptables", "lockfile-progs", "tree", "bc", "bison", "flex", "git", "curl")

# $sudoFoldersToCreate = @("/usr/mod/scripts")

#get the folder where the powershell script is not the bash script. 
$ErrorActionPreference = "Stop"
$scriptFile = $MyInvocation.MyCommand.Definition
write-host "Script file is $scriptFile"
$scriptDirectory = Split-Path -Path $scriptFile -Parent
write-host "Script folder is $scriptDirectory"
get-childitem -path "$scriptDirectory/includes" -recurse -filter *.ps1 |%{
    Write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}
Invoke-ChangeToDirectory -directory $scriptDirectory
. ./configuration.ps1 #contains New-PiStompConfiguration to create config object
$configuration = New-PiStompConfiguration

Write-Host "----------------------------------------"
Write-Host "Starting elevated host configuration script..."
Write-Host "----------------------------------------"
Test-Were_In_Expected_Directory -expectedDirectory $scriptDirectory
Write-Host "----------------------------------------"
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $shouldBeRoot
Write-Host "----------------------------------------"
Get-OSRelease #sets global variables from /etc/os-release
Write-Host "----------------------------------------"
if ($InstallAudio)
{
    Write-Host "Installing audio configuration..."
    $dtOverlay = $configuration.DtOverlay
    $configTxtPath = $configuration.ConfigTxtPath
    $alsaDeviceName = $configuration.AlsaDeviceName
    Install-Audio -dtOverlay $dtOverlay -configTxtPath $configTxtPath -alsaDeviceName $alsaDeviceName
    Write-Host "----------------------------------------"
}
if ($InstallCockpit)
{
    $cockPitPackages = $configuration.CockPitPackages
    write-host "Installing cockpit packages..." 
    Invoke-PackageInstall -packagestoBeInstalled $cockPitPackages
    Write-Host "----------------------------------------"
}
if ($InstallAudioPackages)
{
    Write-Host "Creating audio configuration..."
    Invoke-AudioUserAndGroupConfiguration -group $configuration.Group -user $configuration.User -jackUser $configuration.JackUser
    Write-Host "----------------------------------------"
    New-Folders -foldersToCreate $configuration.SudoFoldersToCreate
    $audioPackages = $configuration.AudioPackages
    write-host "Installing audio packages..."
    Invoke-PackageInstall -packagestoBeInstalled $audioPackages
    Write-Host "----------------------------------------"
    
}
if ($createPythonVirtualEnvironment)
{
    write-host "getting python version..."
    $pythonVersion = Get-PythonVersion #for python version we only need the major.minor part, eg 3.11. use regex to get named group for major.minor
    Write-Host "----------------------------------------"
    Write-Host "Setting up python virtual environment..."
    Invoke-InstallPythonPackages -pythonPackageInstallationScript $configuration.PythonPackageInstallationScript
    Write-Host "----------------------------------------"
    Write-Host "patching python files for compatibility..."
    Invoke-PatchPythonFiles -pythonVersion $pythonVersion -venvPath "$($HOME)/.env"
    Write-Host "----------------------------------------"
}
if ($ConfigureAudioServicesSystemd)
{
    Write-Host "Applying authbind configuration..."
    Invoke-AuthBindConfiguration -user $configuration.User -jackFolder $configuration.JackFolder
    New-SystemDServices -servicesUnitFileFolder $configuration.AudioServicesUnitFileFolder
   
}
    
if ($InstallUserDataFiles)
{
    write-host "Creating user data files and folders..."
    Remove-UserdataFolders
    New-LinkedFolders
    write-host "creating data folders..."
    New-Folders -foldersToCreate $configuration.FoldersToCreate
    Write-Host "Checking out required repos..."
    Invoke-CheckoutGitRepos -repos $configuration.Repos
    Write-Host "cleaning up pedalboards directory..."
    Remove-UnrelatedFilesFromUserDataFolder -directory $configuration.PedalboardsDirectory
    Write-Host "cleaning up user files directory..."
    Remove-UnrelatedFilesFromUserDataFolder -directory $configuration.UserFilesDirectory -filesToRemoveFromUserFolders $configuration.FilesToRemoveFromUserFolders

    Write-Host "----------------------------------------"
}
if ($StartAudioServices)
{
    Write-Host "Starting audio services..."
    Start-SystemDServices -services $configuration.AudioServicesToInstall
    Write-Host "----------------------------------------"
}
# Write-Host "----------------------------------------"
# write-host "Installing main packages..." 
# Invoke-PackageInstall -packagestoBeInstalled $mainPackages
# Write-Host "----------------------------------------"
# write-host "Installing other packages..." 
# Invoke-PackageInstall -packagestoBeInstalled $otherPackages
# Write-Host "----------------------------------------"
# if ($installOptionalPackages)
# {
#     Write-Host "Installing optional packages..." -ForegroundColor Green
#     Invoke-PackageInstall -packagestoBeInstalled $optionalPackages
#     Write-Host "----------------------------------------"
# }
# write-host "Disabling unused services..."
# Disable-Services -servicesToDisable $servicesToDisable
# Write-Host "----------------------------------------"
# Write-Host "creating sudo folders..."
# New-Folders -FoldersToCreate $sudoFoldersToCreate
# Write-Host "----------------------------------------"
# Write-Host "Creating audio configuration..."
# Invoke-AudioUserAndGroupConfiguration -group $group -user $user -jackUser $jackUser
# Write-Host "----------------------------------------"
# Write-Host "Applying JACK configuration..."
# Invoke-JackConfiguration -user $user -jackUser $jackUser -jackFolder $jackFolder
# Write-Host "----------------------------------------"
# write-host "Installing audio software..."
# Invoke-InstallAudioSoftware
# write-host "----------------------------------------"
# write-host "Elevated OS configuration complete"