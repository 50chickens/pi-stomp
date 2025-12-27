function Test-CurrentUserHasCorrectPermissions($shouldBeRoot = $true)
{
    Write-Host "Testing current user permissions... expecting root: $shouldBeRoot."
    $uid = & id -u 2>$null 
    Write-Host "Current user uid is: $uid."
    #compare uid to 0 for root if requiresRoot is true
    if ($shouldBeRoot)
    {
        if (-not $uid -or [int]$uid -ne 0)
        {
            Write-Host "Current user does not have root privileges. uid=$uid." -ForegroundColor Yellow
            exit 1
        }
        else
        {
            Write-Host "Current user has root privileges. uid=$uid. Continuing." -ForegroundColor Green
        }
    }
    else
    {
        if ($uid -and [int]$uid -eq 0)
        {
            Write-Host "Current user should not have root privileges. uid=$uid" -ForegroundColor Yellow
            exit 1
        }
        else
        {
            Write-Host "Current user does not have root privileges as expected. uid=$uid. Continuing." -ForegroundColor Green
        }
    }
}