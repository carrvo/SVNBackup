[CmdletBinding()]
Param(
  [Parameter()]
  [string]$BackupInstallPath = "C:\Program Files\",

  [Parameter(Mandatory)]
  [string]$ApacheInstall,

  [Parameter(Mandatory)]
  [string]$UserBackupRepositoryPath,

  [Parameter(Mandatory)]
  [string]$UserBackupPassowrdPath,

  [Parameter(Mandatory)]
  [string]$UserBackupAccessPath,

  [Parameter(Mandatory)]
  [string]$UserBackupRepositoryUri
)

$apache = '%APACHEINSTALL%'
$install = '%BACKUPINSTALL%'
$installPath = "$BackupInstallPath\SVNBackup\"
$baseUri = '%REPOSITORIESURL%'
$repoPath = if ("$UserBackupRepositoryPath" -Match '^file://')
  { "$UserBackupRepositoryPath" }
  else { "file://localhost/$($UserBackupRepositoryPath -replace '\\','/')" }
$passFile = '%PASSWORDFILE%'
$accessFile = '%ACCESSFILE%'

New-Item -ItemType Directory -Path $installPath -Force

Get-Item -Path "$PSScriptRoot\Add-User.ps1" |
  Get-Content |
  ForEach-Object {$_ -replace $baseUri,$repoPath} |
  ForEach-Object {$_ -replace $apache,$ApacheInstall} |
  ForEach-Object {$_ -replace $passFile,$UserBackupPassowrdPath} |
  ForEach-Object {$_ -replace $accessFile,$UserBackupAccessPath} |
  Set-Content -Path "$installPath\Add-User.ps1" -Force

Get-Item -Path "$PSScriptRoot\Update-UserBackup.ps1" |
  Get-Content |
  ForEach-Object {$_ -replace $baseUri,$UserBackupRepositoryUri} |
  Set-Content -Path "$installPath\Update-UserBackup.ps1" -Force

Get-Item -Path "$PSScriptRoot\UserBackup.cmd" |
  Get-Content |
  ForEach-Object {$_ -replace $install,$installPath} |
  Set-Content -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\UserBackup.cmd" -Force
