function Remove-UnrelatedFilesFromUserDataFolder($directory, $FilesToRemoveFromUserFolders)
{
    Write-Host "Cleaning up non-bundle files from directory $Directory" -ForegroundColor Cyan
    if (-not (Test-Path -Path $Directory)) 
    {
        Write-Host "Directory not found: $Directory" -ForegroundColor Yellow
        return
    }
    Get-ChildItem -Path $directory -Recurse |?{return $FilesToRemoveFromUserFolders -contains $_.Name} |%{remove-item -Path $_.FullName -Force -recurse}
    Get-ChildItem -Path $directory -Recurse -Hidden |?{return $FilesToRemoveFromUserFolders -contains $_.Name} |%{remove-item -Path $_.FullName -Force -recurse}
}

function Invoke-RestartAudioServices
{
    
    Write-Host "Restarting audio services..." -ForegroundColor Cyan
    $services = @(
        "mod-host",
        "mod-ui"
    )
    
    foreach ($service in $services) {
        Write-Host "  Restarting $service..." -ForegroundColor Yellow
        
        try {
            sudo systemctl restart $service 2>$null
            Start-Sleep -Seconds 2
            
            $status = systemctl is-active $service 2>$null
            if ($status -eq "active") {
                Write-Host "    $service restarted successfully" -ForegroundColor Green
            } else {
                Write-Host "    WARNING: $service may not have started properly" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    Error restarting $service : $_" -ForegroundColor Red
        }
    }
    
    Write-Host "Audio services restart complete" -ForegroundColor Green
}
