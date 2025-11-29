function New-Folders($folderToCreate)
{ 
    #create folder if it does not exist 
    if (-not (Test-Path -Path $folderToCreate -PathType Container))
    {
        New-Item -ItemType Directory -Path $folderToCreate | Out-Null
        Write-Host "Created folder: $folderToCreate"
    }
    else
    {
        Write-Host "Folder already exists: $folderToCreate"
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
