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
    write-host "Configuring audio users and groups for user $user, group $group, jack user $jackUser"
    # Create jack user and group if they don't exist
    if ($null -eq (getent group $jackUser)) 
    {
        Write-Host "Creating system group: jack"
        groupadd --system $jackUser
    }
    if ($null -eq (getent passwd $jackUser)) 
    {
        Write-Host "Creating system user: $jackUser"
        adduser --no-create-home --system --group jack $jackUser
    }

    $groupsToAdd = @(
        @{ User = "$user"; Group = $jackUser },
        @{ User = "$user"; Group = "audio" },
        @{ User = "root"; Group = $jackUser },
        @{ User = $jackUser; Group = "audio" }
    )

    foreach ($groupAdd in $groupsToAdd) 
    {
        $isInGroup = id -nG $($groupAdd.User) | grep -qw $($groupAdd.Group)
        if (-not $isInGroup) 
        {
            Write-Host "Adding user $($groupAdd.User) to group $($groupAdd.Group)"
            usermod -aG $($groupAdd.Group) $($groupAdd.User)
        } 
        else 
        {
            Write-Host "User $($groupAdd.User) is already in group $($groupAdd.Group)"
        }
    }
}