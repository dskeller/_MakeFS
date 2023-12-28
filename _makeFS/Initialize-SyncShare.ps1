<#
  .SYNOPSIS
  Initialize-SyncShare.ps1
  Initialize SyncShareState for all SyncShares on local Server

  .COMPONENT
  SyncShare
  ActiveDirectory

  .DESCRIPTION
  Initialize SyncShareState for all folders in all SyncShares on local Server where a user with the same name exists in the Active Directory.
  based on changing state, checking syncshares and searching the active directory the following conditions must be met:
  * runasadministrator
  * PowerShell module SyncShare
  * PowerShell module ActiveDirectory

  .INPUTS
  None

  .OUTPUTS
  No output to be piped

  .EXAMPLE
  .\initialize-syncshare.ps1



#>
#requires -RunAsAdministrator
#requires -Module SyncShare
#requires -Module ActiveDirectory

[CmdletBinding()]
param()

Import-Module SyncShare,ActiveDirectory

# get list of all syncshares from local system
$syncShareList = Get-SyncShare

foreach ($syncShare in $syncShareList){
  $userList = Get-ChildItem $syncShare.Path | Sort-Object -Property Name
  foreach ($user in $userList) {
    <# $user is the current item #>
    $isAD = $false
    # check user in active directory
    if ($(Get-ADUser $user.Name)){
      $isAD = $true
    }
    if ($isAD -eq $true){
      try{
        # fix syncsharestate for $user on $syncshare
        Repair-SyncShare -Name $syncShare.Name -User $user.Name
      }catch{
      Write-Error "Error with '$($user.Name)'. Error was $_"
      }
    }else{
      Write-Warning "$($user.Name) not found in Active Directory"
    }
  }
}
