function Invoke-ChangeToDirectory($directory) 
{
    Write-Host "Changing to directory: $directory"
    Set-Location -Path $directory
}

function Test-ScriptParametersAreValid($paramValue, $paramName)
{ 
    if ([string]::IsNullOrEmpty($paramValue)) 
    { 
        throw "$paramName cannot be null or empty." 
    } 
}
function Test-Were_In_Expected_Directory($expectedDirectory)
{
    Write-Host "Testing if the current directory is $expectedDirectory." -ForegroundColor Blue
    Write-Host "Checking current folder: $($(pwd).Path)" -ForegroundColor Blue
    if (((pwd).Path) -ne "$expectedDirectory")
    {
        Write-Host "We're currently in $((pwd).Path). this is not the right directory."
        exit 1
    }
    else
    {
        Write-Host "You are in the correct folder ($expectedDirectory)." -ForegroundColor Green
    }
}
