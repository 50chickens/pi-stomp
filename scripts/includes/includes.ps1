function Set-WorkingDirectory($workingDirectory)
{
    write-host "Checking current folder: $($(pwd).Path)"
    if (((pwd).Path) -ne "$workingDirectory")
    {
        write-host "$((pwd).Path) is not the right directory. Switching to $workingDirectory."
        cd $workingDirectory
    }
    else
    {
        write-host "You are in the correct folder ($workingDirectory)." -ForegroundColor Green
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
