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
function Invoke-ModSetup()
{
    $tmpDir = $(mktemp -d)
    Write-host "Cloning mod-host into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/micahvdm/mod-host.git
    pushd mod-host
    write-host "building and installing mod-host"
    make
    write-host "running mod-host make install"
    make install
    popd
    popd
}

function Invoke-ModUI()
{
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

function Invoke-CompileSoftware()
{
    Invoke-CompileJack
    Invoke-ModSetup
    Invoke-ModUI
}
function New-AudioSystemDService($audioServicesUnitFile) 
{
    $systemDFolder = "/usr/lib/systemd/system"
    $audioServicesUnitFile = $_
    $audioServiceName = [System.IO.Path]::GetFileNameWithoutExtension($audioServicesUnitFile.Name) #eg - mod-host
    $audioServiceUnitFileName = $audioServicesUnitFile.Name #eg - mod-host.service
    $targetServiceFileName = "$systemDFolder/$audioServiceUnitFileName" #eg /usr/lib/systemd/system/mod-host.service
    Write-Host "Processing audio service: $audioServiceName"
    write-host "Audio service unit file name: $audioServiceUnitFileName"
    write-host "Target service file name: $targetServiceFileName"
    
    if (Test-Path -Path "$targetServiceFileName")
    {
        Write-Host "Removing existing service file: $targetServiceFileName" -ForegroundColor Yellow
        Remove-Item -Path "$targetServiceFileName" -Force
    }
    Write-Host "Copying service file: $($audioServicesUnitFile.FullName) to $systemDFolder"    
    copy-item $audioServicesUnitFile -Destination "$systemDFolder/$audioServiceUnitFileName"
    Write-Host "Creating symlink for $audioServiceName in /etc/systemd/system/multi-user.target.wants/"

    ln -sf $targetServiceFileName /etc/systemd/system/multi-user.target.wants/
}
function New-AudioSystemDServices($audioServicesUnitFileFolder)
{
    write-host "Audio services unit file folder: $audioServicesUnitFileFolder"
    $audioServicesUnitFiles = get-childitem -path $audioServicesUnitFileFolder -filter *.service
    if (-not $audioServicesUnitFiles) {
        write-host "No audio service unit files found in $audioServicesUnitFileFolder" -ForegroundColor Yellow
        return
    }
    $audioServicesUnitFiles |%{
        New-AudioSystemDService -audioServicesUnitFile $_
        }
}

function Start-AudioSystemDService($audioService)
{
    Write-Host "Enabling and starting audio service: $audioService"
    systemctl enable $audioService
    systemctl start $audioService
    systemctl status $audioService --no-pager
}
function Start-AudioSystemDServices($audioServices)
{
    systemctl daemon-reload
    $audioServices |%{
        $audioService = $_
        Start-AudioSystemDService -audioService $audioService
    }
}
