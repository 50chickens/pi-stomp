#!/bin/bash

# This file is part of pi-stomp.
#
# pi-stomp is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pi-stomp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pi-stomp.  If not, see <https://www.gnu.org/licenses/>.

function Invoke-CompileJack()
{
    pushd $(mktemp -d) && git clone https://github.com/micahvdm/jack2.git
    pushd jack2
    ./waf configure
    ./waf build
    sudo ./waf install
    popd
    popd
}
function Invoke-ModSetup()
{
# #Mod-host
    pushd $(mktemp -d) && git clone https://github.com/micahvdm/mod-host.git
    pushd mod-host
    make
    sudo make install
    popd
    popd
}

function Invoke-ModUI()
{

    pushd $(mktemp -d) && git clone https://github.com/micahvdm/mod-ui.git
    pushd mod-ui
    chmod +x setup.py
    cd utils
    make
    cd ..
    sudo ./setup.py install
    cp -r default.pedalboard /home/pistomp/data/.pedalboards
    popd
    popd
}

function New-PedalboardDefaultFiles()
{
    if (Test-Path -Path "~/.pedalboards" -PathType Leaf)
    {
        rm -rf ~/.pedalboards
    }
    ln -s ~/data/.pedalboards ~/.pedalboards
    
}

function Invoke-InstallMod()
{
    Invoke-CompileJack
    Invoke-ModSetup
    Invoke-ModUI
    New-ModSystemDServices
    Invoke-JackConfiguration
    New-PedalboardDefaultFiles
}
function New-ModSystemDServices()
{
    sudo cp setup/mod/*.service /usr/lib/systemd/system/
    sudo ln -sf /usr/lib/systemd/system/browsepy.service /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /usr/lib/systemd/system/jack.service /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /usr/lib/systemd/system/mod-host.service /etc/systemd/system/multi-user.target.wants
    sudo ln -sf /usr/lib/systemd/system/mod-ui.service /etc/systemd/system/multi-user.target.wants

}

function Invoke-JackConfiguration()
{
    pushd setup/mod
    sudo adduser --no-create-home --system --group jack
    sudo adduser pistomp jack --quiet
    sudo adduser root jack --quiet
    sudo adduser jack audio --quiet
    sudo cp jackdrc /etc/
    sudo chmod +x /etc/jackdrc
    sudo chown jack:jack /etc/jackdrc
    sudo cp 80 /etc/authbind/byport/
    sudo chmod 500 /etc/authbind/byport/80
    sudo chown pistomp:pistomp /etc/authbind/byport/80
    popd
}