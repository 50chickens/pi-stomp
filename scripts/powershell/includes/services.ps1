function Get-Services()
{
    $serviceFiles = systemctl list-unit-files |? { $_ -inotmatch "unit file"} |? {$_ -imatch "^(?<servicename>[\w\-_]+)\.service"}

    $services = @()
    $serviceFiles |%{

        $servicefileRegex = "^(?<unitfile>\S+)\s+(?<state>\S+)\s+(?<preset>\S+)$"
        if ($_ -match $servicefileRegex) 
        {
           $unitFileName = $Matches["unitfile"].Trim().Replace(".service","")
           $isRunning = (systemctl is-active $unitFileName) -eq "active"
           $isEnabled = (systemctl is-enabled $unitFileName) -eq "enabled"
            $services += [PSCustomObject]@{
                Name = $unitFileName
                IsRunning = $isRunning
                IsEnabled = $isEnabled
            }
        }
    }
    return $services
}
function Disable-Service($service)
{
        
    if (-not $service) 
    {
        Write-host "Service details not found, skipping." -ForegroundColor Yellow
        return
    }
    if ($service.isEnabled) 
    {
        Write-host "Service $($service.name) is enabled, disabling." -ForegroundColor Green
        systemctl disable $($service.name)
    }
    else 
    {
        Write-host "Service $($service.name) is already disabled." -ForegroundColor green
    }
    if ($service.isRunning) 
    {
        Write-host "Service $($service.name) is running, stopping." -ForegroundColor Green
        systemctl stop $($service.name)
    }
}

function Disable-Services($servicesToDisable)
{
    $services = Get-Services
    $servicesToDisable |% {
        $serviceToProcess = $_
        $service = $services |? { $_.Name -imatch $serviceToProcess}
        if (-not $service) 
        {
            write-host "Service $serviceToProcess not found on system, skipping." -ForegroundColor Yellow
            return
        }
        write-host "Found service: $($service.Name). Checking if it needs to be stopped/disabled..."
        Disable-Service -service $service 
    }
    
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
function New-SystemDServices($servicesUnitFileFolder)
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
