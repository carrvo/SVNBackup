[CmdletBinding()]
Param(
)

$baseUri = '%REPOSITORIESURL%'
$UserName = $ENV:USERNAME
$homeDirectory = Get-Item $HOME
$backupDirectories = '%USERDIRECTORIES%'

$backupDirectories | ForEach-Object -Begin {Push-Location} -Process {
  if (Test-Path -Path "$($homeDirectory.FullName)\$_\.svn") {
    Set-Location "$($homeDirectory.FullName)\$_"
    svn update --username "$UserName"
  }
  else {
    Set-Location $homeDirectory.FullName
    svn co "$baseUri/$UserName/$_" --username "$UserName"
  }
} -End {Pop-Location}

if (-Not (Test-Path -Path "$($homeDirectory.FullName)\LocalDocuments")) {
  New-Item -ItemType Directory -Path "$($homeDirectory.FullName)\LocalDocuments"
}
