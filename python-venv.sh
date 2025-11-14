#!/bin/bash
source ~/.env/bin/activate
# install latest available releases (no exact pins)
pip3 install pyserial pystache aggdraw scandir backports.shutil-get-terminal-size
pip3 install python-config
# pycrypto is unmaintained; use pycryptodome instead
pip3 install pycryptodome
pip3 install tornado
pip3 install Pillow
pip3 install cython
pip3 install browsepy
pip3 install pyalsaaudio python-rtmidi requests RPi.GPIO gfxhat matplotlib rpi_ws281x adafruit-circuitpython-neopixel adafruit-circuitpython-rgb-display numpy adafruit-circuitpython-mcp3xxx

# pushd $(mktemp -d) && git clone https://github.com/micahvdm/browsepy.git
# pushd browsepy
# pip3 install ./
# popd
# popd

# pushd $(mktemp -d) && git clone https://github.com/micahvdm/touchosc2midi.git
# pushd touchosc2midi
# pip3 install ./
# popd
# popd


#### only required for python 3.11 compatibility ####
echo "Patching tornado for python 3.11"
cp ~/.env/lib/python3.11/site-packages/tornado/httputil.py ~/.env/lib/python3.11/site-packages/tornado/httputil.py.bak
sed -i -e 's/collections.MutableMapping/collections.abc.MutableMapping/' ~/.env/lib/python3.11/site-packages/tornado/httputil.py
sed -i -e 's/collections.MutableMapping/collections.abc.MutableMapping/' ~/modui-env/lib/python3.11/site-packages/tornado/httputil.py
sed -i -e 's/collections.Mapping/collections.abc.Mapping/' ~/.env/lib/python3.11/site-packages/browsepy/manager.py