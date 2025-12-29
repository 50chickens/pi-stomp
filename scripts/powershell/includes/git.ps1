function Invoke-CheckoutGitRepo($repo) 
{
    write-host "Checking out repo $($repo.RepoURL) into folder $($repo.CheckOutFolder)"
    $targetFolder = $repo.CheckOutFolder
    $repoURL = $repo.RepoURL
    
    #if the .git folder exists in the target folder, do a git pull instead of cloning.
    if ((Test-Path -Path $targetFolder) -and (Test-Path -Path "$($targetFolder)/.git")) 
    {
        #we need to remove the .git folder because it causes problems with mod-ui later on.
        remove-item -Path "$($targetFolder)/.git" -Recurse -Force
        return  
    }
    
    write-host "Cloning repo $repoURL into folder $targetFolder"
    if (-not $repo.Branch)  #if no branch specified, clone default branch
    {
        git clone $repoURL $targetFolder    
    }
    else 
    {
        $branch = $repo.Branch
        write-host "Cloning branch $branch."
        git clone --branch $branch $repoURL $targetFolder
    }
    
    # Remove .git folder after cloning as it causes problems with mod-ui
    if (Test-Path -Path "$($targetFolder)/.git")
    {
        remove-item -Path "$($targetFolder)/.git" -Recurse -Force
        write-host "Removed .git folder from $targetFolder"
    }
}
function Invoke-CheckoutGitRepos($repos) 
{

    $repos |% {
        Invoke-CheckoutGitRepo -repo $_
    }
}

function Invoke-GitPull($targetFolder)
{
    Write-Host "Target folder $targetFolder exists; Doing git pull from $($repo.Branch) branch." -ForegroundColor Yellow
    Push-Location $targetFolder
    #test if there are local changes. if so, print warning and skip git pull.
    $localChanges = git status --porcelain
    write-host "Local changes: $localChanges"
    if ($localChanges) 
    {
        Write-Host "Warning: Local changes detected in $targetFolder; skipping git pull to avoid merge conflicts." -ForegroundColor Yellow
        Pop-Location
        return
    }
    git checkout $branch
    git pull origin $branch
    #check for errors during git pull, and write a warning to the log and continue.
    $gitLastExitCode = $LASTEXITCODE
    if ($gitLastExitCode -ne 0) 
    {
        Write-Host "Warning: git pull in $targetFolder exited with code $gitLastExitCode" -ForegroundColor Yellow
    }   
    Pop-Location
}