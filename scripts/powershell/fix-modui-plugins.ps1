#!/usr/bin/env pwsh

# Complete fix for mod-ui plugin loading issues

Write-Host "=== MOD-UI PLUGIN LOADING FIX ===" -ForegroundColor Cyan
Write-Host "This script fixes mod-ui crashes and plugin loading errors" -ForegroundColor Yellow

# Source the pedalboards functions
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$pedalboardsScript = Join-Path $scriptDir "includes/pedalboards.ps1"

if (Test-Path $pedalboardsScript) {
    . $pedalboardsScript
} else {
    Write-Host "Error: Could not find pedalboards.ps1 at $pedalboardsScript" -ForegroundColor Red
    exit 1
}

Write-Host "`n[Step 1] Cleaning up pedalboards directory..."
Remove-NonBundleFilesFromPedalboards -PedalboardsDirectory "$HOME/data/.pedalboards"

Write-Host "`n[Step 2] Restarting audio services..."
Write-Host "Note: This will require sudo authentication" -ForegroundColor Yellow
Invoke-RestartAudioServices

Write-Host "`n[Step 3] Verifying services are running..."
$services = @('mod-host', 'mod-ui', 'jack', 'browsepy')
$allRunning = $true
foreach ($svc in $services) {
    $status = systemctl is-active $svc 2>$null
    $color = if ($status -eq "active") { "Green" } else { "Red" }
    if ($status -ne "active") { $allRunning = $false }
    Write-Host "  $svc : $status" -ForegroundColor $color
}

if ($allRunning) {
    Write-Host "`n✓ SUCCESS: All services running" -ForegroundColor Green
    
    Write-Host "`n[Step 4] Verifying plugins are available..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost/effect/list" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $plugins = $response.Content | ConvertFrom-Json
            Write-Host "✓ Found $($plugins.Count) plugins available:" -ForegroundColor Green
            $plugins | ForEach-Object {
                Write-Host "  - $($_.name)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Warning: Could not verify plugins (web service may still be initializing)" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n✗ ERROR: Some services are not running" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== FIX COMPLETE ===" -ForegroundColor Cyan
Write-Host "You should now be able to load plugins in mod-ui" -ForegroundColor Green
