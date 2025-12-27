#systemctl start cockpit
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

function Get-OSRelease()
{
    Get-Content -Path "/etc/os-release" |%{
       $parts = $_ -split '='
       if ($parts.Length -eq 2) {
           $key = $parts[0].Trim()
           $value = $parts[1].Trim('"')
           Write-Verbose "setting variable $key to $value."
           Set-Variable -Name $key -Value $value -Scope Global
       }
    }
}