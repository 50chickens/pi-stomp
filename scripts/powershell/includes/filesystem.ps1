function New-Folder($folderToCreate, $baseFolder) 
{
    if (![string]::IsNullOrEmpty($baseFolder))
    {
        $fullPath = Join-Path -Path $baseFolder -ChildPath $folderToCreate
    }
    else 
    {
        $fullPath = $folderToCreate
    }
    #create folder if it does not exist 
    if (-not (Test-Path -Path $fullPath))
    {
        New-Item -ItemType Directory -Path $fullPath | Out-Null
        Write-Host "Created folder: $fullPath" -ForegroundColor Green
    }
    else
    {
        Write-Host "Folder already exists: $fullPath" -ForegroundColor Green
    }
}
function New-Folders($foldersToCreate, $baseFolder)
{ 
    $foldersToCreate |%{
        $folderToCreate = $_
        New-Folder -folderToCreate $folderToCreate -baseFolder $baseFolder
    }
}
function New-LinkedFolder($folderName)
{
    if (Test-Path -Path "~/data/$folderName")
    {
        Write-Host "~/data/$folderName folder already exists .Removing" -ForegroundColor Yellow
        remove-item -force ~/data/$folderName #remove item won't remove symlinks where the target is missing.
    }
    Write-Host "linking ~/data/$folderName folder to ~/$folderName" -ForegroundColor Green
    ln -s ~/$folderName ~/data/$folderName
}
function New-LinkedFolders($linkedFolders)
{
    $linkedFolders |%{
        New-LinkedFolder -folderName $_
    }
}