#!/bin/bash
source ~/.env/bin/activate
pip3 install pyserial==3.0 pystache==0.5.4 aggdraw==1.3.11 scandir backports.shutil-get-terminal-size
pip3 install python-config
pip3 install pycrypto
pip3 install tornado==4.3
pip3 install Pillow==8.4.0
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
echo "Patching tornado for python 3.11"
cp ~/.env/lib/python3.11/site-packages/tornado/httputil.py ~/.env/lib/python3.11/site-packages/tornado/httputil.py.bak
sed -i -e 's/collections.MutableMapping/collections.abc.MutableMapping/' ~/.env/lib/python3.11/site-packages/tornado/httputil.py
sed -i -e 's/collections.Mapping/collections.abc.Mapping/' ~/.env/lib/python3.11/site-packages/browsepy/manager.py