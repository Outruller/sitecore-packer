function Open-Code {
  code P:\sitecore-packer
}

function Invoke-Step {
  Open-Code;
}

Start-Transcript -Path $PSScriptRoot\packer_open_log.log -Force -Append -NoClobber;

Try {
  Invoke-Step;

  Unregister-ScheduledTask -TaskName "PackerSetup_Resume" -Confirm:$false
}
Catch {
  Write-Host $error[0].Exception;
}

Stop-Transcript;