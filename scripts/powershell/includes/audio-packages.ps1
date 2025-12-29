function Install-AudioPackages($audioPackages)
{
    Write-Host "Installing audio packages: $($audioPackages -join ', ')"
    #create a list of any packages that are not already installed
    $packagesToInstall = @()
    foreach ($package in $audioPackages)
    {
        $packageInstalled = dpkg -l | Select-String -Pattern $package
        if (-not $packageInstalled) 
        {
            $packagesToInstall += $package
        }
        else 
        {
            Write-Host "Package $package is already installed."
        }
    }
    #if any packages need to be installed, install them
    if ($packagesToInstall.Count -eq 0)
    {
        Write-Host "All audio packages are already installed."
        return
    }
    Write-Host "Packages to install: $($packagesToInstall -join ', ')"  
    Invoke-PackageInstall -packageList $packagesToInstall
}
