function New-Folders($foldersToCreate, $baseFolder)
{ 
    $foldersToCreate |%{
        $folderToCreate = $_
        if (![string]::IsNullOrEmpty($baseFolder))
        {
            write-host ""
            $fullPath = Join-Path -Path $baseFolder -ChildPath $folderToCreate
        }
        else {
            $fullPath = $folderToCreate
        }
        #create folder if it does not exist 
        if (-not (Test-Path -Path $fullPath -PathType Container))
        {
            New-Item -ItemType Directory -Path $fullPath | Out-Null
            Write-Host "Created folder: $fullPath" -ForegroundColor Green
        }
        else
        {
            Write-Host "Folder already exists: $fullPath" -ForegroundColor Green
        }
    }
}
function New-lv2pluginsfolder()
{
    if (Test-Path -Path "~/data/.lv2")
    {
        Write-Host "~/data/.lv2 folder already exists .Removing" -ForegroundColor Yellow
        remove-item -force ~/data/.lv2 #remove item won't remove symlinks where the target is missing.
    }
    Write-Host "linking ~/data/.lv2 folder to ~/.lv2" -ForegroundColor Green
    ln -s ~/.lv2 ~/data/.lv2
}