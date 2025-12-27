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
function Disable-UnusedService($service)
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
