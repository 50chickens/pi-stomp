param (
    [string] $VERSION_CODENAME,
    [string] $workingDirectory
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

$mainPackages = @("virtualenv","python3-pip","python3-dev","python3-zeroconf","build-essential","libasound2-dev","libjack-jackd2-dev","liblilv-dev","libjpeg-dev","zlib1g-dev","cmake","debhelper","dh-autoreconf","dh-python","gperf","intltool","ladspa-sdk","libarmadillo-dev","libavahi-gobject-dev","libavcodec-dev","libavutil-dev","libbluetooth-dev","libboost-dev","libeigen3-dev","libfftw3-dev","libglib2.0-dev","libglibmm-2.4-dev","libgtk2.0-dev","libgtkmm-2.4-dev","liblrdf0-dev","libsamplerate0-dev","libsigc++-2.0-dev","libsndfile1-dev","libzita-convolver-dev","libzita-resampler-dev","lv2-dev","p7zip-full","python3-all","python3-setuptools","libreadline-dev","zita-alsa-pcmi-utils","hostapd","dnsmasq","iptables","python3-smbus","liblo-dev","python3-liblo","libzita-alsa-pcmi-dev","authbind","rcconf","libfluidsynth-dev","lockfile-progs","tree")

$otherPackages = @("liblilv-dev","lv2-dev","libserd-dev","libsord-dev","libsratom-dev","lilv-utils","liblilv-0-0")

$optionalPackages = @("virtualenv", "python3-venv", "python3-pip", "python3-dev", "python3-all", "python3-setuptools", "python3-zeroconf", "python3-smbus", "python3-liblo", "build-essential", "pkg-config", "cmake", "debhelper", "dh-autoreconf", "dh-python", "gperf", "intltool", "make", "libasound2-dev", "libjack-jackd2-dev", "libpulse-dev", "liblilv-dev", "libserd-dev", "libsord-dev", "libsratom-dev", "lilv-utils", "liblilv-0-0", "lv2-dev", "libfreetype6-dev", "libjpeg-dev", "libpng-dev", "libtiff5-dev", "zlib1g-dev", "libpng-dev", "libtiff5-dev", "libreadline-dev", "libssl-dev", "libffi-dev", "libarmadillo-dev", "libavahi-gobject-dev", "libavcodec-dev", "libavutil-dev", "libbluetooth-dev", "libboost-dev", "libeigen3-dev", "libfftw3-dev", "libglib2.0-dev", "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev", "liblrdf0-dev", "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev", "libzita-convolver-dev", "libzita-resampler-dev", "libzita-alsa-pcmi-dev", "zita-alsa-pcmi-utils", "libfluidsynth-dev", "librtmidi-dev", "ladspa-sdk", "liblo-dev", "p7zip-full", "authbind", "hostapd", "dnsmasq", "iptables", "lockfile-progs", "tree", "bc", "bison", "flex", "git", "curl")

function Test-CurrentUserHasRootPermission()
{
    $uid = & id -u 2>$null 
    if (-not $uid -or [int]$uid -ne 0) 
    {
        Write-Host "Current user does not have root privileges. uid=$uid" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Have root privileges - either running as root, or under sudo. this is good." -ForegroundColor Green
    
}


# ensure the script is running as root (UID 0)

if (-not $uid -or [int]$uid -ne 0) {
    Write-Host "This script must be run as root. Please run with sudo." -ForegroundColor Yellow
    exit 1
}

Test-CurrentUserHasRootPermission

#Invoke-PackageInstall -packageList $mainPackages
# Invoke-PackageInstall -packageList $otherPackages

# if ($installOptionalPackages)
# {
#     Write-Host "Installing optional packages..."
#     Invoke-PackageInstall -packageList $optionalPackages
# }

# $unusedServices |% {
#     Disable-UnusedService -serviceName $_
# }
