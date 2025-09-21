
get-childitem -path .\setup\includes\*.ps1 | foreach { 
    write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}


Disable-BuiltInAudio
Enable-AudioOverlay
