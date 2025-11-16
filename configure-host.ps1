get-childitem -path ~/pi-stomp/setup/includes/*.ps1 |% { 
    write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

$requiredOverlays = @(
"iqaudio-codec"#,
#"hifiberry-dacplusadc",
#"audioinjector-wm8731-audio"
)
$correctFolderName = "$HOME/pi-stomp"
if (-not (Test-ImInTheCorrectFolder -correctFolderName $correctFolderName))
{
    write-host "switch to $correctFolderName"
    cd $correctFolderName
}
$configTxtPath = "/boot/firmware/config.txt"
$audioDeviceExists = Test-AudioDeviceExistsInAlsa -audioDeviceName "iqaudio"
Disable-BuiltInHdmiaudio -configTxtPath $configTxtPath
Disable-BuiltInAudio -configTxtPath $configTxtPath
$requiredOverlays |%{
    if ($audioDeviceExists) {
        Write-Host "Skipping enabling overlay $_ as audio device already detected in ALSA"
    }
    else {
        Enable-AudioOverlay -configTxtPath $configTxtPath -overlayName $_    
    }
    
}

#reboot required after this.
