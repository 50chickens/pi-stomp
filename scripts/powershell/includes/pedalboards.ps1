function Remove-NonBundleFilesFromPedalboards
{
    <#
    .SYNOPSIS
    Remove non-bundle files from the pedalboards directory that can cause lilv scanning errors.
    
    .DESCRIPTION
    Removes README.md, LICENSE, and other non-.pedalboard files from the pedalboards directory
    that cause mod-ui to crash when lilv tries to scan them as plugin bundles.
    
    .PARAMETER PedalboardsDirectory
    The path to the pedalboards directory. Default: /home/pistomp/data/.pedalboards
    
    .EXAMPLE
    Remove-NonBundleFilesFromPedalboards
    #>
    
    param (
        [string]$PedalboardsDirectory = "$HOME/data/.pedalboards"
    )
    
    Write-Host "Cleaning up non-bundle files from pedalboards directory..." -ForegroundColor Cyan
    
    if (-not (Test-Path -Path $PedalboardsDirectory)) {
        Write-Host "Pedalboards directory not found: $PedalboardsDirectory" -ForegroundColor Yellow
        return
    }
    
    # List of non-bundle files to remove
    $filesToRemove = @(
        "README.md",
        "LICENSE",
        ".gitignore",
        ".git"
    )
    
    $removed = $false
    
    foreach ($file in $filesToRemove) {
        $fullPath = Join-Path -Path $PedalboardsDirectory -ChildPath $file
        
        if (Test-Path -Path $fullPath) {
            try {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Host "  Removed: $file" -ForegroundColor Green
                $removed = $true
            } catch {
                Write-Host "  Error removing $file : $_" -ForegroundColor Red
            }
        }
    }
    
    if (-not $removed) {
        Write-Host "  No non-bundle files found to remove" -ForegroundColor Yellow
    }
    
    Write-Host "Pedalboards cleanup complete" -ForegroundColor Green
}

function Invoke-RestartAudioServices
{
    <#
    .SYNOPSIS
    Restart mod-host and mod-ui services in proper order.
    
    .DESCRIPTION
    Restarts mod-host first (to rescan plugins), then mod-ui (to refresh UI).
    Includes appropriate delays between restarts.
    
    .EXAMPLE
    Invoke-RestartAudioServices
    #>
    
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
