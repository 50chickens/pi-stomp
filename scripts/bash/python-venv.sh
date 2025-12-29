#!/bin/bash
function setup_python_venv_modui() 
{
    tmpDir=$(mktemp -d)
    echo "Cloning mod-ui into temporary folder $tmpDir"
    pushd "$tmpDir" && git clone https://github.com/mod-audio/mod-ui.git
    pushd mod-ui
    echo "Setting up mod-ui"
    chmod +x setup.py
    cd utils
    make
    cd ..
    python setup.py install
    popd
    popd

}
echo "Setting up Python virtual environment and installing required packages..."
rm -rf ~/.env
virtualenv -p python3 ~/.env
source ~/.env/bin/activate
echo "Installing required Python packages..."
# install latest available releases (no exact pins)
pip3 install pyserial pystache aggdraw scandir backports.shutil-get-terminal-size
pip3 install python-config
# pycrypto is unmaintained; use pycryptodome instead
pip3 install pycryptodome
pip3 install tornado==4.5.3
pip3 install backports.ssl_match_hostname
pip3 install Pillow
pip3 install cython
pip3 install browsepy
pip3 install setuptools
pip3 install pyalsaaudio python-rtmidi requests RPi.GPIO gfxhat matplotlib rpi_ws281x adafruit-circuitpython-neopixel adafruit-circuitpython-rgb-display numpy adafruit-circuitpython-mcp3xxx

#test if ~/.env/bin/mod-ui exists
if [ -f ~/.env/bin/mod-ui ]; then
    echo "mod-ui already installed in python virtual environment, skipping mod-ui installation."
    exit 0
fi

setup_python_venv_modui

# pushd $(mktemp -d) && git clone https://github.com/mod-audio/browsepy.git
# pushd browsepy
# pip3 install ./
# popd
# popd

# pushd $(mktemp -d) && git clone https://github.com/mod-audio/touchosc2midi.git
# pushd touchosc2midi
# pip3 install ./
# popd
# popd


#### only required for python 3.11 compatibility ####
