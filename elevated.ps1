get-childitem -path ~/pi-stomp/setup/includes/*.ps1 |% { 
    write-host "dot Sourcing $($_.FullName)"
    . $_.FullName 
}

Disable-BuiltInAudio
Enable-AudioOverlay

 