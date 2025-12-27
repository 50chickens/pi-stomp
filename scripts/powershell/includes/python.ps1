function New-PythonVenv($venvPath)
{
    # expand ~ to actual home path if provided
    if ($venvPath -imatch "~*") { $venvPath = $venvPath -replace '^~', $HOME }

    if (Test-Path -Path $venvPath -PathType Container)
    {
        Remove-Item -Recurse -Force $venvPath
        Write-Host "Removed existing python virtual environment at $venvPath"
    }
    else
    {
        Write-Host "No existing python virtual environment at $venvPath"
    }

    python3 -m venv $venvPath
    Write-Host "Created python virtual environment at $venvPath"
}
