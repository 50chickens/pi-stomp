function Invoke-Amidithru()
{
    write-host "Installing Amidithru..."
    pushd $(mktemp -d) && git clone https://github.com/BlokasLabs/amidithru.git
    pushd amidithru
    sed -i 's/CXX=g++.*/CXX=g++/' Makefile
    make install
    popd
    popd
}

function Invoke-InstallModMidiMerger()
{
    write-host "Installing Mod MIDI Merger..."
    pushd $(mktemp -d) && git clone https://github.com/micahvdm/mod-midi-merger.git
    pushd mod-midi-merger
    mkdir build && cd build
    cmake ..
    make
    make install
    popd
    popd
}

function Invoke-InstallMidi()
{
    Invoke-Amidithru
    Invoke-InstallModMidiMerger
}   