$includesFolder = "~/pi-stomp/setup/includes"
get-childitem -path $includesFolder/*.ps1 |% { 
    write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

Test-ImInTheCorrectFolder


$ErrorActionPreference = "Stop" #stop on all errors

$foldersToCreate = @("data/.pedalboards", "data/user-files")
$sudoFoldersToCreate = @("/usr/mod/scripts")
$userFoldersToCreate = @("Speaker Cabinets IRs", "Reverb IRs", "Audio Loops", "Audio Recordings", "Audio Samples", "Audio Tracks", "MIDI Clips", "MIDI Songs", "Hydrogen Drumkits", "SF2 Instruments", "SFZ Instruments", "Amplifier Profiles", "Aida DSP Models", "NAM Models")

Test-ICanSudo

# New-Folders -foldersToCreate $foldersToCreate -baseFolder "~"
# New-Folders -foldersToCreate $sudoFoldersToCreate -sudo
# New-Folders -foldersToCreate $userFoldersToCreate -baseFolder "~/data/user-files"


# New-PythonVenv -venvPath "~/.env"
# bash python-venv.sh #run this bash script to setup python venv.
Invoke-PackageInstall #packages that we need to install.
Invoke-ElevatedCommands #things in here run with sudo - eg sudo pwsh -c "./elevated.ps1"
