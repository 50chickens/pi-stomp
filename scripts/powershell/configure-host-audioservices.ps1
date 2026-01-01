param(
        $alsaStateFile  
)
$ErrorActionPreference = "Stop"

$enableMidi = $false
$setupfolder = "../../setup"
$alsaStateFilePath = "$setupfolder/audio/$($alsaStateFile).state"
$audioServicesUnitFileFolder = "$setupfolder/AudioServices"
$midiServicesUnitFileFolder = "$setupfolder/MidiServices"
# $audioServices = @("browsepy","jack","mod-host","mod-ui")
# $midiServices = @("mod-amidithru","mod-touchosc2midi","mod-midi-merger","mod-midi-merger-broadcaster")

#get the folder where the powershell script is not the bash script. 
$expectedDirectory = $MyInvocation.MyCommand.Definition | Split-Path -Parent
write-host "Current script path: $expectedDirectory" 
push-location $expectedDirectory
Write-Verbose "Changed location to script folder: $expectedDirectory"

$includesFolder = "$(pwd)/includes"
Write-Verbose "dot sourcing: $includesFolder"
if (-not (Test-Path -Path $includesFolder)) 
{
    write-host "Includes folder $includesFolder not found." -ForegroundColor Red
    exit 1
}
$includefiles = get-childitem -path $includesFolder -recurse -filter *.ps1
if (-not $includefiles) {
    write-host "No include files found in $includesFolder" -ForegroundColor Yellow
    exit 1
}
get-childitem -path $includesFolder -recurse -filter *.ps1 |% { 
    Write-Verbose "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

$parametersToValidate = @(
    @{ Value = $alsaStateFile; Name = "alsaStateFile" }
)

foreach ($param in $parametersToValidate) 
{
    Test-ScriptParametersAreValid -paramValue $param.Value -paramName $param.Name
}

Write-Host "----------------------------------------"
Write-Host "Starting audio service script..."
Write-Host "----------------------------------------"
Test-Were_In_Expected_Directory -expectedDirectory $expectedDirectory
Write-Host "----------------------------------------"
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $true
Write-Host "----------------------------------------"
write-host "Restoring alsa audio settings..." 
Restore-AlsaState -alsaStateFilePath $alsaStateFilePath
Write-Host "----------------------------------------"
write-host "Creating audio systemd services..."
New-SystemDServices -ServicesUnitFileFolder $audioServicesUnitFileFolder
Write-Host "----------------------------------------"
Write-Host "Enabling and starting audio systemd services..."
Start-SystemDServices -Services $AudioServices
Write-Host "----------------------------------------"
if ($enableMidi)
{
    write-host "Installing MIDI components..."
    Invoke-InstallMidi
    Write-Host "----------------------------------------"
    write-host "Creating MIDI systemd services..."
    New-AudioSystemDServices -servicesUnitFileFolder $midiServicesUnitFileFolder
    Write-Host "----------------------------------------"
    Write-Host "Enabling and starting MIDI systemd services..."
    Start-SystemDServices -Services $MidiServices
    Write-Host "----------------------------------------"
}
write-host "Audio services configuration complete"

##
#(Invoke-WebRequest -Uri "http://localhost/effect/list").Content | ConvertFrom-Json
#(Invoke-WebRequest -Uri "http://localhost/files/list?types=cabsim").Content | ConvertFrom-Json