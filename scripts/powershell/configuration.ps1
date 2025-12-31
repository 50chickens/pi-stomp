<#
.SYNOPSIS
    Configuration object containing all variables from configure-host-audioservices.ps1,
    configure-pistomp.ps1, and configure.ps1
.DESCRIPTION
    This module provides a centralized PSCustomObject with all configuration variables
    extracted from the three configuration scripts to enable code reuse and consistency.
#>

function New-PiStompConfiguration {
    <#
    .SYNOPSIS
        Creates a new Pi-Stomp configuration object
    .DESCRIPTION
        Returns a PSCustomObject containing all configuration variables used across
        the Pi-Stomp setup scripts.
    .OUTPUTS
        PSCustomObject with all configuration settings
    #>
    
    $config = [PSCustomObject]@{
        # From configure-host-audioservices.ps1
        EnableMidi = $false
        AlsaStateFileFolder = "../../setup/audio/"
        AlsaDeviceName = "snd_rpi_hifiberry_dacplusadcpro"
        AlsaStateFile="hifiberry.state"
        DtOverlay="hifiberry-dacplusadcpro"
        ConfigTxtPath = "/boot/firmware/config.txt"
        SetupFolder = "../../setup"
        AudioServicesUnitFileFolder = "../../setup/AudioServices"
        MidiServicesUnitFileFolder = "../../setup/MidiServices"
        AudioServicesToInstall = @("browsepy", "jack", "mod-host", "mod-ui")
        MidiServicesToStart = @("mod-amidithru", "mod-touchosc2midi", "mod-midi-merger", "mod-midi-merger-broadcaster")
        
        # From configure-pistomp.ps1
        BaseGithubOrganization = "TreeFallSound"
        BaseFolder = $HOME
        ModFolder = "$($HOME)/.mod"
        Lv2Folder = "$($HOME)/.lv2"
        DataFolder = "$($HOME)/data"
        UserFilesDirectory = "$($HOME)/data/user-files"
        PedalBoardsDirectory = "$($HOME)/data/.pedalboards"
        FoldersToCreate = @("$($HOME)/.lv2", "$($HOME)/data")
        UserFilesSubfolders = @(
            "Speaker Cabinets IRs",
            "Reverb IRs",
            "Audio Loops",
            "Audio Recordings",
            "Audio Samples",
            "Audio Tracks",
            "MIDI Clips",
            "MIDI Songs",
            "Hydrogen Drumkits",
            "SF2 Instruments",
            "SFZ Instruments",
            "Amplifier Profiles",
            "Aida DSP Models",
            "NAM Models",
            "Captures"
        )
        LinkedFolders = @()  # Empty as we don't need any linked folders for pi-stomp currently
        Repos = @(
            [PSCustomObject]@{
                RepoURL = "https://github.com/TreeFallSound/pi-stomp-pedalboards.git"
                CheckOutFolder = "$($HOME)/data/.pedalboards"
            }
            [PSCustomObject]@{
                RepoURL = "https://github.com/TreeFallSound/pi-stomp-user-files.git"
                CheckOutFolder = "$($HOME)/data/user-files"
            }
        )
        PythonPackageInstallationScript = "../bash/python-venv.sh"
        PythonVersion = $null  # Set dynamically via Get-PythonVersion
        
        # From configure.ps1
        User = "pistomp"
        Group = "jack"
        JackUser = "jack"
        JackFolder = "../../setup/mod"
        ServicesToDisable = @("bluetooth", "dnsmasq", "exim4", "fluidsynth")
        CockPitPackages = @("cockpit", "cockpit-packagekit", "cockpit-storaged", "cockpit-networkmanager")
        MainPackages = @(
            "virtualenv", "python3-pip", "python3-dev", "python3-zeroconf", "build-essential",
            "libasound2-dev", "libjack-jackd2-dev", "liblilv-dev", "libjpeg-dev", "zlib1g-dev",
            "cmake", "debhelper", "dh-autoreconf", "dh-python", "gperf", "intltool", "ladspa-sdk",
            "libarmadillo-dev", "libavahi-gobject-dev", "libavcodec-dev", "libavutil-dev",
            "libbluetooth-dev", "libboost-dev", "libeigen3-dev", "libfftw3-dev", "libglib2.0-dev",
            "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev", "liblrdf0-dev",
            "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev", "libzita-convolver-dev",
            "libzita-resampler-dev", "lv2-dev", "p7zip-full", "python3-all", "python3-setuptools",
            "libreadline-dev", "zita-alsa-pcmi-utils", "hostapd", "dnsmasq", "iptables",
            "python3-smbus", "liblo-dev", "python3-liblo", "libzita-alsa-pcmi-dev", "authbind",
            "libfluidsynth-dev", "lockfile-progs", "tree"
        )
        OtherPackages = @(
            "liblilv-dev", "lv2-dev", "libserd-dev", "libsord-dev", "libsratom-dev",
            "lilv-utils", "liblilv-0-0"
        )
        OptionalPackages = @(
            "virtualenv", "python3-venv", "python3-pip", "python3-dev", "python3-all",
            "python3-setuptools", "python3-zeroconf", "python3-smbus", "python3-liblo",
            "build-essential", "pkg-config", "cmake", "debhelper", "dh-autoreconf", "dh-python",
            "gperf", "intltool", "make", "libasound2-dev", "libjack-jackd2-dev", "libpulse-dev",
            "liblilv-dev", "libserd-dev", "libsord-dev", "libsratom-dev", "lilv-utils", "liblilv-0-0",
            "lv2-dev", "libfreetype6-dev", "libjpeg-dev", "libpng-dev", "libtiff5-dev", "zlib1g-dev",
            "libreadline-dev", "libssl-dev", "libffi-dev", "libarmadillo-dev", "libavahi-gobject-dev",
            "libavcodec-dev", "libavutil-dev", "libbluetooth-dev", "libboost-dev", "libeigen3-dev",
            "libfftw3-dev", "libglib2.0-dev", "libglibmm-2.4-dev", "libgtk2.0-dev", "libgtkmm-2.4-dev",
            "liblrdf0-dev", "libsamplerate0-dev", "libsigc++-2.0-dev", "libsndfile1-dev",
            "libzita-convolver-dev", "libzita-resampler-dev", "libzita-alsa-pcmi-dev",
            "zita-alsa-pcmi-utils", "libfluidsynth-dev", "librtmidi-dev", "ladspa-sdk", "liblo-dev",
            "p7zip-full", "authbind", "hostapd", "dnsmasq", "iptables", "lockfile-progs", "tree",
            "bc", "bison", "flex", "git", "curl"
        )
        SudoFoldersToCreate = @("/usr/mod/scripts")
    }
    
    return $config
}