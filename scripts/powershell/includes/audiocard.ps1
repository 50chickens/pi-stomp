function Test-AudioDeviceExistsInAlsa($audioDeviceName) 
{
    if ([string]::IsNullOrEmpty($audioDeviceName)) 
    {
        Write-Error "audioDeviceName parameter cannot be null or empty."
        exit 1
    }
    write-host "Checking for audio device matching pattern '$audioDeviceName' in ALSA"
    try {
        $alsactlOutput = & alsactl info 2>&1
    }
    catch 
    {
        Write-Host "Failed to run 'alsactl info': $_" -ForegroundColor Yellow
        return $false
    }
    if (-not $alsactlOutput) 
    {
        Write-Host "'alsactl info' returned no output; cannot detect audio devices." -ForegroundColor Yellow
        return $false
    }
    $foundMatches = $alsactlOutput |? {$_ -imatch $audioDeviceName}

    if ($foundMatches) 
    {
        write-host "Found matching audio device(s):"
        $foundMatches |% { write-host "  $_" }
        return $true
    }
    else 
    {
        write-host "No matching audio device found for pattern '$audioDeviceName'"
    }
    return $false
}

function Disable-BuiltInHDMIaudio($configTxtPath)
{
    $inbuiltHDMI = "dtoverlay=vc4-kms-v3d" # should match dtoverlay=vc4-kms-v3d only if it is an exact match 
    $inbuiltHDMIWithAudioDisabled = "dtoverlay=vc4-kms-v3d,noaudio"
    $fileContent = Get-Content -Path $configTxtPath -Raw
    #check if $replacement exists
    $inbuiltHDMIAudioIsDisabled = ($fileContent |? {$_ -imatch $inbuiltHDMIWithAudioDisabled}).Count -ge 1
    if ($inbuiltHDMIAudioIsDisabled) 
    {
        Write-Host "HDMI audio already disabled; no changes made" -ForegroundColor Green
        return $false
    }
    #if exists pattern
    $inbuiltHDMIExists = ($fileContent |? {$_ -imatch $inbuiltHDMI}).Count -ge 1
    #do replacement 
    if (!$inbuiltHDMIExists)
    {
        Add-Content -Path $configTxtPath -Value $inbuiltHDMIWithAudioDisabled
        Write-Host "Added HDMI audio disable line to config.txt" -ForegroundColor Green
        return $true
    }
    Write-Host "Found vc4-kms-v3d overlay but audio is not disabled. fixing."
    $replacedContent = $fileContent -replace $inbuiltHDMI, $inbuiltHDMIWithAudioDisabled 
    $replacedContent | Set-Content -Path $configTxtPath
    Write-Host "HDMI audio disabled." -ForegroundColor Green
    return $true
}

function Disable-BuiltInAudio($configTxtPath)
{
    $onboardAudioOverLay = "dtparam=audio=on" # should match dtoverlay=vc4-kms-v3d only if it is an exact match 
    $onboardAudioOverLayDisabled = "dtparam=audio=off"
    $fileContent = Get-Content -Path $configTxtPath -Raw
    #check if audio overlay is already disabled
    $onboardAudioOverLayisDisabled = ($fileContent |? {$_ -imatch $onboardAudioOverLayDisabled}).Count -ge 1
    if ($onboardAudioOverLayisDisabled) 
    {
        Write-Host "Onboard audio already disabled; no changes made" -ForegroundColor Green
        return $false
    }
    #if onboardAudioOverLay exists 
    $onboardAudioOverLayExists = ($fileContent |? {$_ -imatch $onboardAudioOverLay}).Count -ge 1

    if ($onboardAudioOverLayExists) 
    {
        $replacedContent = $fileContent -replace $onboardAudioOverLay, $onboardAudioOverLayDisabled 
        $replacedContent | Set-Content -Path $configTxtPath
        write-host "Disabled onboard audio in $configTxtPath" -ForegroundColor Green
        return $true
    }
    Write-Host "Onboard audio overlay not found; adding line to disable onboard audio regardless." -ForegroundColor Green
    Add-Content -Path $configTxtPath -Value $onboardAudioOverLayDisabled
    Write-Host "Onboard audio disabled." -ForegroundColor Green
    return $true
}

function Enable-AudioOverlay($dtOverLay, $configTxtPath)
{
    Write-Host "Checking for audio overlay $dtOverLay in $configTxtPath"
    $pattern = "dtoverlay=$dtOverLay"
    $fileContent = Get-Content -Path $configTxtPath -Raw
        
    #do a regex match on exactly the overlay name to see if it's already enabled
    $overlayEnabled = ($fileContent |? {$_ -imatch $pattern}).Count -ge 1
    if ($overlayEnabled) 
    {
        Write-Host "Audio overlay $dtOverLay already enabled; no changes made." -ForegroundColor Green
        return $false
    }
    Add-Content -Path $configTxtPath -Value $pattern
    Write-Host "Enabled audio overlay $dtOverLay in $configTxtPath" -ForegroundColor Green
    return $true
}
function Test-AudioDeviceFoundInAlsa($alsaDeviceName)
{
    write-host "Testing for existing $alsaDeviceName device in ALSA..."
    $audioDeviceExists = Test-AudioDeviceExistsInAlsa -audioDeviceName $alsaDeviceName
    if (!$audioDeviceExists) 
    {
        write-host "Audio device $alsaDeviceName not found in ALSA." -ForegroundColor Red
        return $false
    }
    Write-Host "Audio device $alsaDeviceName already exists in ALSA." -ForegroundColor Green
    return $true
}
function Install-Audio($configTxtPath, $dtOverlay, $alsaDeviceName)
{
    $rebootrequired = $false
    #assume that if the audio device does not exist in ALSA then we need to configure it.
    write-host "Checking that built-in HDMI audio and built-in audio are disabled..."
    $hdmiAudioChanged = Disable-BuiltInHdmiaudio -configTxtPath $configTxtPath
    $builtInAudioChanged = Disable-BuiltInAudio -configTxtPath $configTxtPath
    write-host "Ensuring audio overlay $dtOverlay is enabled in $configTxtPath..."
    $overlayChanged = Enable-AudioOverlay -dtOverLay $dtOverlay -configTxtPath $configTxtPath
    
    if ($hdmiAudioChanged) {
        $rebootrequired = $true
    }
    if ($builtInAudioChanged) {
        $rebootrequired = $true
    }
    if ($overlayChanged) {
        $rebootrequired = $true
    }
    #each of the audio functions returns true if a change was made that requires a reboot.
    Write-Verbose "Reboot required: $rebootrequired"
    if ($rebootrequired) 
    {
        write-host "Changes were made to $configTxtPath. You need to reboot for it to take effect." -ForegroundColor Yellow
        exit 1
    }
    
    $audioDeviceFound = Test-AudioDeviceFoundInAlsa -alsaDeviceName $alsaDeviceName

    if (-not $audioDeviceFound) 
    {
        Write-Warning "Audio device $alsaDeviceName not found in ALSA, and no changes requiring reboot were made. You either need to reboot, or check your configuration."
        exit 1
    }
    write-host "Audio device $alsaDeviceName is already configured and present in ALSA. No changes needed."
}
function Invoke-JackConfiguration($user, $jackUser, $jackFolder)
{
    write-host "Configuring JACK settings for user $user and jack user $jackUser. Jack folder: $jackFolder"
    # Copy and configure jackdrc
    if (Test-Path "/etc/jackdrc")
    {
        write-Host "Removing existing /etc/jackdrc"
        rm -f /etc/jackdrc
    } 
    Write-Host "Copying jackdrc to /etc/"
    cp "$jackFolder/jackdrc" /etc/
    chmod +x /etc/jackdrc
    $chown = @($jackUser,$jackUser) -join ":"
    Write-Host "Setting ownership of /etc/jackdrc to $chown"
    chown $chown /etc/jackdrc    
}

function Invoke-AuthBindConfiguration($user, $jackFolder)
{
    if (Test-Path "/etc/authbind/byport/80")
    {
        write-Host "Removing existing /etc/authbind/byport/80"
        rm -f /etc/authbind/byport/80
    }
    Write-Host "Copying authbind configuration for port 80"
    cp "$jackFolder/80" /etc/authbind/byport/
    chmod 500 /etc/authbind/byport/80
    Write-Host "Setting ownership of /etc/authbind/byport/80 to $user"
    $chown = @($user,$user) -join ":"
    chown $chown /etc/authbind/byport/80
}
Function Restore-AlsaState($alsaStateFilePath)
{
    if (-not (Test-Path -Path $alsaStateFilePath)) 
    {
        write-host "ALSA state file $alsaStateFilePath not found. Cannot restore ALSA state." -ForegroundColor Red
        exit 1
    }
    write-host "Restoring ALSA state from file: $alsaStateFilePath"
    alsactl restore -f $alsaStateFilePath --no-ucm
    write-host "ALSA state restored." -ForegroundColor Green
}
