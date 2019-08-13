function Update-PowerShellGet {
  If ((Get-Module PowerShellGet).Version -eq [Version]::new(1, 0, 0, 1)) {
    
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Install-PackageProvider -Name NuGet -Scope AllUsers -Force -ForceBootstrap -Confirm:$false;
    Install-Module -Name PowerShellGet -Force -AllowClobber -SkipPublisherCheck -Confirm:$false;

    Remove-Item "$env:ProgramFiles\\WindowsPowerShell\\Modules\\PowerShellGet\\1.0.0.1" -Recurse -ErrorAction Ignore;
    Remove-Item "$env:ProgramFiles\\WindowsPowerShell\\Modules\\\PackageManagement\\1.0.0.1" -Recurse -ErrorAction Ignore;
  }
    
  Write-Host "Windows features updated: PowerShellGet." -ForegroundColor Green;
}

function Install-Chocolatey {
  Set-ExecutionPolicy Unrestricted -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));

  $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).path)\..\..";
  Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1";
  refreshenv;

  choco feature enable -n=allowGlobalConfirmation;

  Write-Host "Chocolatey installed." -ForegroundColor Green;
}

function Install-DevSoft { 
  choco install gitkraken;
  choco install dotnetcore-sdk;
  choco install vscode;

  refreshenv;

  code --install-extension robertohuertasm.vscode-icons;
  code --install-extension ms-vscode.csharp;
  code --install-extension ms-vscode.powershell;
  code --install-extension cake-build.cake-vscode;
  code --install-extension rebornix.ruby;
  code --install-extension pendrica.chef;
  code --install-extension bbenoist.vagrant;

  Write-Host "Development software installed." -ForegroundColor Green;
}

function Install-PackerSoft { 
  choco install git.install;
  choco install chefdk;
  choco install packer;
  choco install virtualbox

  refreshenv;

  Write-Host "Packer software installed." -ForegroundColor Green;
}

function Install-GeneralSoft { 
  choco install 7zip.install;
  choco install totalcommander;
  choco install notepadplusplus.install;
  choco install googlechrome;

  Write-Host "General software installed." -ForegroundColor Green;
}

function Initialize-Storage {
  Initialize-Disk -Number 2 -PartitionStyle GPT;
  New-Partition -DiskNumber 2 -DriveLetter P -UseMaximumSize;
  Format-Volume -DriveLetter P -FileSystem exFAT -Confirm:$false -Force;
    
  Write-Host "Storage configured." -ForegroundColor Green;
}

function Set-SitecorePacker {
  $repoPath = "P:\sitecore-packer";
  $packerCachePath = "P:\packer-cache";

  New-Item -ItemType Directory -Force -Path $packerCachePath;
  [Environment]::SetEnvironmentVariable("PACKER_CACHE_DIR", $packerCachePath, "Machine");
	
  New-Item -ItemType Directory -Force -Path $repoPath;
  Get-SitecorePackerRepo -RepoPath $repoPath;

  Copy-Item "$PSScriptRoot\secret.rb" -Destination "$repoPath\src\components\sitecore\chef\cookbooks\scp_sitecore\attributes" -Recurse -force;
  Copy-Item "$PSScriptRoot\license.xml" -Destination "$repoPath\src\components\sitecore\chef\cookbooks\scp_sitecore\files" -Recurse -force;
  Copy-Item "$PSScriptRoot\2016_developer.rb" -Destination "$repoPath\src\components\sql\chef\cookbooks\scp_sql\attributes" -Recurse -force;
    
  Write-Host "Packer repository configured." -ForegroundColor Green;
}

function Get-SitecorePackerRepo($repoPath) {
  $repoURL = "https://github.com/asmagin/sitecore-packer.git";
  git clone --recurse-submodules $repoURL $repoPath -q;
    
  Write-Host "Packer repository cloned." -ForegroundColor Green;
}

function Disable-UAC {
  try {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value "0"  
  }
  catch {
    Write-Host "Issues with setting EnableLUA" -ForegroundColor Reg;
  }
  
  try {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value "0" 
  }
  catch {
    Write-Host "Issues with setting ConsentPromptBehaviorAdmin" -ForegroundColor Reg;
  }
    
  Write-Host "UAC disabled." -ForegroundColor Green;
}

function Set-Folder-Options {
  $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
  Set-ItemProperty $key Hidden 1
  Set-ItemProperty $key HideFileExt 0
  Set-ItemProperty $key ShowSuperHidden 1
    
  Write-Host "Folder options configured." -ForegroundColor Green
}

function Enable-Search {
  Set-Service -Name WSearch -StartupType Automatic
  # To make default admin able to search we should set "User Account Control: Use Admin Approval Mode for the built-in Administrator account" to "Enabled"
  Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "FilterAdministratorToken" -Value "1" 
    
  Write-Host "Windows Search service configured and started." -ForegroundColor Green
}

function Disable-ieESC {
  $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
  $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
  Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
  Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

  Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function New-Schedule-Task {
  $Action = New-ScheduledTaskAction `
    -Execute 'C:\Windows\System32\WindowsPowerShellv1.0\powershell.exe' `
    -Argument "-NonInteractive -NoLogo -NoProfile -File 'C:\Users\Public\Desktop\ConfigurePacker\open.ps1'" `
    -WorkingDirectory "C:\Users\Public\Desktop\ConfigurePacker";
  
  $Trigger = New-ScheduledTaskTrigger -RandomDelay (New-TimeSpan -Minutes 3) -AtStartup;
  
  $Settings = New-ScheduledTaskSettingsSet `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -DontStopOnIdleEnd `
    -RestartCount 10 `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -Compatibility Win8;
  $Settings.ExecutionTimeLimit = "PT0S";
  
  $Credentials = New-Object System.Management.Automation.PSCredential("PackerVM\packer", (ConvertTo-SecureString -String "Engine123" -AsPlainText -Force));
  $UserName = $Credentials.UserName;
  $Password = $Credentials.GetNetworkCredential().Password;
  
  Register-ScheduledTask `
    -TaskName 'PackerSetup_Resume' `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -User $UserName `
    -Password $Password `
    -RunLevel Highest `
    -Force;
}

function Invoke-Step {
  Update-PowerShellGet

  Disable-UAC;
  Enable-Search;
  Set-Folder-Options;
  Disable-ieESC;

  Install-Chocolatey;
  Install-PackerSoft;
  Initialize-Storage;
  Set-SitecorePacker;
  
  Install-GeneralSoft;
  Install-DevSoft;
}

Start-Transcript -Path $PSScriptRoot\packer_configure_log.log -Force -Append -NoClobber;

Try {
  Invoke-Step;
  New-Schedule-Task;
  Restart-Computer;
}
Catch {
  Write-Host $error[0].Exception;
}

Stop-Transcript;