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
    pushd $tmpDir && git clone https://github.com/jackaudio/jack2.git
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

    #test if mod-host is already found in path
    $modHostFound = Get-Command mod-host -ErrorAction SilentlyContinue
    if ($modHostFound) 
    {
        Write-Host "mod-host already found in path; skipping installation."
        return
    }
    $tmpDir = $(mktemp -d)
    Write-host "Cloning mod-host into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/mod-audio/mod-host.git
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
    #test if ~/.env/bin/mod-ui exists
    $mouduiFound = Test-Path -Path "$($HOME)/.env/bin/mod-ui"
    if ($mouduiFound) 
    {
        Write-Host "mod-ui already found in python venv; skipping installation."
        return
    }
    
    $tmpDir = $(mktemp -d)
    Write-host "Cloning mod-ui into temporary folder $tmpDir"
    pushd $tmpDir && git clone https://github.com/mod-audio/mod-ui.git
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

function Invoke-InstallAudioSoftware()
{
    Invoke-CompileJack
    Invoke-ModHostSetup
    #Invoke-ModUI #moved to the python venv setup script
}
function New-SystemDService($servicesUnitFile) 
{
    $systemDFolder = "/usr/lib/systemd/system"
    $servicesUnitFile = $_
    $serviceName = [System.IO.Path]::GetFileNameWithoutExtension($servicesUnitFile.Name) #eg - mod-host
    $serviceUnitFileName = $servicesUnitFile.Name #eg - mod-host.service
    $targetServiceFileName = "$systemDFolder/$serviceUnitFileName" #eg /usr/lib/systemd/system/mod-host.service
    Write-Host "Processing service: $serviceName"
    write-host "service unit file name: $audioServiceUnitFileName"
    write-host "Target service file name: $targetServiceFileName"
    
    if (Test-Path -Path "$targetServiceFileName")
    {
        Write-Host "Removing existing service file: $targetServiceFileName" -ForegroundColor Yellow
        Remove-Item -Path "$targetServiceFileName" -Force
    }
    Write-Host "Copying service file: $($servicesUnitFile.FullName) to $systemDFolder"    
    copy-item $servicesUnitFile -Destination "$systemDFolder/$serviceUnitFileName"
    Write-Host "Creating symlink for $serviceName in /etc/systemd/system/multi-user.target.wants/"

    ln -sf $targetServiceFileName /etc/systemd/system/multi-user.target.wants/
}
function New-AudioSystemDServices($servicesUnitFileFolder)
{
    write-host "services unit file folder: $servicesUnitFileFolder"
    $servicesUnitFiles = get-childitem -path $servicesUnitFileFolder -filter *.service
    if (-not $servicesUnitFiles) {
        write-host "No service unit files found in $servicesUnitFileFolder" -ForegroundColor Yellow
        return
    }
    $servicesUnitFiles |%{
        New-SystemDService -ServicesUnitFile $_
        }
}

function Start-SystemDService($service)
{
    Write-Host "Enabling and starting service: $service"
    systemctl enable $service
    systemctl start $service
    systemctl status $service --no-pager
}
function Start-SystemDServices($services)
{
    systemctl daemon-reload
    $services |%{
        $service = $_
        Start-SystemDService -service $service
    }
}
