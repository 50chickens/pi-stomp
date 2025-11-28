#systemctl start cockpit
function Disable-UnusedService($serviceName)
{
    Write-host "Disabling unused service: $serviceName"
    #test if the systemctl service in linux exists first 
    if (systemctl list-unit-files | Select-String -Pattern $serviceName) {
        Write-host "Service $serviceName exists, disabling it."
        systemctl disable $serviceName
        Write-host "Stopping unused service: $serviceName"
        systemctl stop $serviceName
    }
    else {
        Write-host "Service $serviceName does not exist, skipping."
        return
    }
}
