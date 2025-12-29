function Invoke-CheckoutGitRepo($repo) 
{
    write-host "Checking out repo $($repo.RepoURL) into folder $($repo.CheckOutFolder)"
    $targetFolder = $repo.CheckOutFolder
    $repoURL = $repo.RepoURL
    
    if (Test-Path -Path $targetFolder) 
    {
        Invoke-GitPull -targetFolder $targetFolder
        return  
    }
    write-host "Cloning repo $repoURL into folder $targetFolder"
    if (-not $repo.Branch)  #if no branch specified, clone default branch
    {
        git clone  $repoURL $targetFolder    
    }
    else 
    {
        $branch = $repo.Branch
        write-host "Cloning branch $branch."
        git clone --branch $branch $repoURL $targetFolder
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
    Write-Host "Target folder $targetFolder already exists; Doing git pull from $($repo.Branch) branch." -ForegroundColor Yellow
    pushd $targetFolder
    #test if there are local changes. if so, print warning and skip git pull.
    $localChanges = git status --porcelain
    if ($localChanges) 
    {
        Write-Host "Warning: Local changes detected in $targetFolder; skipping git pull to avoid merge conflicts." -ForegroundColor Yellow
        popd
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
    popd
}