function Test-WorkingDirectory($workingDirectory)
{
    Write-Host "Testing if working directory is $workingDirectory." -ForegroundColor Blue
    Write-Host "Checking current folder: $($(pwd).Path)" -ForegroundColor Blue
    if (((pwd).Path) -ne "$workingDirectory")
    {
        Write-Host "$((pwd).Path) is not the right directory."
        exit 1
    }
    else
    {
        Write-Host "You are in the correct folder ($workingDirectory)." -ForegroundColor Green
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