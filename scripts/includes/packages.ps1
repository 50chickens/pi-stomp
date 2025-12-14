function Invoke-PackageInstall($packageList)
{
    $expandedPackageList = $packageList -join " "
    write-verbose "Installing packages: $expandedPackageList"
    apt-get -y install $packageList   
}
function Invoke-InstallCockpit() 
{
    #check if cockpit is already installed. print it's version as well 
    $cockpitInstalled = dpkg -l | Select-String -Pattern "cockpit"
    if ($cockpitInstalled) 
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