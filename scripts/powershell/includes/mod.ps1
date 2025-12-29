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
    #test if jack2 binaries are already found in path
    $jackFound = Get-Command jackd -ErrorAction SilentlyContinue
    if ($jackFound) 
    {
        Write-Host "Jack2 binaries already found in path; skipping compilation."
        return
    }
    
    $tmpDir = $(mktemp -d)
    Write-host "Cloning jack2 into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/micahvdm/jack2.git
    pushd jack2
    write-host "running jack2 configure."
    ./waf configure
    write-host "building and installing jack2."
    ./waf build
    ./waf install
    popd
    popd
}
function Invoke-ModHostSetup()
{

    $modHostFound = Get-Command mod-host -ErrorAction SilentlyContinue
    if ($modHostFound) 
    {
        Write-Host "Mod-host already found in path; skipping installation."
        return
    }
    $tmpDir = $(mktemp -d)
    Write-host "Cloning mod-host into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/micahvdm/mod-host.git
    pushd mod-host
    write-host "Building and installing mod-host"
    make
    write-host "Running mod-host make install (binary only, skipping JACK plugin)"
    make install
    write-host "Removing incompatible JACK plugin (mod-host.so) that may cause version conflicts"
    rm -f /usr/local/lib/jack/mod-host.so
    popd
    popd
}

function Invoke-ModUI()
{
    #test if ~/.env/bin/mod-ui exists
    $mouduiFound = Test-Path -Path "$($HOME)/.env/bin/mod-ui"
    if ($mouduiFound) 
    {
        Write-Host "Mod-ui already found in python venv; skipping installation."
        return
    }
    
    $tmpDir = $(mktemp -d)
    Write-host "Cloning mod-ui into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/micahvdm/mod-ui.git
    pushd mod-ui
    write-host "Setting up mod-ui"
    chmod +x setup.py
    cd utils
    make
    cd ..
    ./setup.py install
    popd
    popd
}

function Invoke-BrowserPy()
{
    #test if browsepy is installed
    $browsepyFound = pip show browsepy -ErrorAction SilentlyContinue
    if ($browsepyFound) 
    {
        Write-Host "browsepy already found; skipping installation."
        return
    }
    
    $tmpDir = $(mktemp -d)
    Write-host "Cloning browsepy into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/micahvdm/browsepy.git
    pushd browsepy
    write-host "Installing browsepy"
    pip install ./
    popd
    popd
}

function Invoke-InstallAudioSoftware()
{
    Invoke-CompileJack
    Invoke-ModHostSetup
    Invoke-BrowserPy
    Invoke-ModUI
}