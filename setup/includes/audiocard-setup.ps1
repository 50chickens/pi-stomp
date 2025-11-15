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

function Disable-BuiltInAudio($configTxtPath)
{

    $dtparamPattern = "^\s*dtparam=audio"
    $dtparamReplacement = "#dtparam=audio"

    $msgNoChange = "No dtparam=audio line found in $configTxtPath; nothing to change."
    $msgWork = "Disabled dtparam=audio in $configTxtPath"

    Invoke-RegexReplacementOnfile -FilePath $configTxtPath -MatchRegex $dtparamPattern -Replacement $dtparamReplacement -NoWorkMessage $msgNoChange -WorkMessage $msgWork | Out-Null
}
function Disable-BuiltInHdmiaudio($configTxtPath)
{
    
    # match lines beginning with optional space then dtoverlay= that mention vc4-kms-v3d
    $vc4Pattern = "^\s*dtoverlay\s*=.*vc4-kms-v3d"
    $vc4Replacement = "dtoverlay=vc4-kms-v3d,noaudio"

    $msgNoVc4 = "No vc4-kms-v3d overlay found; nothing to change."
    $msgWork = "Patched $configTxtPath to set $vc4Replacement."

    Invoke-RegexReplacementOnfile -FilePath $configTxtPath -MatchRegex $vc4Pattern -Replacement $vc4Replacement -NoWorkMessage $msgNoVc4 -WorkMessage $msgWork | Out-Null
}

# Note: ALSA device testing moved to configure-host.ps1 to keep this file focused.
function Enable-AudioOverlay($overlayName, $configTxtPath)
{
    Write-Host "Enabling overlay for $overlayName"
    $content = Get-Content -Path $configTxtPath -Raw
    $overlayExact = "dtoverlay=$overlayName"

    # match any supported audio overlay line (case-insensitive, multiline aware)
    $overlayPattern = "(?im)^\s*dtoverlay\s*=.*(?:" + $possibleOverlays + ").*" 
    $canonicalLine = "dtoverlay=$overlayName`n"
    $msgOverlayPresent = "Audio overlay $overlayName already present in $configTxtPath"
    $msgUpdated = "Updated overlay to $overlayName in $configTxtPath"
    $msgAdding = "Adding audio overlay $overlayName to $configTxtPath"
    $msgAdded = "Added overlay $overlayName to $configTxtPath"
    if ($content -match $overlayExact) {
        Write-Host $msgOverlayPresent 
        return
    }

        # If a supported audio overlay exists, replace it with a canonical one.
        if ($content -match $overlayPattern) {
            Invoke-RegexReplacementOnfile -FilePath $configTxtPath -MatchRegex $overlayPattern -Replacement $canonicalLine -NoWorkMessage $msgOverlayPresent -WorkMessage $msgUpdated | Out-Null
            return
        }

    Write-Host $msgAdding 
    # ensure we append a trailing newline when adding a new line
    Add-Content -Path $configTxtPath -Value ("dtoverlay=$overlayName`n")
    Write-Host $msgAdded 
}