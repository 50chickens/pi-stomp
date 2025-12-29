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
    New-Folders -foldersToCreate $foldersToCreate
}


#$foldersToCreate = @("data/.pedalboards", "data/user-files", ".lv2")

$modFolder = ".mod"
$lv2Folder = "$($modFolder)/.lv2"
$modDataFolder = "$modFolder/data"
$userFilesDirectory = "$modDataFolder/user-files"
$pedalBoardsDirectory = "$modDataFolder/pedalboards"
$foldersToCreate = @($modFolder, $lv2Folder, $modDataFolder, $userFilesDirectory, $pedalBoardsDirectory)

write-host "Mod folder: $modFolder"
write-host "LV2 folder: $lv2Folder"
write-host "Mod data folder: $modDataFolder"
write-host "User files directory: $userFilesDirectory"
write-host "Pedalboards directory: $pedalBoardsDirectory"

$repos = @()
$repos += [PSCustomObject]@{RepoURL = "https://github.com/TreeFallSound/pi-stomp-pedalboards.git";CheckOutFolder=$pedalBoardsDirectory}
$repos += [PSCustomObject]@{RepoURL = "https://github.com/TreeFallSound/pi-stomp-user-files.git";CheckOutFolder=$userFilesDirectory} 


#$linkedFolders = @(".lv2", ".pedalboards")
#$userFoldersToCreate = @("Speaker Cabinets IRs", "Reverb IRs", "Audio Loops", "Audio Recordings", "Audio Samples", "Audio Tracks", "MIDI Clips", "MIDI Songs", "Hydrogen Drumkits", "SF2 Instruments", "SFZ Instruments", "Amplifier Profiles", "Aida DSP Models", "NAM Models")
$pythonPackageInstallationScript = "../bash/python-venv.sh"
Write-Host "----------------------------------------"
write-host "testing that we're in the expected directory..." 
Test-Were_In_Expected_Directory -expectedDirectory $expectedDirectory
Write-Host "----------------------------------------"
write-host "checking current user permissions..." 
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $false #prevent running as root so that folders created are owned by the normal user, and other security reasons.
Write-Host "----------------------------------------"
write-host "getting OS release information..." 
Get-OSRelease #sets global variables from /etc/os-release
Write-Host "----------------------------------------"
write-host "creating data folders..." 
New-DataFolders -foldersToCreate $foldersToCreate
Write-Host "----------------------------------------"
Write-Host "Checking out required repos..."
Invoke-CheckoutGitRepos -repos $repos
Write-Host "----------------------------------------"
exit

Write-Host "creating linked folders"
#New-LinkedFolders -linkedFolders $linkedFolders
Write-Host "----------------------------------------"
$pythonVersion = Get-PythonVersion #for python version we only need the major.minor part, eg 3.11. use regex to get named group for major.minor
Write-Host "----------------------------------------"
Write-Host "creating new python environment."
New-EmptyPythonVenv -venvPath "$($HOME)/.env"
Write-Host "----------------------------------------"
Write-Host "installing all required python packages into venv."
Write-Host "----------------------------------------"
Invoke-InstallPythonPackages -pythonPackageInstallationScript $pythonPackageInstallationScript
Write-Host "----------------------------------------"
Write-Host "patching python files for compatibility..."
Invoke-PatchPythonFiles -pythonVersion $pythonVersion -venvPath "$($HOME)/.env"
Write-Host "----------------------------------------"