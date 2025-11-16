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
    Enable-AudioOverlay -configTxtPath $configTxtPath -overlayName $_    
    if ($audioDeviceExists) {
        Write-Host "overlay $_ was already detected before changes to $configTxtPath."
    }
    else {
        write-host "Overlay $_ enabled in $configTxtPath. You may need to reboot for it to take effect."
    }
    
}

#reboot required after this.
