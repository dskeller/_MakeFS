#Requires -runasadministrator
<#
  _makefs.ps1

  create standardized file-server with
  - Fileservice
  - SyncShareService
  - Print-Service
  - DHCP
  - RSAT-Tools for roles and Active Directory
  - Sync Folders from old system to new
  - Print Server Migration
  - DHCP Server Migration
  - Computer certificate request for work folder service
#>
[CmdletBinding(DefaultParameterSetName = 'None')]
param (
  [Parameter(Mandatory = $true, ParameterSetName = 'PrintService')]
  [Parameter(Mandatory = $true, ParameterSetName = 'DHCPService')]
  [Parameter(Mandatory = $true, ParameterSetName = 'FileService')]
  [Parameter(Mandatory = $true, ParameterSetName = 'All')]
  [string]$oldserver, # Name of the old server
  [Parameter(Mandatory = $false, ParameterSetName = 'Serverlog')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [switch]$Serverlog, # Switch to create serverlog file in startup
  [Parameter(Mandatory = $false, ParameterSetName = 'Serverlog')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [string]$serverlogheader = "$PSScriptRoot\serverlog-header.txt", # default is a file in script folder
  [Parameter(Mandatory = $false, ParameterSetName = 'FileService')]
  [switch]$FileService, # Switch to copy files
  [Parameter(Mandatory = $false, ParameterSetName = 'FileService')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [string[]]$sharelist = @("groupshare", "usershome$", "images$", "usersprofile$"), # List of shares on old server
  [Parameter(Mandatory = $false, ParameterSetName = 'FileService')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [string]$newpath = "E:\fileserv", # location of files on local server
  [Parameter(Mandatory = $false, ParameterSetName = 'FileService')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [switch]$createshare, # create share on local server
  [Parameter(Mandatory = $false, ParameterSetName = 'InstallWindowsFeatures')]
  [switch]$InstallWindowsFeatures, # Switch to install roles and features
  [Parameter(Mandatory = $false, ParameterSetName = 'UninstallWindowsFeatures')]
  [switch]$UninstallWindowsFeatures, # Switch to uninstall roles and features
  [Parameter(Mandatory = $false, ParameterSetName = 'PrintService')]
  [switch]$PrintService, # Switch to migrate print service
  [Parameter(Mandatory = $false, ParameterSetName = 'DHCPService')]
  [switch]$DHCPService, # Switch to migrate dhcp service
  [Parameter(Mandatory = $false, ParameterSetName = 'Certificate')]
  [switch]$Certificate, # Switch to generate certificate request
  [Parameter(Mandatory = $false, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [string]$FQDN = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName, # Server FQDN for certificate
  [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $true, ParameterSetName = 'All')]
  [string]$Mail, # Mail, for certificate renew or revoke
  [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $true, ParameterSetName = 'All')]
  [string]$Organization, # Organization of the new server for certificate
  [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $true, ParameterSetName = 'All')]
  [string]$OrganizationalUnit, # Organizational unit of the new server for certificate
  [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $true, ParameterSetName = 'All')]
  [string]$City, # City, the new server is located for certificate
  [Parameter(Mandatory = $false, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [string]$State = "Schleswig-Holstein", # State, the new server is located for certificate
  [Parameter(Mandatory = $false, ParameterSetName = 'Certificate')]
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [string]$Country = "DE", # Country, the new server is located
  [Parameter(Mandatory = $false, ParameterSetName = 'All')]
  [switch]$All                                                                      # Switch to do all migration steps excl. install roles and features
)

#########################################
#
# no changes beyond this point
#
$logfolder = "C:\logs\Migration"
$LogFile = $logfolder + "\" + $($($MyInvocation.MyCommand.Name).Replace('.ps1', '.log'))
$roboparams = @('/COPYALL', '/MIR', '/MT:128', '/COPY:DATSOU', '/DCOPY:DAT', '/DST', '/R:1', '/W:2', '/NC', '/NP', '/J', '/SEC', '/ZB', '/BYTES', '/XF Sync-UserProfile.log Thumbs.db ~$* ~*.tmp ~*.wbk fbc*.tmp', '/XD profile.v2')
$serverlogfile = $env:ProgramData + "\Microsoft\Windows\Start Menu\Programs\StartUp\serverlog.txt"
$serverlogheadercontent = Get-Content -Path $serverlogheader

#region functions
function Write-Log {
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
  if ($level -eq 'INFO') {
    [System.ConsoleColor]$color = 'Green'
  }
  elseif ($level -eq 'WARN') {
    [System.ConsoleColor]$color = 'Yellow'
  }
  elseif ($level -eq 'ERROR') {
    [System.ConsoleColor]$color = 'Red'
  }
  else {
    [System.ConsoleColor]$color = 'White'
  }
  $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $output = $date + " " + $level + " : " + $message
  Write-Host -Object $output -ForegroundColor $color
  Out-File -InputObject $output -FilePath $LogFile -Encoding utf8 -Append
}
#endregion functions

#region main

# starting script
Clear-Host

# create log folder
if (-not (Test-Path "$logfolder")) {
  try {
    New-Item -Path "$logfolder" -ItemType Directory -Force
  }
  catch {
    Write-Host "ERROR: Unable to create Log and Temp Folder $logfolder"
    Pause
    exit 1
  }
  Write-Log "Log folder created" -level INFO
}

Write-Log -message "Starting script execution" -level INFO
Write-Log -message "Log files location is: $logfolder" -level INFO

#region serverlog
if (($Serverlog.IsPresent -eq $true) -or ($All.IsPresent -eq $true)) {
  if (-not (Test-Path "$serverlogfile" -PathType Leaf)) {
    Write-Log -message "Starting serverlog creation and setting file permission" -level INFO
    try {
      [void]$(New-Item -Path "$serverlogfile" -ItemType File -Force)
      Out-File -InputObject $serverlogheadercontent -FilePath "$serverlogfile"
      Start-Process -FilePath "$env:windir\System32\icacls.exe" -ArgumentList "`"$serverlogfile`" /grant *S-1-5-32-545:M"
      Write-Log -message "Serverlog created" -level INFO
    }
    catch {
      Write-Log -message "Unable to create $serverlogfile" -level ERROR
    }
  }
  else {
    Write-Log -message "'$serverlogfile' already exists. Setting permissions to User:M" -level INFO
    Start-Process -FilePath "$env:windir\System32\icacls.exe" -ArgumentList "`"$serverlogfile`" /grant *S-1-5-32-545:M"
  }
}
else {
  Write-Log -message "Skipping Serverlog creation" -level INFO
}
#endregion serverlog

#region windowsRaF
if (($InstallWindowsFeatures.IsPresent -eq $true) -and ($UninstallWindowsFeatures.IsPresent -eq $true)) {
  Write-Log -message "Currently it is not possible to uninstall and install windows roles and features in the same run. please restart with just one parameter specified" -level ERROR
  break
}

if ($UninstallWindowsFeatures.IsPresent -eq $true) {
  # remove unwanted/unsafe features
  Write-Log -message "Uninstall-WindowsFeature -name PowerShell-v2, FS-SMB1-Client, FS-SMB1-Server, FS-SMB1 -LogPath `"$logfolder\Uninstall-WindowsFeature.log`"" -level INFO
  $uninstJob = Start-Job -Command { Uninstall-WindowsFeature -Name PowerShell-v2, FS-SMB1-Client, FS-SMB1-Server, FS-SMB1 -LogPath "$logfolder\Uninstall-WindowsFeature.log" }
  Receive-Job -Job $uninstJob -Wait | Select-Object Success, RestartNeeded, exitCode, FeatureResult

  # reboot system
  Write-Log -message "Restarting server to disable roles and features" -level INFO
  # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32shutdowntracker-method-in-class-win32-operatingsystem
  # Timeout, Comment, ReasonCode,  Flags (6 = Forced Reboot)
  # https://docs.microsoft.com/en-us/windows/win32/shutdown/system-shutdown-reason-codes
  # SHTDN_REASON_MAJOR_OPERATINGSYSTEM | SHTDN_REASON_MINOR_RECONFIG | SHTDN_REASON_FLAG_PLANNED
  # 0x00020000                         | 0x00000004                  | 0x80000000
  # adding clean-ui (https://devblogs.microsoft.com/oldnewthing/20100831-00/?p=12993) 0x04000000
  # -> 0x80020004
  # -> [uint32]"0x84020004"
  $rargs = @{
    Timeout    = [System.UInt32]0
    Comment    = 'Uninstall Windows roles and features'
    ReasonCode = [System.UInt32]2214723588
    Flags      = 6
  }
  Invoke-CimMethod -Query 'SELECT * FROM Win32_OperatingSystem' -MethodName 'Win32ShutdownTracker' -Arguments $rargs
}
else {
  Write-Log -message "Skipping Disabling Windows roles and features" -level INFO
}

if ($InstallWindowsFeatures.IsPresent -eq $true) {
  # install needed features and restart server afterwards
  Write-Log -message "Install-WindowsFeature -name FS-Fileserver, FS-SyncShareService, FS-Resource-Manager, DHCP, Print-Server, Web-Mgmt-Console, Web-Scripting-Tools, RSAT-DHCP, RSAT-FSRM-Mgmt, RSAT-Print-Services, RSAT-ADDS-Tools, RSAT-AD-PowerShell, GPMC, Remote-Assistance -LogPath `"$logfolder\Install-WindowsFeature.log`"" -level INFO
  $instJob = Start-Job -Command { Install-WindowsFeature -Name FS-Fileserver, FS-SyncShareService, FS-Resource-Manager, DHCP, Print-Server, Web-Mgmt-Console, Web-Scripting-Tools, RSAT-DHCP, RSAT-FSRM-Mgmt, RSAT-Print-Services, RSAT-ADDS-Tools, RSAT-AD-PowerShell, GPMC, Remote-Assistance -LogPath "$logfolder\Install-WindowsFeature.log" }
  Receive-Job -Job $instJob -Wait | Select-Object Success, RestartNeeded, exitCode, FeatureResult

  # reboot system
  Write-Log -message "Restarting server to enable roles and features" -level INFO
  $rargs = @{
    Timeout    = [System.UInt32]0
    Comment    = 'Install Windows roles and features'
    ReasonCode = [System.UInt32]2214723588
    Flags      = 6
  }
  Invoke-CimMethod -Query 'SELECT * FROM Win32_OperatingSystem' -MethodName 'Win32ShutdownTracker' -Arguments $rargs
}
else {
  Write-Log -message "Skipping Enabling Windows roles and features" -level INFO
}
#endregion windowsRaF

#region fileservice
if (($FileService.IsPresent -eq $true) -or ($All.IsPresent -eq $true)) {
  # copy folder structure with permissions
  Write-Log -message "Starting copy process of '$oldserver' to '$newpath'" -level INFO
  if (-not(Test-Path $newpath)) {
    Write-Log -message "New-Item -Path '$newpath' -ItemType Directory -Force" -level INFO
    try {
      New-Item -Path "$newpath" -ItemType Directory -Force
    }
    catch {
      Write-Log "Unable to create path" -level ERROR
      exit 1
    }
  }

  Write-Log -message "Each share has its own log file for copied directories and files" -level INFO
  foreach ($share in $sharelist) {
    # shared folder on old server
    $old = '\\' + $oldserver + '\' + $share

    # check if source is available, if not stop working on it
    if (-not(Test-Path -Path $old -PathType Container)) {
      $message = "Unable to access '" + $old + "'"
      Write-Log $message -level ERROR
    }
    else {
      #get share on old server
      $oShare = Get-CimInstance -ComputerName $oldserver -ClassName win32_share -Filter "Name = '$share'"
      #folder name and description
      $folder = Split-Path $($oShare.Path) -Leaf
      $description = $oShare.Description

      #if complete disks (administrative Shares [LW]$) are copied
      if ($folder -match '([A-Z]|[a-z])\:\\' ) {
        $folder = $folder.TrimEnd(':\')
        $createshare = $false
      }

      # new local folder with share name
      $new = $($newpath.TrimEnd('\') + "\" + $folder).TrimEnd('\')

      # date for log file
      $sDate = Get-Date -Format yyyy-MM-dd_hh-mm

      # log file for each share
      if ($folder.Length -eq 1) {
        $rLogFile = $logfolder + "\" + $sDate + "_disk_" + $folder + ".log"
      }
      else {
        $rLogFile = $logfolder + "\" + $sDate + "_" + $folder + ".log"
      }

      # add log file location to robocopy params
      $arguments = $roboparams + "/UNILOG+:$rLogFile"

      # new folder name is the same as old folder name
      $message = "Starting copy '" + $old + "' -> '" + $new + "'"
      Write-Log $message -level INFO
      Write-Log -message "Logfile is: $rLogFile" -level INFO
      Write-Log -message "Start-Process -NoNewWindow -Wait -FilePath `"$env:windir\System32\Robocopy.exe`" -ArgumentList `"$old $new $arguments`"" -level INFO
      Start-Process -NoNewWindow -Wait -FilePath "$env:windir\System32\Robocopy.exe" -ArgumentList "`"$old`" `"$new`" $arguments"
      $message = "Finished copy '" + $old + "' -> '" + $new + "'"
      Write-Log -message $message -level INFO

      #share new folder
      if ($createshare -eq $false) {
        $message = "Skipping sharing of '$new'"
        Write-Log -message $message -level INFO
      }
      else {
        if (-not(Get-SmbShare -Name $share)) {
          $message = "Creating share '$share' for '$new'"
          Write-Log -message $message -level INFO
          $message = "New-SmbShare -Name $share -Path `"$new`" -Description `"$Description`" -FolderEnumerationMode AccessBased -CachingMode None -FullAccess `"Jeder`""
          Write-Log -message $message -level INFO
          try {
            New-SmbShare -Name $share -Path "$new" -Description $description -FolderEnumerationMode AccessBased -CachingMode None -FullAccess "Jeder"
          }
          catch {
            $message = "Unable to create share. Error was $_"
            Write-Log -message $message -level ERROR
          }
        }
        else {
          $message = "Creating share '$share' for '$new' failed. share name already exists."
          Write-Log -message $message -level ERROR
        }
      }
    }
  }
}
else {
  Write-Log -message "Skipping File service migration" -level INFO
}
#endregion fileservice

#region printservice
if (($PrintService.IsPresent -eq $true) -or ($All.IsPresent -eq $true)) {
  # print server migration

  # tool is part of server role, so check if tool is available is necessary before run
  $tool = "C:\windows\system32\spool\tools\PrintBrm.exe"
  if (-not (Test-Path -Path $tool -PathType Leaf)) {
    Write-Log -message "PrintBrm.exe not found. No print server migration" -level WARN
  }
  else {
    $printshare = '\\' + $oldserver + '\print$'
    if (-not (Test-Path -Path $printshare -PathType Container)) {
      Write-Log "`$print share on old server not reachable" -level ERROR
    }
    else {
      $cpath = Get-Location
      Set-Location -Path $(Split-Path -Path $tool -Parent)
      $printbrmbackup = $logfolder + '\' + $oldserver + ".printerExport"
      Write-Log -message "Starting print server migration" -level INFO
      if (Test-Path -Path $printbrmbackup -PathType Leaf) {
        Write-Log -message "Removing existing"
        Remove-Item -Path $printbrmbackup -Force
      }
      $export = & .\$(Split-Path -Path $tool -Leaf) -S "$oldserver" -B -F "$printbrmbackup" -O FORCE
      $exportfile = $logfolder + '\printbrm-export.log'
      Out-File -FilePath $exportfile -InputObject $export -Encoding utf8
      $import = & .\$(Split-Path -Path $tool -Leaf) -R -F "$printbrmbackup" -O FORCE
      $importfile = $logfolder + '\printbrm-import.log'
      Out-File -FilePath $importfile -InputObject $import -Encoding utf8
      Set-Location $cpath.path
    }
  }
}
else {
  Write-Log -message "Skipping print service migration" -level INFO
}
#endregion printservice

#region DHCP
if (($DHCPService.IsPresent -eq $true) -or ($All.IsPresent -eq $true)) {
  $dhcpbackup = $logfolder + '\' + $oldserver + "_DHCP.xml"
  Write-Log -message "Starting migrating DHCP configuration" -level INFO
  try {
    Export-DhcpServer -ComputerName $oldserver -File $dhcpbackup -Force
    try {
      Import-DhcpServer -File $dhcpbackup -BackupPath $env:TEMP
    }
    catch {
      Write-Log -message "Import of DHCP configuration failed"
    }
  }
  catch {
    Write-Log -message "Export of DHCP configuration failed"
  }
  Write-Log -message "End migrating DHCP configuration" -level INFO
}
else {
  Write-Log -message "Skipping DHCP service migration" -level INFO
}
#endregion DHCP

#region certificate
if (($Certificate.IsPresent -eq $true) -or ($All.IsPresent -eq $true)) {
  # generate INF for request with specified variables
  Write-Log -message "Generating certificate request" -level INFO
  $INFFile = $logfolder + '\' + $FQDN + '_' + $((Get-Date).ToString('yyyyMMdd')) + '.INF'
  $REQFile = $logfolder + '\' + $FQDN + '_' + $((Get-Date).ToString('yyyyMMdd')) + '_CSR.REQ'

  $Signature = '$Windows NT$'
  $SANList = @("dns=$CertName")

  $INF = @"
  [Version]
  Signature= "$Signature"

  [NewRequest]
  Exportable = TRUE ; TRUE = Privater Schlüssel ist exportierbar
  KeyLength = 256 ; Gültige Schlüsselgrößen: 256.384.512
  KeySpec = 1 ; Schlüsselaustausch – Für die Verschlüsselung erforderlich
  MachineKeySet = TRUE ; Der Standardwert ist false.
  PrivateKeyArchive = FALSE ; Die Einstellung PrivateKeyArchive funktioniert nur, wenn der entsprechende RequestType auf "CMC" gesetzt ist.
  ProviderName = "Microsoft Software Key Storage Provider"
  ProviderType = 23                                                      ; nistP256
  RequestType = PKCS10 ; Bestimmt den Standard, der zum Generieren und Senden der Zertifikatanforderung verwendet wird (PKCS10 – 1)
  SMIME = False ; Siehe symmetrische Verschlüsselungsalgorithmen, die von Secure Multipurpose Internet Mail Extensions (S/MIME) verwendet werden können.
  Subject = "E=$Mail, CN=$FQDN, OU=$OrganizationalUnit, O=$Organization, L=$City, S=$State, C=$Country"
  UseExistingKeySet = FALSE
  UserProtected = FALSE

  [Extensions]
  ; If your client operating system is Windows Server 2008, Windows Server 2008 R2, Windows Vista, or Windows 7
  ; SANs can be included in the Extensions section by using the following text format. Note 2.5.29.17 is the OID for a SAN extension.
  ; Multiple alternative names must be separated by an ampersand (&).
  2.5.29.17 = "{text}"
"@
  $SANList | ForEach-Object { $INF += "_continue_ = `"$($_)&`"`r`n" }
  $INF += "`r`n; EOF`r`n"

  $INF | Out-File -FilePath $INFFile -Force
  & certreq.exe -New $INFFile $REQFile

  Write-Log -message "Certificate Request has been generated" -level INFO
}
else {
  Write-Log -message "Skipping certificate generation" -level INFO
}
#endregion certificate

Write-Log -message "End script execution" -level INFO
#endregion main
