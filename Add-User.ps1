#Requires -RunAs

[CmdletBinding()]
Param(
  [Parameter(Mandatory)]
  [string]$FullName,

  [Parameter(Mandatory)]
  [string]$UserName,

  [Parameter(Mandatory)]
  [securestring]$Password
)

$baseUri = '%REPOSITORIESURL%'
$baseRepoName = $baseUri |
  Select-String '/(?<repo>[\w\d]+)/?$' |
  Select -ExpandProperty Matches |
  Select -ExpandProperty Groups |
  Where Name -EQ repo |
  Select -ExpandProperty Value

<#
.NOTES
https://stackoverflow.com/a/7469473
#>
function ConvertFrom-SecureStringToPlainText ($SecureString) {
  $password = $SecureString #| ConvertFrom-SecureString
  $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password)
  $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
  $result
}

Push-Location '%APACHEINSTALL%\Apache24\bin\'
ConvertFrom-SecureStringToPlainText -SecureString $Password | .\htpasswd.exe -i '%PASSWORDFILE%' $UserName
Pop-Location
Add-Content -Path '%ACCESSFILE%' -Value "

[$baseRepoName`:/$UserName]
$UserName = rw
"

New-LocalUser -Name $UserName -FullName $FullName -Password $Password -AccountNeverExpires -PasswordNeverExpires
Add-LocalGroupMember -Group Users -Member $UserName

svn mkdir --message "creating user '$UserName'" --parents "$baseUri/$UserName/"
