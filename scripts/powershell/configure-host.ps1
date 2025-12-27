param(
        $dtOverlay,
        $configTxtPath
)
$ErrorActionPreference = "Stop"

Write-host "Audio configuration script started with parameters:"
Write-host "  dtOverlay: $dtOverlay"
Write-host "  configTxtPath: $configTxtPath"

$user = "pistomp"
$group = "jack"
$jackUser = "jack"
$jackFolder = "../../setup/mod"
$servicesToDisable = @("bluetooth","dnsmasq","exim4")
$cockPitPackages = @("cockpit","cockpit-packagekit","cockpit-storaged","cockpit-networkmanager")

$mainPackages = @("virtualenv","python3-pip","python3-dev","python3-zeroconf","build-essential","libasound2-dev","libjack-jackd2-dev","liblilv-dev","libjpeg-dev","zlib1g-dev","cmake","debhelper","dh-autoreconf","dh-python","gperf","intltool","ladspa-sdk","libarmadillo-dev","libavahi-gobject-dev","libavcodec-dev","libavutil-dev","libbluetooth-dev","libboost-dev","libeigen3-dev","libfftw3-dev","libglib2.0-dev","libglibmm-2.4-dev","libgtk2.0-dev","libgtkmm-2.4-dev","liblrdf0-dev","libsamplerate0-dev","libsigc++-2.0-dev","libsndfile1-dev","libzita-convolver-dev","libzita-resampler-dev","lv2-dev","p7zip-full","python3-all","python3-setuptools","libreadline-dev","zita-alsa-pcmi-utils","hostapd","dnsmasq","iptables","python3-smbus","liblo-dev","python3-liblo","libzita-alsa-pcmi-dev","authbind","libfluidsynth-dev","lockfile-progs","tree")
$otherPackages = @("liblilv-dev","lv2-dev","libserd-dev","libsord-dev","libsratom-dev","lilv-utils","liblilv-0-0")
$optionalPackages = @("virtualenv", "python3-venv", "python3-pip", "python3-dev", "python3-all", "python3-setuptools", "python3-zeroconf", "python3-smbus", "python3-liblo", "build-essential", "pkg-config", "cmake", "debhelper", "dh-autoreconf", "dh-python", "gperf", "intltool", "make", "libasound2-dev", "libjack-jackd2-dev", "libpulse-dev", "liblilv-dev", "libserd-dev", "libsord-dev", "libsratom-dev", "lilv-utils", "liblilv-0-0", "lv2-dev", "libfreetype6-dev", "libjpeg-dev", "libpng-dev", "libtiff5-dev", "zlib1g-dev", "libpng-dev", "libtiff5-dev", "libreadline-dev", "libssl-dev", "libffi-dev", "libarmadillo-dev", "libavahi-gobject-dev", "libavcodec-dev", "libavutil-dev", "libbluetooth-dev", "libboost-dev", "libeigen3-dev", "libfftw3-dev", "libglib2.0-dev", "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev", "liblrdf0-dev", "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev", "libzita-convolver-dev", "libzita-resampler-dev", "libzita-alsa-pcmi-dev", "zita-alsa-pcmi-utils", "libfluidsynth-dev", "librtmidi-dev", "ladspa-sdk", "liblo-dev", "p7zip-full", "authbind", "hostapd", "dnsmasq", "iptables", "lockfile-progs", "tree", "bc", "bison", "flex", "git", "curl")

$sudoFoldersToCreate = @("/usr/mod/scripts")

#get the folder where the powershell script is not the bash script. 
$expectedDirectory = $MyInvocation.MyCommand.Definition | Split-Path -Parent
write-host "Current script path: $expectedDirectory" 
push-location $expectedDirectory
Write-Verbose "Changed location to script folder: $expectedDirectory"

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

$parametersToValidate = @(
    @{ Value = $dtOverlay; Name = "dtOverlay" },
    @{ Value = $configTxtPath; Name = "configTxtPath" }
)

foreach ($param in $parametersToValidate) 
{
    Test-ScriptParametersAreValid -paramValue $param.Value -paramName $param.Name
}

function Invoke-AudioUserAndGroupConfiguration($group, $user, $jackUser)
{
    write-host "Configuring audio users and groups for user $user, group $group, jack user $jackUser"
    # Create jack user and group if they don't exist
    if ($null -eq (getent group $jackUser)) 
    {
        Write-Host "Creating system group: jack"
        groupadd --system $jackUser
    }
    if ($null -eq (getent passwd $jackUser)) 
    {
        Write-Host "Creating system user: $jackUser"
        adduser --no-create-home --system --group jack $jackUser
    }

    $groupsToAdd = @(
        @{ User = "$user"; Group = $jackUser },
        @{ User = "$user"; Group = "audio" },
        @{ User = "root"; Group = $jackUser },
        @{ User = $jackUser; Group = "audio" }
    )

    foreach ($groupAdd in $groupsToAdd) 
    {
        $isInGroup = id -nG $($groupAdd.User) | grep -qw $($groupAdd.Group)
        if (-not $isInGroup) 
        {
            Write-Host "Adding user $($groupAdd.User) to group $($groupAdd.Group)"
            usermod -aG $($groupAdd.Group) $($groupAdd.User)
        } 
        else 
        {
            Write-Host "User $($groupAdd.User) is already in group $($groupAdd.Group)"
        }
    }
}
function Invoke-JackConfiguration($user, $jackUser, $jackFolder)
{
    write-host "Configuring JACK settings for user $user and jack user $jackUser. Jack folder: $jackFolder"
    # Copy and configure jackdrc
    if (Test-Path "/etc/jackdrc")
    {
        write-Host "Removing existing /etc/jackdrc"
        rm -f /etc/jackdrc
    } 
    Write-Host "Copying jackdrc to /etc/"
    cp "$jackFolder/jackdrc" /etc/
    chmod +x /etc/jackdrc
    $chown = @($jackUser,$jackUser) -join ":"
    Write-Host "Setting ownership of /etc/jackdrc to $chown"
    chown $chown /etc/jackdrc

    if (Test-Path "/etc/authbind/byport/80")
    {
        write-Host "Removing existing /etc/authbind/byport/80"
        rm -f /etc/authbind/byport/80
    }
    Write-Host "Copying authbind configuration for port 80"
    cp "$jackFolder/80" /etc/authbind/byport/
    chmod 500 /etc/authbind/byport/80
    Write-Host "Setting ownership of /etc/authbind/byport/80 to $user"
    $chown = @($user,$user) -join ":"
    chown $chown /etc/authbind/byport/80
}

Write-Host "----------------------------------------"
Write-Host "Starting elevated host configuration script..."
Write-Host "----------------------------------------"
Test-Were_In_Expected_Directory -expectedDirectory $expectedDirectory
Write-Host "----------------------------------------"
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $true
Write-Host "----------------------------------------"
Get-OSRelease #sets global variables from /etc/os-release
Write-Host "----------------------------------------"
write-host "Configuring audio settings..." 
Install-Audio -dtOverlay $dtOverlay -configTxtPath $configTxtPath
Write-Host "----------------------------------------"
write-host "Installing cockpit packages..." 
Invoke-PackageInstall -packagestoBeInstalled $cockPitPackages
Write-Host "----------------------------------------"
write-host "Installing main packages..." 
Invoke-PackageInstall -packagestoBeInstalled $mainPackages
Write-Host "----------------------------------------"
write-host "Installing other packages..." 
Invoke-PackageInstall -packagestoBeInstalled $otherPackages
Write-Host "----------------------------------------"
if ($installOptionalPackages)
{
    Write-Host "Installing optional packages..." -ForegroundColor Green
    Invoke-PackageInstall -packagestoBeInstalled $optionalPackages
    Write-Host "----------------------------------------"
}
write-host "Disabling unused services..."
Disable-Services -servicesToDisable $servicesToDisable
Write-Host "----------------------------------------"
Write-Host "creating sudo folders..."
New-Folders -FoldersToCreate $sudoFoldersToCreate
Write-Host "----------------------------------------"
Write-Host "Creating audio configuration..."
Invoke-AudioUserAndGroupConfiguration -group $group -user $user -jackUser $jackUser

Write-Host "----------------------------------------"
Invoke-JackConfiguration -user $user -jackUser $jackUser -jackFolder $jackFolder
write-host "Elevated OS configuration complete"