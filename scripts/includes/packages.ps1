function Invoke-PackageInstall($packageList)
{
    # $expandedPackageList = $packageList -join " "
    # write-verbose "Installing packages: $expandedPackageList"
    apt-get -y install $packageList   
}
