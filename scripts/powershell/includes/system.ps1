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
function Invoke-AudioUserAndGroupConfiguration($group, $user, $jackUser)
{
    
    # Create jack user and group if they don't exist
    $jackGroupExists = getent group $jackUser
    $jackUserExists = getent passwd $jackUser
     
    if (-not $jackUserExists)
    {
        Write-Host "Creating system user and group: $jackUser"
        adduser --no-create-home --system --group $jackUser
    }
    if (-not $jackGroupExists)
    {
        Write-Host "Creating system user and group: $jackUser"
        adduser --no-create-home --system --group $jackUser
    }
    else
    {
        Write-Host "User and group $jackUser already exists."
    }
    
    $groupsToAdd = @(
        @{ User = "$user"; Group = "$jackUser" },
        @{ User = "$user"; Group = "audio" },
        @{ User = "root"; Group = "$jackUser" },
        @{ User = "$jackUser"; Group = "audio" }
    )
    
    foreach ($groupAdd in $groupsToAdd)
    {
        $userGroups = id -nG $($groupAdd.User)
        
        if ($userGroups -match "\b$($groupAdd.Group)\b")
        {
            Write-Host "User $($groupAdd.User) is already in group $($groupAdd.Group)"
        }
        else
        {
            Write-Host "Adding user $($groupAdd.User) to group $($groupAdd.Group)"
            adduser $($groupAdd.User) $($groupAdd.Group) --quiet
        }
    }
}