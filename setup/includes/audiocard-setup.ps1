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

# Generic helper: apply a regex replace to a file and write back if it changes.
# Parameters:
#  -FilePath: full path to file
#  -MatchRegex: regex to search for (string, may include inline options like (?m))
#  -Replacement: replacement text (can include `n for newline)
#  -NoWorkMessage: message to print when no matches found
#  -WorkMessage: message to print when replacement is applied
function Invoke-RegexReplacementOnfile([string]$FilePath, [string]$MatchRegex, [string]$Replacement, [string]$NoWorkMessage, [string]$WorkMessage)
{
    $fileContent = Get-Content -Path $FilePath -Raw
    if (-not ($fileContent -match $MatchRegex)) {
        Write-Host $NoWorkMessage 
        return $false
    }

    $new = [regex]::Replace($fileContent, $MatchRegex, $Replacement)
    if ($new -ne $fileContent) {
        Set-Content -Path $FilePath -Value $new
        Write-Host $WorkMessage 
        return $true
    }

    Write-Host $NoWorkMessage 
    return $false
}

# function Disable-BuiltInAudio($configTxtPath)
# {

#     $dtparamPattern = "dtparam=audio=off"
#     $dtparamReplacement = "#dtparam=audio"

#     $msgNoChange = "No dtparam=audio line found in $configTxtPath; nothing to change."
#     $msgWork = "Disabled dtparam=audio in $configTxtPath"

#     Invoke-RegexReplacementOnfile -FilePath $configTxtPath -MatchRegex $dtparamPattern -Replacement $dtparamReplacement -NoWorkMessage $msgNoChange -WorkMessage $msgWork | Out-Null
# }
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
    write-host "targetStateExists: $targetStateExists"
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

    $replacement = "dtparam=$overlayName"
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