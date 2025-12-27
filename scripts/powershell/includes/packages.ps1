function Get-Packages()
{
## Example dpkg -l --robot --no-pager output line:
##note the package name can have colons and dashes to make it more awesome.
# | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
# |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
# ||/ Name                                 Version                              Architecture Description
# +++-====================================-====================================-============-================================================================================
# ii  7zip                                 25.01+dfsg-1~deb13u1                 arm64        7-Zip file archiver with a high compression ratio
# ii  adduser                              3.152                                all          add and remove users and groups
# ii  adwaita-icon-theme                   48.1-1                               all          default icon theme of GNOME
##ii  libasound2-data                      1.2.14-1+rpt1                        all          Configuration files and profiles for ALSA drivers
##ii  libasound2-dev:arm64                 1.2.14-1+rpt1                        arm64        shared library for ALSA applications -- development files

$packageList = @()
$dpkgOutput = dpkg -l --robot --no-pager
$parsingPackages = $false
$packageListHeaderRegex = "^\+\+\+-=.+$"

$dpkgOutput |% {
        if (-not $parsingPackages) 
        {
            if ($_ -match $packageListHeaderRegex) 
            {
                $parsingPackages = $true
            }
            return
        }
        $packageLineRegex  = "^(?<status>\S{2})\s+(?<name>[\w\-\:\+\.]+)\s+(?<version>\S+)\s+(?<architecture>\S+)\s+(?<description>.+)$"
        if ($_ -match $packageLineRegex) 
        {
            $packageName = $Matches["name"].Trim().Replace(":"+$Matches["architecture"].Trim(),"")
            $packageVersion = $Matches["version"].Trim()
            $packageList += [PSCustomObject]@{
                Name = $packageName
                Version = $packageVersion
                Architecture = $Matches["architecture"].Trim()
                Description = $Matches["description"].Trim()
            }
        }
    }
    return $packageList
}
function Invoke-PackageInstall($packagestoBeInstalled)
{
    $existingPackages = get-packages #make sure we have the latest package list
    $packageList = @()
    foreach ($packageName in $packagestoBeInstalled) 
    {
        $package = $existingPackages |? { $_.Name -eq $packageName }
        if (-not $package) 
        {
            Write-host "Package $packageName not found on system, adding to apt-get install command line."
            $packageList += $packageName
        }
        else 
        {
            Write-Verbose "Package $packageName already installed (version $($package.Version)), not adding it apt-get install command line."
        }
    }
    if (-not $packageList -or $packageList.Count -eq 0) 
    {
        write-host "All packages in list are already installed, not calling apt-get to install them." -ForegroundColor Green
        return
    }

    $expandedPackageList = $packageList -join " "
    write-verbose "Installing packages: $expandedPackageList"
    apt-get -y install $packageList   
}
function Invoke-InstallCockpit() 
{
    #check if cockpit is already installed. print it's version as well 
    $packageisInstalled = dpkg -l | Select-String -Pattern "cockpit"
    if ($packageisInstalled) 
    {
        write-host "Found packages matching Cockpit already."
        dpkg -l |? {$_ -imatch "cockpit"} |% { write-host $_ }
        return
    }
    
    write-host "Displaying available cockpit versions in apt repos..."
    apt-cache policy cockpit

    write-host "Installing Cockpit web admin interface..."
    apt-get install -y cockpit
}