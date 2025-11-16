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