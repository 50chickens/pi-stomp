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

function New-PythonVenv($venvPath)
{
    # expand ~ to actual home path if provided
    if ($venvPath -imatch "~*") { $venvPath = $venvPath -replace '^~', $HOME }

    if (Test-Path -Path $venvPath -PathType Container)
    {
        Remove-Item -Recurse -Force $venvPath
        Write-Host "Removed existing python virtual environment at $venvPath"
    }
    else
    {
        Write-Host "No existing python virtual environment at $venvPath"
    }

    python3 -m venv $venvPath
    Write-Host "Created python virtual environment at $venvPath"
}



function New-Folders($foldersToCreate, $baseFolder, [switch] $sudo)
{ 
    write-verbose "baseFolder: $baseFolder"
    write-verbose "sudo: $sudo"
    foreach ($folder in $foldersToCreate) 
    {
        if ($baseFolder) 
        { 
            write-verbose "baseFolder is $baseFolder"
            $folder = "$baseFolder/$folder" 
        }
        write-verbose "testing for folder: $folder"
        if (-Not (Test-Path -Path $folder)) 
        {
            if ($sudo) 
            {
                Write-Host "Creating folder: $folder with sudo"
                sudo pwsh -c "New-Item -ItemType Directory -Path $folder -whatif" | Out-Null
                Write-Verbose "Created folder: $folder with sudo"
            } 
            else 
            {
                write-host "Creating folder: $folder"
                New-Item -ItemType Directory -Path $folder | Out-Null
                Write-Verbose "Created folder: $folder"
            }
        } 
        else 
        {
            Write-Host "Folder already exists: $folder"
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