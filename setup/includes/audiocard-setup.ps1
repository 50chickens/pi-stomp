#!/bin/bash

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

function Disable-BuiltInAudio()
{
    (Get-Content -Path "/boot/firmware/config.txt") -replace '^\s*dtparam=audio', '#dtparam=audio' | Set-Content -Path "/boot/firmware/config.txt"
}

function Enable-AudioOverlay($dtOverlayName = "iqaudio-codec")
{

    $firmwarePath = "/boot/firmware/config.txt"
    $possibleOverlays = "iqaudio-codec|hifiberry-dacplusadc|audioinjector-wm8731-audio"
    $overlayAlreadyConfigured = (get-content -Path $firmwarePath) -match "dtoverlay=$dtOverlayName"

    if ($overlayAlreadyConfigured) 
    { 
        Write-Host "Audio overlay $dtOverlayName already present in $firmwarePath"
        return 
    }

    $audioOverlayExists = (get-content -Path $firmwarePath) -match "dtoverlay=$possibleOverlays"

    if ($audioOverlayExists) 
    { 
        Write-Host "Audio overlay already present in $firmwarePath but need updating to $dtOverlayName"
        Set-Content -Path $firmwarePath -Value ((Get-Content -Path $firmwarePath) -replace "$possibleOverlays", "$dtOverlayName")
        return
    }

    Write-host "Adding audio overlay $dtOverlayName to $firmwarePath"
    $newoverlayLine = "dtoverlay=$dtOverlayName" #| out-file -FilePath $firmwarePath -Append 
    write-host "Adding new line $newoverlayLine"
    Add-Content -Path $firmwarePath -Value $newoverlayLine
}