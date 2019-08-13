Start-Transcript -Path $PSScriptRoot\startup_log.log -Force -Append -NoClobber;

$destinationFolderPath = "$([Environment]::GetFolderPath("CommonDesktopDirectory"))\ConfigurePacker";
$destinationFolder = New-Item $destinationFolderPath -Type container -Force;
Copy-Item "$PSScriptRoot\configure.ps1" -Container $destinationFolder -Force;
Copy-Item "$PSScriptRoot\open.ps1" -Container $destinationFolder -Force;
Copy-Item "$PSScriptRoot\license.xml" -Container $destinationFolder -Force;
Copy-Item "$PSScriptRoot\secret.rb" -Container $destinationFolder -Force;
Copy-Item "$PSScriptRoot\2016_developer.rb" -Container $destinationFolder -Force;

Stop-Transcript;
