[CmdletBinding()]
Param(
)

$baseUri = '%REPOSITORIESURL%'
$UserName = $ENV:USERNAME
$homeDirectory = Get-Item $HOME

Push-Location $homeDirectory.FullName

if (-Not (Test-Path -Path ".\LocalDocuments")) {
  New-Item -ItemType Directory -Path ".\LocalDocuments"
}

if (Test-Path -Path ".\.svn") {
  svn update --username "$UserName"
}
else {
  Push-Location ..
  svn co "$baseUri/$UserName" --username "$UserName"
  Pop-Location

  $ignorelist = (svn status | ForEach-Object {$_ -replace '^\?\s+(?<name>.*)$','${name}'}) -join "`n"
  svn propset svn:ignore $ignorelist .
  svn commit -m "setting up user '$UserName' (svn:ingore)"
}
