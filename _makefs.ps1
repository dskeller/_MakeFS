<#
  _makefs.ps1
  
  create standardized file-server with
  - Fileservice
  - SyncShareService
  - Print-Service
  - DHCP
  - RSAT-Tools for roles and Active Directory
#>

#Standort-Parameter (anzupassen)
$oldpath = "\\FS-01\fileserv$"
$folderlist = @("share1", "share2", "groupshare", "usershome", "usersprofile")


#ab hier finger weg
# #fingerab
$logfolder = "C:\logs"
$LogFile = $logfolder + "\" + $($MyInvocation.MyCommand.Name)
$newpath = "C:\fileserv"
$roboparams = @('/COPYALL', '/MIR', '/MT:128', '/COPY:DATSOU', '/DCOPY:DAT', '/DST', '/R:1', '/W:2', '/NC', '/NP', '/J', '/SEC', '/B')

function Write-Log
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    $message,
    [Parameter(Mandatory = $false)]
    [ValidateSet('INFO', 'WARN', 'ERROR')]
    [string]
    $level = 'HINT',
    [Parameter(Mandatory = $false)]
    [string]
    $Log = $LogFile
  )
  if ($level -eq 'INFO')
  {
    [System.ConsoleColor]$color = 'Green'
  }
  elseif ($level -eq 'WARN')
  {
    [System.ConsoleColor]$color = 'Yellow'
  }
  elseif ($level -eq 'ERROR')
  {
    [System.ConsoleColor]$color = 'Red'
  }
  else
  {
    [System.ConsoleColor]$color = 'White'
  }
  $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $output = $date + " " + $level + " : " + $message
  Write-Host -Object $output -ForegroundColor $color
  Out-File -InputObject $output -FilePath $LogFile -Encoding utf8
}

# starting script
Clear-Host

# create log folder
if (-not (Test-Path "$logfolder"))
{
  New-Item -Path "$logfolder" -ItemType Directory -Force
  Write-Log "Log folder created" -level INFO
}

Write-Log -message "Starting script execution" -level INFO
Write-Log -message "Log files location is: $logfolder" -level INFO

# remove unwanted/unsafe features
Write-Log -message "Uninstall-WindowsFeature -name XPS-Viewer, PowerShell-v2, FS-SMB1-Client, FS-SMB1-Server, FS-SMB1 -LogPath $logfolder\Uninstall-WindowsFeature.log" -level INFO
#Uninstall-WindowsFeature -name XPS-Viewer, PowerShell-v2, FS-SMB1-Client, FS-SMB1-Server, FS-SMB1 -LogPath $logfolder\Uninstall-WindowsFeature.log

# install needed features and restart server afterwards
Write-Log -message "Install-WindowsFeature -name FS-Fileserver, FS-SyncShareService, FS-Ressource-Manager, DHCP, Print-Server, Web-Mgmt-Console, Web-Scripting-Tools, RSAT-DHCP, RSAT-FSRM-Mgmt, RSAT-Print-Services, RSAT-ADDS-Tools, RSAT-AD-PowerShell, GPMC, Remote-Assistance -LogPath $logfolder\Install-WindowsFeature.log -Restart" -level INFO
#Install-WindowsFeature -name FS-Fileserver, FS-SyncShareService, FS-Ressource-Manager, DHCP, Print-Server, Web-Mgmt-Console, Web-Scripting-Tools, RSAT-DHCP, RSAT-FSRM-Mgmt, RSAT-Print-Services, RSAT-ADDS-Tools, RSAT-AD-PowerShell, GPMC, Remote-Assistance -LogPath $logfolder\Install-WindowsFeature.log -Restart


# copy folderstructure with permissions
Write-Log -message "Starting copy process of old server to new server" -level INFO
if (-not(Test-Path $newpath))
{
  Write-Log -message "New-Item -Path '$newpath' -ItemType Directory -Force" -level INFO
  New-Item -Path "$newpath" -ItemType Directory -Force
}

Write-Log -message "Each folder has its own log file for copied directories and files" -level INFO

foreach ($folder in $folderlist)
{
  # shared folder on on old server
  $old = $oldpath + "\" + $folder

  # check if source is available, if not stop working on it
  if (-not(Test-Path -Path $old -PathType Container))
  {
    $message = "Unable to access '" + $old + "'"
    Write-Log $message -level ERROR
  }
  else
  {
    # new local folder with share name
    $new = $newpath + "\" + $folder

    # log file for each share
    $rLogFile = $logfolder + "\" + $folder + ".log"

    # add logfile to robocopy params
    $arguments = $roboparams + "/UNILOG+:$rLogFile"

    # new folder name is the same as old folder name
    $message = "Starting copy '" + $old + "' -> '" + $new + "'"
    Write-Log $message -level INFO
    Write-Log -message "Logfile is: $rLogFile" -level INFO
    Write-Log -message "Start-Process -Wait -FilePath `"$env:windir\System32\Robocopy.exe`" -ArgumentList `"$old $new $arguments`"" -level INFO
    Start-Process -Wait -FilePath "$env:windir\System32\Robocopy.exe" -ArgumentList "$old $new $arguments"
    $message = "Finished copy '" + $old + "' -> '" + $new + "'"
    Write-Log -message $message -level INFO 
  }
}

