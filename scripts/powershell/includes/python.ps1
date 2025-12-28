function New-PythonVenv($venvPath)
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
