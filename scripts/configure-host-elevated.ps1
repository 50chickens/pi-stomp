param (
    [string] $VERSION_CODENAME,
    [string] $workingDirectory,
    [string] $requiredOverlay,
    [string] $alsaDeviceName
    )   

write-host "workingDirectory is $workingDirectory"
$includesFolder = "$workingDirectory/includes"
write-host "dot sourcing: $includesFolder"
$includefiles = get-childitem -path $includesFolder -recurse -filter *.ps1
if (-not $includefiles) {
    write-host "No include files found in $includesFolder" -ForegroundColor Yellow
    exit 1
}
get-childitem -path $includesFolder -recurse -filter *.ps1 |% { 
    write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

Set-WorkingDirectory -workingdirectory $workingDirectory

$unusedServices = @(
"bluetooth.service",
"dnsmasq.service",
"cockpit.socket",
"cockpit.service",
"exim4.service")

$mainPackages = @("virtualenv","python3-pip","python3-dev","python3-zeroconf","build-essential","libasound2-dev","libjack-jackd2-dev","liblilv-dev","libjpeg-dev","zlib1g-dev","cmake","debhelper","dh-autoreconf","dh-python","gperf","intltool","ladspa-sdk","libarmadillo-dev","libavahi-gobject-dev","libavcodec-dev","libavutil-dev","libbluetooth-dev","libboost-dev","libeigen3-dev","libfftw3-dev","libglib2.0-dev","libglibmm-2.4-dev","libgtk2.0-dev","libgtkmm-2.4-dev","liblrdf0-dev","libsamplerate0-dev","libsigc++-2.0-dev","libsndfile1-dev","libzita-convolver-dev","libzita-resampler-dev","lv2-dev","p7zip-full","python3-all","python3-setuptools","libreadline-dev","zita-alsa-pcmi-utils","hostapd","dnsmasq","iptables","python3-smbus","liblo-dev","python3-liblo","libzita-alsa-pcmi-dev","authbind","libfluidsynth-dev","lockfile-progs","tree")

$otherPackages = @("liblilv-dev","lv2-dev","libserd-dev","libsord-dev","libsratom-dev","lilv-utils","liblilv-0-0")

$optionalPackages = @("virtualenv", "python3-venv", "python3-pip", "python3-dev", "python3-all", "python3-setuptools", "python3-zeroconf", "python3-smbus", "python3-liblo", "build-essential", "pkg-config", "cmake", "debhelper", "dh-autoreconf", "dh-python", "gperf", "intltool", "make", "libasound2-dev", "libjack-jackd2-dev", "libpulse-dev", "liblilv-dev", "libserd-dev", "libsord-dev", "libsratom-dev", "lilv-utils", "liblilv-0-0", "lv2-dev", "libfreetype6-dev", "libjpeg-dev", "libpng-dev", "libtiff5-dev", "zlib1g-dev", "libpng-dev", "libtiff5-dev", "libreadline-dev", "libssl-dev", "libffi-dev", "libarmadillo-dev", "libavahi-gobject-dev", "libavcodec-dev", "libavutil-dev", "libbluetooth-dev", "libboost-dev", "libeigen3-dev", "libfftw3-dev", "libglib2.0-dev", "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev", "liblrdf0-dev", "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev", "libzita-convolver-dev", "libzita-resampler-dev", "libzita-alsa-pcmi-dev", "zita-alsa-pcmi-utils", "libfluidsynth-dev", "librtmidi-dev", "ladspa-sdk", "liblo-dev", "p7zip-full", "authbind", "hostapd", "dnsmasq", "iptables", "lockfile-progs", "tree", "bc", "bison", "flex", "git", "curl")


write-host "----------------------------------------"
write-host "Starting elevated host configuration script..."
write-host "----------------------------------------"
write-host "Testing for root permissions..."
Test-CurrentUserHasRootPermission
write-host "Root permission test passed."
write-host "Installing main packages..."
#Invoke-PackageInstall -packageList $mainPackages
write-host "Installing other packages..."
#Invoke-PackageInstall -packageList $otherPackages

if ($installOptionalPackages)
{
    Write-Host "Installing optional packages..."
    #Invoke-PackageInstall -packageList $optionalPackages
}
write-host "Disabling unused services..."
$unusedServices |% {
    Disable-UnusedService -serviceName $_
}

write-host "----------------------------------------"
write-host "Starting audio configuration..."

$configTxtPath = "/boot/firmware/config.txt"
write-host "----------------------------------------"
write-host "testing for existing iqaudio device in ALSA..."
$audioDeviceExists = Test-AudioDeviceExistsInAlsa -audioDeviceName $alsaDeviceName
write-host "disabling built-in HDMI audio and built-in audio..."
Disable-BuiltInHdmiaudio -configTxtPath $configTxtPath
write-host "disabling built-in audio..."
Disable-BuiltInAudio -configTxtPath $configTxtPath

write-host "Ensuring audio overlay $requiredOverlay is enabled in $configTxtPath..."
Enable-AudioOverlay -configTxtPath $configTxtPath -overlayName $requiredOverlay    
if ($audioDeviceExists) 
{
    Write-Host "overlay $requiredOverlay was already detected before changes to $configTxtPath."
}
else 
{
    write-host "Overlay $requiredOverlay enabled in $configTxtPath. You may need to reboot for it to take effect."
}
$sudoFoldersToCreate = @("/usr/mod/scripts")
New-Folders -foldersToCreate $sudoFoldersToCreate

write-host "Audio configuration complete."
write-host "Elevated host configuration script complete."
write-host "----------------------------------------"
