function Get-PythonVersion($venvPath)
{
    $pythonOutput = python3 --version
    #check error level 
    if ($LASTEXITCODE -ne 0) 
    {
        write-host "Error getting python version. python3 --version exited with code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    write-host "python version output: $pythonOutput"
    $pythonVersion = $pythonOutput | ForEach-Object {
        if ($_ -match 'Python (?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)') {
            "$($Matches['major']).$($Matches['minor'])"
        }
    }
    if ($null -eq $pythonVersion) 
    {
        write-host "Could not determine python version." -ForegroundColor Red
        exit 1
    }
    return $pythonVersion
}
function New-EmptyPythonVenv($venvPath)
{
    write-host "Setting up python virtual environment at $venvPath"
    if (Test-Path -Path $venvPath -PathType Container)
    {
        Write-Host "Removing existing python virtual environment at $venvPath" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $venvPath
    }
    Write-Host "Creating python virtual environment at $venvPath"
    python3 -m venv $venvPath
}
function Invoke-InstallPythonPackages($pythonPackageInstallationScript) 
{    
    write-host "running $pythonPackageInstallationScript to install python packages..."
    if (Test-Path -Path $pythonPackageInstallationScript) 
    {
        write-host "found $pythonPackageInstallationScript, running it..."
        bash $pythonPackageInstallationScript
    }
    else 
    {
        write-host "$pythonPackageInstallationScript not found, cannot setup python venv." -ForegroundColor Red
        exit 1
    }
}
function Invoke-PatchPythonFile($FileToPatch)
{
    $patches = @(
        @{ Pattern = 'collections\.Mapping'; Replacement = 'collections.abc.Mapping' },
        @{ Pattern = 'collections\.MutableMapping'; Replacement = 'collections.abc.MutableMapping' }
    )
    
    $fileContent = Get-Content -Path $FileToPatch.FullName -Raw
    $patchedContent = $fileContent
    
    foreach ($patch in $patches) {
        Write-Host "Patching file $($FileToPatch.FullName) to replace $($patch.Pattern) with $($patch.Replacement)."
        $patchedContent = $patchedContent -replace $patch.Pattern, $patch.Replacement
    }
    
    Set-Content -Path $FileToPatch.FullName -Value $patchedContent
}
function Invoke-PatchPythonFiles($pythonVersion,$venvPath)
{
    write-host "Patching python files in venv at $venvPath."
    $filesToPatch = @("tornado/httputil.py","browsepy/manager.py")
    $filesToPatch |%{
        $fileToPatch = Get-ChildItem -Path "$venvPath/lib/python$pythonVersion/site-packages/" -Recurse -Filter $_ -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $fileToPatch) 
        {
            write-host "File $_ not found, skipping patch." -ForegroundColor Yellow
            return
        }
        Invoke-PatchPythonFile -FileToPatch $fileToPatch
    }
}