function Invoke-Amidithru()
{
    #amidithru
    pushd $(mktemp -d) && git clone https://github.com/BlokasLabs/amidithru.git
    pushd amidithru
    sed -i 's/CXX=g++.*/CXX=g++/' Makefile
    sudo make install
    popd
    popd
}

function Invoke-InstallModMidiMerger()
{
    pushd $(mktemp -d) && git clone https://github.com/micahvdm/mod-midi-merger.git
    pushd mod-midi-merger
    mkdir build && cd build
    cmake ..
    make
    sudo make install
    popd
    popd
}

function Invoke-MidiConfiguration()
{
    # TOUCHOSC2MIDI_ROOT=/usr/local/lib/python3.9/dist-packages/touchosc2midi
    # MOD_SCRIPTS=/usr/mod/scripts

    # sudo cp setup/mod-tweaks/start_touchosc2midi.sh $MOD_SCRIPTS

    #!/bin/sh
    # IN_PORT_ID=$(/usr/bin/touchosc2midi list ports 2>&1 | grep touchosc | head -n 1 | egrep -o "\s+[0-9]+: " | egrep -o "[0-9]+")
    # OUT_PORT_ID=$(/usr/bin/touchosc2midi list ports 2>&1 | grep touchosc | tail -n 1 | egrep -o "\s+[0-9]+: " | egrep -o "[0-9]+")
    # exec touchosc2midi --midi-in=$IN_PORT_ID --midi-out=$OUT_PORT_ID
}
function Invoke-InstallMidi()
{
    Invoke-Amidithru
    Invoke-InstallModMidiMerger
    Invoke-MidiSystemDServices
    Invoke-MidiConfiguration
}   

function New-MidiSystemDServices()
{
    sudo ln -sf /usr/lib/systemd/system/mod-amidithru.service /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /usr/lib/systemd/system/mod-touchosc2midi.service /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /usr/lib/systemd/system/mod-midi-merger.service /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /usr/lib/systemd/system/mod-midi-merger-broadcaster.service /etc/systemd/system/multi-user.target.wants
}

