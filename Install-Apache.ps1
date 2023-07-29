#Requires -RunAs

[CmdletBinding()]
Param(
  [Parameter()]
  [ValidateSet("Windows")]
  [string]$Platform = "Windows",

  [Parameter()]
  [string]$VCRedistBinary = "https://aka.ms/vs/17/release/VC_redist.x64.exe", #"https://download.visualstudio.microsoft.com/download/pr/eaab1f82-787d-4fd7-8c73-f782341a0c63/917C37D816488545B70AFFD77D6E486E4DD27E2ECE63F6BBAAF486B178B2B888/VC_redist.x64.exe",

  [Parameter()]
  [string]$ApacheBinary = "https://apache-http-server.en.softonic.com/download",

  [Parameter()]
  [string]$DavSvnModule = "https://github.com/nono303/win-svn/archive/refs/tags/1.14.0.zip",

  [Parameter()]
  [int]$DavVSVersion = 15,

  [Parameter()]
  [string]$DavArchitecture = "x86",

  [Parameter()]
  [string]$InstallDirectory = "C:\Program Files\",

  [Parameter()]
  [switch]$NoConfigOverride,

  [Parameter()]
  [string]$ServiceName = "Apache-SVN"
)

Write-Progress -Activity "Installing Apache" -CurrentOperation "Installing VC Redist"

$VCRedist = if ("$VCRedistBinary" -Match '^https?://') {
  $zipName = "$PSScriptRoot\VC_redist.x64.exe"
  Invoke-WebRequest -Uri $VCRedistBinary -UseBasicParsing -OutFile $zipName
  Get-Item -Path $zipName -ErrorAction Stop
} else { Get-Item -Path "$VCRedistBinary" -ErrorAction Stop }
& $VCRedist

Write-Progress -Activity "Installing Apache" -CurrentOperation "Retrieving ZIPs"

$ApacheZip = if ("$ApacheBinary" -Match '^https?://') {
  $zipName = "$PSScriptRoot\Apache.zip"
  Invoke-WebRequest -Uri $ApacheBinary -UseBasicParsing -OutFile $zipName
  Get-Item -Path $zipName -ErrorAction Stop
} else { Get-Item -Path "$ApacheBinary" -ErrorAction Stop }

$DavZip = if ("$DavSvnModule" -Match '^https?://') {
  $zipName = "$PSScriptRoot\win-svn.zip"
  Invoke-WebRequest -Uri $DavSvnModule -UseBasicParsing -OutFile $zipName
  Get-Item -Path $zipName -ErrorAction Stop
} else { Get-Item -Path "$DavSvnModule" -ErrorAction Stop }

Write-Progress -Activity "Installing Apache" -CurrentOperation "Expanding ZIPs"

New-Item -ItemType Directory -Path "$InstallDirectory\" -ErrorAction SilentlyContinue
Expand-Archive -Path $ApacheZip -DestinationPath "$InstallDirectory\" -Force
Expand-Archive -Path $DavZip -DestinationPath "$InstallDirectory\" -Force

Write-Progress -Activity "Installing Apache" -CurrentOperation "Hardlink DLLs"

$ApacheInstall = Get-ChildItem -Path $InstallDirectory -Recurse -Filter Apache24 -ErrorAction SilentlyContinue |
  Select-Object -First 1
$DavInstall = Get-ChildItem -Path $InstallDirectory -Recurse -Filter "v*$DavVSVersion" -ErrorAction SilentlyContinue |
  Get-ChildItem -Filter $DavArchitecture |
  Select-Object -First 1
$DavDeps = $DavInstall | Get-ChildItem -Filter deps

$apache = $ApacheInstall | Get-ChildItem -Filter bin | Get-ChildItem
$DavDeps | Get-ChildItem | Where-Object Name -NotIn $apache.Name | ForEach-Object {
  New-Item -ItemType HardLink -Path "$($ApacheInstall.FullName)\modules\" -Name $_.Name -Value $_.FullName
}
$DavInstall | Get-ChildItem | Where-Object Name -Match '\.(pdb|dll)$' | Where-Object Name -NotIn $apache.Name | ForEach-Object {
  New-Item -ItemType HardLink -Path "$($ApacheInstall.FullName)\bin\" -Name $_.Name -Value $_.FullName
}
$DavInstall | Get-ChildItem | Where-Object Name -Match '\.so$' | ForEach-Object {
  New-Item -ItemType HardLink -Path "$($ApacheInstall.FullName)\modules\" -Name $_.Name -Value $_.FullName -Force
}

Write-Progress -Activity "Installing Apache" -CurrentOperation "Set Environment Variables"

$OldPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
$NewPath = "$OldPath;$($ApacheInstall.FullName)\bin;$($DavInstall.FullName);$($DavDeps.FullName)"
[System.Environment]::SetEnvironmentVariable("Path", $NewPath, [System.EnvironmentVariableTarget]::Machine)

$OldConfig = $ApacheInstall | Get-ChildItem -Filter conf | Get-ChildItem -Filter *conf
if (-Not $NoConfigOverride) {
  Write-Progress -Activity "Installing Apache" -CurrentOperation "Override Config"

  $OldConfig | Rename-Item -NewName "$OldConfig.ORIGINAL"
  Get-Item -Path "$PSScriptRoot\httpd.conf" | Copy-Item -Destination $OldConfig.FullName
}

Write-Progress -Activity "Installing Apache" -CurrentOperation "Register Service"

Push-Location "$($ApacheInstall.FullName)\bin\"
.\httpd.exe -k install -n $ServiceName
Pop-Location

Write-Progress -Activity "Installing Apache" -Completed
Write-Host "Please fill in $OldConfig!" -ForegroundColor Red
Write-Host "Test with ``$($ApacheInstall.FullName)\bin\httpd.exe -t -n $ServiceName``!" -ForegroundColor Green
