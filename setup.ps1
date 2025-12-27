
$installLv2plugins = $true
$installMidi = $false
$foldersToCreate = @("data/.pedalboards", "data/user-files")
$userFoldersToCreate = @("Speaker Cabinets IRs", "Reverb IRs", "Audio Loops", "Audio Recordings", "Audio Samples", "Audio Tracks", "MIDI Clips", "MIDI Songs", "Hydrogen Drumkits", "SF2 Instruments", "SFZ Instruments", "Amplifier Profiles", "Aida DSP Models", "NAM Models")

New-Folders -foldersToCreate $foldersToCreate -baseFolder "~/"
New-Folders -foldersToCreate $userFoldersToCreate -baseFolder "~/data/user-files/"

New-PythonVenv -venvPath "~/.env"
bash python-venv.sh #run this bash script to setup python venv.

alsactl restore -f ./setup/audio/iqaudiocodec.state #setup the audio codec
alsactl restore --no-ucm -f ./setup/audio/iqaudiocodec.state #setup the audio codec without ucm for pi-stomp. prevents 

#patch /boot/firmware/config.txt to ensure audio works correctly with pi-stomp
#replace dtoverlay=vc4-kms-v3d with dtoverlay=vc4-kms-v3d,noaudio 

# alsa-lib main.c:1541:(snd_use_case_mgr_open) error: failed to import hw:0 use case configuration -2
# alsa-lib main.c:1541:(snd_use_case_mgr_open) error: failed to import hw:0 use case configuration -2

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