param (
    [string] $dtOverlay
    )   

$expectedDirectory = $MyInvocation.MyCommand.Definition | Split-Path -Parent
write-host "Current script path: $expectedDirectory"
push-location $expectedDirectory
Write-Verbose "Changed location to script folder: $expectedDirectory"

$includesFolder = "$(pwd)/includes"
Write-Verbose "dot sourcing: $includesFolder"
if (-not (Test-Path -Path $includesFolder)) 
{
    write-host "Includes folder $includesFolder not found." -ForegroundColor Red
    exit 1
}
$includefiles = get-childitem -path $includesFolder -recurse -filter *.ps1
if (-not $includefiles) {
    write-host "No include files found in $includesFolder" -ForegroundColor Yellow
    exit 1
}
get-childitem -path $includesFolder -recurse -filter *.ps1 |% { 
    Write-Verbose "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

$parametersToValidate = @(
    @{ Value = $dtOverlay; Name = "dtOverlay" }
)

foreach ($param in $parametersToValidate) 
{
    Test-ScriptParametersAreValid -paramValue $param.Value -paramName $param.Name
}

function New-DataFolders($foldersToCreate, $userFoldersToCreate)
{
    New-Folders -foldersToCreate $foldersToCreate -baseFolder "~"
    New-Folders -foldersToCreate $userFoldersToCreate -baseFolder "~/data/user-files"
}


$foldersToCreate = @("data/.pedalboards", "data/user-files", ".lv2")
$linkedFolders = @(".lv2", ".pedalboards")
$userFoldersToCreate = @("Speaker Cabinets IRs", "Reverb IRs", "Audio Loops", "Audio Recordings", "Audio Samples", "Audio Tracks", "MIDI Clips", "MIDI Songs", "Hydrogen Drumkits", "SF2 Instruments", "SFZ Instruments", "Amplifier Profiles", "Aida DSP Models", "NAM Models")
$pythonSetupScript = "../bash/python-venv.sh"
Write-Host "----------------------------------------"
write-host "testing that we're in the expected directory..." 
Test-Were_In_Expected_Directory -expectedDirectory $expectedDirectory
Write-Host "----------------------------------------"
write-host "checking current user permissions..." 
Test-CurrentUserHasCorrectPermissions -shouldBeRoot $false #prevent running as root so that folders created are owned by the normal user, and other security reasons.
Write-Host "----------------------------------------"
write-host "getting OS release information..." 
Get-OSRelease #sets global variables from /etc/os-release
Write-Host "----------------------------------------"
write-host "creating data folders..." 
#New-DataFolders -foldersToCreate $foldersToCreate -userFoldersToCreate $userFoldersToCreate
Write-Host "----------------------------------------"
Write-Host "creating linked folders"
#New-LinkedFolders -linkedFolders $linkedFolders
Write-Host "----------------------------------------"
Write-Host "creating new python environment."

New-PythonVenv -venvPath "$($HOME)/.env"
Write-Host "----------------------------------------"
Write-Host "installing all required python packages into venv."

write-host "running python-venv.sh to setup python venv..."
if (Test-Path -Path $pythonSetupScript) 
{
    write-host "found python-venv.sh, running it..."
    bash $pythonSetupScript
}
else 
{
    write-host "python-venv.sh not found, cannot setup python venv." -ForegroundColor Red
    exit 1
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
        #find the file underneath the venv site-packages folder by using recursive get-childitem
        $fileToPatch = Get-ChildItem -Path "$venvPath/lib/python$pythonVersion/site-packages/" -Recurse -Filter $_ | Select-Object -First 1

        if (-not (Test-Path -Path $fileToPatch)) 
        {
            write-host "File $fileToPatch not found, cannot patch." -ForegroundColor Yellow
            exit 1
        }
        Invoke-PatchPythonFile -FileToPatch $fileToPatch
    }
    # $httputilPath = "$venvPath/lib/python$pythonVersion/site-packages/tornado/httputil.py"
    # $managerPath = "$venvPath/lib/python$pythonVersion/site-packages/browsepy/manager.py"
    # $replacedContent = (Get-Content -path $httputilPath) -replace 
    # set-content -path $httputilPath -value 
    # set-content -path $httputilPath -value (Get-Content -path $httputilPath) -replace 'collections\.Mapping', 'collections.abc.Mapping'
    # set-content -path $managerPath -value (Get-Content -path $managerPath) -replace 'collections\.Mapping', 'collections.abc.Mapping'
}
Write-Host "----------------------------------------"
#for python version we only need the major.minor part, eg 3.11. use regex to get named group for major.minor
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
    Write-Host "patching python files for compatibility with python $pythonVersion."
    if ($null -eq $pythonVersion) 
    {
        write-host "could not determine python version, cannot patch python files." -ForegroundColor Red
        exit 1
    }
    return $pythonVersion
}
$pythonVersion = Get-PythonVersion 
Invoke-PatchPythonFiles -pythonVersion $pythonVersion -venvPath "$($HOME)/.env"