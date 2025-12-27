param(
        $dtOverlay,
        $configTxtPath,
        $workingDirectory
)
$ErrorActionPreference = "Stop"
Write-host "Audio configuration script started with parameters:"
Write-host "  dtOverlay: $dtOverlay"
Write-host "  configTxtPath: $configTxtPath"
Write-host "  workingDirectory: $workingDirectory"

function Test-ScriptParametersAreValid($paramValue, $paramName)
{ 
    if ([string]::IsNullOrEmpty($paramValue)) 
    { 
        throw "$paramName cannot be null or empty." 
    } 
}
$parametersToValidate = @(
    @{ Value = $dtOverlay; Name = "dtOverlay" },
    @{ Value = $configTxtPath; Name = "configTxtPath" },
    @{ Value = $workingDirectory; Name = "workingDirectory" }
)
foreach ($param in $parametersToValidate) 
{
    Test-ScriptParametersAreValid -paramValue $param.Value -paramName $param.Name
}

Write-Verbose "workingDirectory is $(pwd)."
$includesFolder = "$(pwd)/includes"
Write-Verbose "dot sourcing: $includesFolder"
if (-not (Test-Path -Path $includesFolder)) 
{
    write-host "Includes folder $includesFolder not found." -ForegroundColor Red
    exit 1
}
$includefiles = get-childitem -path $includesFolder -recurse -filter *.ps1
if (-not $includefiles) {
    write-host "No include files found in $includesFolder" -ForegroundColor Yellow
    exit 1
}
get-childitem -path $includesFolder -recurse -filter *.ps1 |% { 
    Write-Verbose "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

Write-Host "----------------------------------------"
Write-Host "Starting elevated host configuration script..."
Write-Host "----------------------------------------"

Test-WorkingDirectory -workingdirectory $workingDirectory
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $true
Get-OSRelease #sets global variables from /etc/os-release

$unusedServices = @("bluetooth","dnsmasq","exim4")
$cockPitPackages = @("cockpit","cockpit-packagekit","cockpit-storaged","cockpit-networkmanager")

$mainPackages = @("virtualenv","python3-pip","python3-dev","python3-zeroconf","build-essential","libasound2-dev","libjack-jackd2-dev","liblilv-dev","libjpeg-dev","zlib1g-dev","cmake","debhelper","dh-autoreconf","dh-python","gperf","intltool","ladspa-sdk","libarmadillo-dev","libavahi-gobject-dev","libavcodec-dev","libavutil-dev","libbluetooth-dev","libboost-dev","libeigen3-dev","libfftw3-dev","libglib2.0-dev","libglibmm-2.4-dev","libgtk2.0-dev","libgtkmm-2.4-dev","liblrdf0-dev","libsamplerate0-dev","libsigc++-2.0-dev","libsndfile1-dev","libzita-convolver-dev","libzita-resampler-dev","lv2-dev","p7zip-full","python3-all","python3-setuptools","libreadline-dev","zita-alsa-pcmi-utils","hostapd","dnsmasq","iptables","python3-smbus","liblo-dev","python3-liblo","libzita-alsa-pcmi-dev","authbind","libfluidsynth-dev","lockfile-progs","tree")
$otherPackages = @("liblilv-dev","lv2-dev","libserd-dev","libsord-dev","libsratom-dev","lilv-utils","liblilv-0-0")
$optionalPackages = @("virtualenv", "python3-venv", "python3-pip", "python3-dev", "python3-all", "python3-setuptools", "python3-zeroconf", "python3-smbus", "python3-liblo", "build-essential", "pkg-config", "cmake", "debhelper", "dh-autoreconf", "dh-python", "gperf", "intltool", "make", "libasound2-dev", "libjack-jackd2-dev", "libpulse-dev", "liblilv-dev", "libserd-dev", "libsord-dev", "libsratom-dev", "lilv-utils", "liblilv-0-0", "lv2-dev", "libfreetype6-dev", "libjpeg-dev", "libpng-dev", "libtiff5-dev", "zlib1g-dev", "libpng-dev", "libtiff5-dev", "libreadline-dev", "libssl-dev", "libffi-dev", "libarmadillo-dev", "libavahi-gobject-dev", "libavcodec-dev", "libavutil-dev", "libbluetooth-dev", "libboost-dev", "libeigen3-dev", "libfftw3-dev", "libglib2.0-dev", "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev", "liblrdf0-dev", "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev", "libzita-convolver-dev", "libzita-resampler-dev", "libzita-alsa-pcmi-dev", "zita-alsa-pcmi-utils", "libfluidsynth-dev", "librtmidi-dev", "ladspa-sdk", "liblo-dev", "p7zip-full", "authbind", "hostapd", "dnsmasq", "iptables", "lockfile-progs", "tree", "bc", "bison", "flex", "git", "curl")

write-host "Configuring audio settings..." 
Install-Audio -dtOverlay $dtOverlay -configTxtPath $configTxtPath

write-host "Installing cockpit packages..." 
Invoke-PackageInstall -packagestoBeInstalled $cockPitPackages

write-host "Installing main packages..." 
Invoke-PackageInstall -packagestoBeInstalled $mainPackages

write-host "Installing other packages..." 
Invoke-PackageInstall -packagestoBeInstalled $otherPackages

if ($installOptionalPackages)
{
    Write-Host "Installing optional packages..." -ForegroundColor Green
    Invoke-PackageInstall -packagestoBeInstalled $optionalPackages
}
write-host "Disabling unused services..."
$services = Get-Services
$unusedServices |% {
    $serviceToProcess = $_
    $service = $services |? { $_.Name -imatch $serviceToProcess}
    if (-not $service) 
    {
        write-host "Service $serviceToProcess not found on system, skipping." -ForegroundColor Yellow
        return
    }
    write-host "Found service: $($service.Name). Checking if it needs to be stopped/disabled..."
    Disable-UnusedService -service $service 
}

$sudoFoldersToCreate = @("/usr/mod/scripts")
$sudoFoldersToCreate |%{
    New-Folder -folderToCreate $_
}


write-host "Audio configuration complete."
write-host "Elevated host configuration script complete."
write-host "----------------------------------------"
