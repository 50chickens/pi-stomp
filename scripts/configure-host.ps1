param (
    [string] $VERSION_CODENAME,
    [string] $workingDirectory
    )   


$includesFolder = "includes"
get-childitem -path $includesFolder/*.ps1 |% { 
    write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

$requiredOverlays = @(
"iqaudio-codec"#,
#"hifiberry-dacplusadc",
#"audioinjector-wm8731-audio"
)

Set-WorkingDirectory -workingdirectory $workingDirectory

write-host "----------------------------------------"
write-host "Starting audio configuration..."

$configTxtPath = "/boot/firmware/config.txt"
write-host "----------------------------------------"
write-host "testing for existing iqaudio device in ALSA..."
$audioDeviceExists = Test-AudioDeviceExistsInAlsa -audioDeviceName "iqaudio"
write-host "disabling built-in HDMI audio and built-in audio..."
Disable-BuiltInHdmiaudio -configTxtPath $configTxtPath
write-host "disabling built-in audio..."
Disable-BuiltInAudio -configTxtPath $configTxtPath
$requiredOverlays |%{
    write-host "Ensuring audio overlay $_ is enabled in $configTxtPath..."
    Enable-AudioOverlay -configTxtPath $configTxtPath -overlayName $_    
    if ($audioDeviceExists) {
        Write-Host "overlay $_ was already detected before changes to $configTxtPath."
    }
    else {
        write-host "Overlay $_ enabled in $configTxtPath. You may need to reboot for it to take effect."
    }
    
}
write-host "Audio configuration complete."
#reboot required after this.
