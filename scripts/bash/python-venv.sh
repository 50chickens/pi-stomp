#!/bin/bash
# function setup_python_venv_modui() 
# {
#     tmpDir=$(mktemp -d)
#     echo "Cloning mod-ui into temporary folder $tmpDir"
#     pushd "$tmpDir" && git clone https://github.com/mod-audio/mod-ui.git
#     pushd mod-ui
#     echo "Setting up mod-ui"
#     chmod +x setup.py
#     cd utils
#     make
#     cd ..
#     python setup.py install
#     popd
#     popd

# }
set -e
echo "Setting up Python virtual environment and installing required packages..."
rm -rf ~/.env
virtualenv -p python3 ~/.env
source ~/.env/bin/activate
echo "Installing required Python packages from original install.sh..."
# Install packages matching versions from /home/pistomp/pi-stomp-orig/pi-stomp/setup/mod/install.sh
# but adapted for Python 3.13 compatibility where needed
~/.env/bin/pip install pyserial==3.0 pystache==0.5.4 aggdraw==1.3.11 scandir backports.shutil-get-terminal-size
# pycrypto is unmaintained; use pycryptodome (the maintained fork) instead
~/.env/bin/pip install pycryptodome
~/.env/bin/pip install tornado==4.3
# tornado 4.3 requires backports.ssl_match_hostname
~/.env/bin/pip install backports.ssl_match_hostname
# Pillow 9.4.0 incompatible with Python 3.13; use pre-built wheel version
~/.env/bin/pip install Pillow==11.1.0
~/.env/bin/pip install cython


echo "Installing mod-ui from source..."
tmpDir=$(mktemp -d)
pushd "$tmpDir" && git clone https://github.com/micahvdm/mod-ui.git
pushd mod-ui
echo "Setting up mod-ui"
chmod +x setup.py
cd utils
make
cd ..
# Use setuptools instead of distutils (distutils removed in Python 3.13)
~/.env/bin/python -m pip install setuptools wheel
~/.env/bin/python setup.py install
popd
popd

echo "Installing browsepy from source..."
pushd $(mktemp -d) && git clone https://github.com/micahvdm/browsepy.git
pushd browsepy
~/.env/bin/pip install ./
popd
popd

echo "Python virtual environment setup complete!"
echo "To activate: source ~/.env/bin/activate"
