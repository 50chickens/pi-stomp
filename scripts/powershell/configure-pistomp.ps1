param (
    [string] $dtOverlay
    )   

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
    @{ Value = $dtOverlay; Name = "dtOverlay" }
)

foreach ($param in $parametersToValidate) 
{
    Test-ScriptParametersAreValid -paramValue $param.Value -paramName $param.Name
}

function New-DataFolders($foldersToCreate, $userFoldersToCreate)
{
    New-Folders -foldersToCreate $foldersToCreate -baseFolder "~"
    New-Folders -foldersToCreate $userFoldersToCreate -baseFolder "~/data/user-files"
}


$installLv2plugins = $true
$installMidi = $false
$foldersToCreate = @("data/.pedalboards", "data/user-files", ".lv2")
$userFoldersToCreate = @("Speaker Cabinets IRs", "Reverb IRs", "Audio Loops", "Audio Recordings", "Audio Samples", "Audio Tracks", "MIDI Clips", "MIDI Songs", "Hydrogen Drumkits", "SF2 Instruments", "SFZ Instruments", "Amplifier Profiles", "Aida DSP Models", "NAM Models")

Write-Host "----------------------------------------"
write-host "testing that we're in the expected directory..." 
Test-Were_In_Expected_Directory -expectedDirectory $expectedDirectory
Write-Host "----------------------------------------"
write-host "checking current user permissions..." 
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $false #prevent running as root so that folders created are owned by the normal user, and other security reasons.
Write-Host "----------------------------------------"
write-host "getting OS release information..." 
Get-OSRelease #sets global variables from /etc/os-release


New-DataFolders -foldersToCreate $foldersToCreate -userFoldersToCreate $userFoldersToCreate

Write-Host "Installing LV2 plugins..."
New-lv2pluginsfolder

New-PythonVenv -venvPath "~/.env"
bash python-venv.sh #run this bash script to setup python venv.

get-childitem -path ../../state/audio  -ErrorAction SilentlyContinue |% {
    $modalias = get-content $_.FullName
    write-host "Detected audio device modalias: $modalias"
}

#setup the audio codec without ucm for pi-stomp. prevents 
#alsa-lib main.c:1541:(snd_use_case_mgr_open) error: failed to import hw:0 use case configuration -2

alsactl restore  -f ./setup/audio/$($dtOverlay).state  --no-ucm

Invoke-InstallMod

if ($installLv2plugins)
{
    Write-Host "Installing LV2 plugins..."
    New-lv2pluginsfolder
}

if ($installMidi)
{
    Write-Host "Installing MIDI..."
    Invoke-InstallMidi
}
