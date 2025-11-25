#!/usr/bin/env pwsh

# This file is part of pi-stomp.
#
# pi-stomp is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pi-stomp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pi-stomp.  If not, see <https://www.gnu.org/licenses/>.

# check the device tree overlay is setup correctly ...
# firstly disable PWM audio
# Disable PWM audio by commenting out dtparam=audio in config.txt


# Central ALSA test function (kept in configure-host so callers here can use it)
function Test-AudioDeviceExistsInAlsa([string]$audioDeviceName) {
    write-host "Checking for audio device matching pattern '$audioDeviceName' in ALSA"
    try {
        $alsactlOutput = & alsactl info 2>&1
    }
    catch {
        Write-Host "Failed to run 'alsactl info': $_" -ForegroundColor Yellow
        return $false
    }
    if (-not $alsactlOutput) {
        Write-Host "'alsactl info' returned no output; cannot detect audio devices." -ForegroundColor Yellow
        return $false
    }
    $foundMatches = $alsactlOutput |? {$_ -imatch $audioDeviceName}

    if ($foundMatches) {
        write-host "Found matching audio device(s):"
        $foundMatches |% { write-host "  $_" }
        return $true
    }
    else {
        write-host "No matching audio device found for pattern '$audioDeviceName'"
    }
    return $false
}

function Disable-BuiltInHdmiaudio($configTxtPath)
{
    
    $pattern = "dtoverlay=vc4-kms-v3d" # should match dtoverlay=vc4-kms-v3d only if it is an exact match 
    $replacement = "dtoverlay=vc4-kms-v3d,noaudio"
    $fileContent = Get-Content -Path $configTxtPath -Raw
        
    #return true is there are any lines that match the pattern exactly, otherwise false
    $hdmiAudioEnabled = (($fileContent |? {$_ -imatch $replacement}).Count -ne 1) -and (($fileContent |? {$_ -imatch $pattern}).Count -ge 1)
    if ($hdmiAudioEnabled) 
    {
        Write-Host "found vc4-kms-v3d overlay without noaudio; disabling HDMI audio"
        $replacedContent = $fileContent -replace $pattern, $replacement 
        $replacedContent | Set-Content -Path $configTxtPath
    }
    else 
    {
        Write-Host "HDMI audio already disabled or vc4-kms-v3d overlay not present; no changes made"
        return
    }
    
}

function Disable-BuiltInAudio($configTxtPath)
{
    $pattern = "dtparam=audio=on" # should match dtoverlay=vc4-kms-v3d only if it is an exact match 
    $replacement = "dtparam=audio=off"
    $fileContent = Get-Content -Path $configTxtPath -Raw
        
    #return true is there are any lines that match the pattern exactly, otherwise false
    $targetStateExists = ($fileContent |? {$_ -imatch $replacement}).Count -ne 1
    $onboardAudioDisabled = (($fileContent |? {$_ -imatch $replacement}).Count -ne 1 -and (($fileContent |? {$_ -imatch $pattern}).Count -ne 1))
    if ($onboardAudioDisabled) 
    {
        Write-Host "Onboard audio already disabled; no changes made"
        return
    }
    
    Write-Host "Found dtparam=audio=on; disabling onboard audio"
    $replacedContent = $fileContent -replace $pattern, $replacement 
    $replacedContent | Set-Content -Path $configTxtPath

}

function Enable-AudioOverlay($overlayName, $configTxtPath)
{

    $replacement = "dtoverlay=$overlayName"
    $pattern = "dtoverlay=$overlayName"
    $fileContent = Get-Content -Path $configTxtPath -Raw
        
    #return true is there are any lines that match the pattern exactly, otherwise false
    $overlayEnabled = (($fileContent |? {$_ -imatch $replacement}).Count -ne 1) -and (($fileContent |? {$_ -imatch $pattern}).Count -eq 0)
    if ($overlayEnabled) 
    {
        Write-Host "didn't find overlay $overlayName ; enabling it"
        $replacement | Add-Content -Path $configTxtPath
    }
    else 
    {
        Write-Host "Overlay $overlayName already enabled."
        return
    }
}