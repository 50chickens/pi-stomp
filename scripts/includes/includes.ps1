function Test-WorkingDirectory($workingDirectory)
{
    write-host "----------------------------------------"
    write-host "Testing if working directory is $workingDirectory."
    Write-Host "Checking current folder: $($(pwd).Path)"
    if (((pwd).Path) -ne "$workingDirectory")
    {
        Write-Host "$((pwd).Path) is not the right directory."
        exit 1
    }
    else
    {
        Write-Host "You are in the correct folder ($workingDirectory)." -ForegroundColor Green
    }
}
function Get-OSRelease()
{
    Get-Content -Path "/etc/os-release" |%{
       $parts = $_ -split '='
       if ($parts.Length -eq 2) {
           $key = $parts[0].Trim()
           $value = $parts[1].Trim('"')
           Write-Verbose "setting variable $key to $value."
           Set-Variable -Name $key -Value $value -Scope Global
       }
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
