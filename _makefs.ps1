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
#>
[CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)][string]$oldserver,                                                                                             # Name of the old server
    [Parameter(Mandatory = $true)][string[]]$sharelist=@("Gruppenablage","usershome$","images$","usersprofile$"),                                 # List of shares on old server
    [Parameter(Mandatory = $false)][string]$newpath = "E:\fileserv",                                                                              # location of files on local server
    [Parameter(Mandatory = $false)][string]$serverlogheader = "$PSScriptRoot\serverlog-header.txt",                                               # default is a file in script folder
    [Parameter(Mandatory = $false, ParameterSetName = "InstallRaF")][bool]$WindowsFeatures = $false,                                              # Switch to install roles and features in parameter set so it does not run each time the script is executed
    [Parameter(Mandatory = $false, ParameterSetName = "Certificate")][bool]$Certificate = $false,                                                 # Parameter to decide if computer certificate should be generated
    [Parameter(Mandatory = $true, ParameterSetName = "Certificate")][string]$City,                                                                # City, the new server is located for certificate
    [Parameter(Mandatory = $true, ParameterSetName = "Certificate")][string]$Mail,                                                                # Mail, for certificate renew or revoke
    [Parameter(Mandatory = $true, ParameterSetName = "Certificate")][string]$State,                                                               # State, the new server is located for certificate
    [Parameter(Mandatory = $true, ParameterSetName = "Certificate")][string]$Country,                                                             # Country, the new server is located
    [Parameter(Mandatory = $true, ParameterSetName = "Certificate")][string]$Organization,                                                        # Organization of the new server for certificate
    [Parameter(Mandatory = $true, ParameterSetName = "Certificate")][string]$OrganizationalUnit,                                                  # Organizational unit of the new server for certificate
    [Parameter(Mandatory = $false, ParameterSetName = "Certificate")][string]$FQDN=[System.Net.Dns]::GetHostByName(($env:computerName)).HostName  # Server FQDN for certificate
  )

#########################################
#
# no changes beyond this point
#
$logfolder              = "C:\logs\Migration"
$LogFile                = $logfolder + "\" + $($($MyInvocation.MyCommand.Name).Replace('.ps1','.log'))
$roboparams = @('/COPYALL','/MIR','/MT:128','/COPY:DATSOU','/DCOPY:DAT','/DST','/R:1','/W:2','/NC','/NP','/J','/SEC','/ZB','/BYTES','/XF Sync-UserProfile.log Thumbs.db ~$* ~*.tmp','/XD Der-europass-macht-Schule')
$serverlogfile          = $env:ProgramData + "\Microsoft\Windows\Start Menu\Programs\StartUp\serverlog.txt"
$serverlogheadercontent = Get-Content -Path $serverlogheader

#region functions
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
  Out-File -InputObject $output -FilePath $LogFile -Encoding utf8 -Append
}
#endregion functions

#region main

# starting script
Clear-Host

# create log folder
if (-not (Test-Path "$logfolder"))
{
  try
  {
    New-Item -Path "$logfolder" -ItemType Directory -Force
  }
  catch
  {
    Write-Host "ERROR: Unable to create Log and Temp Folder $logfolder"
    Pause
    exit 1
  }
  Write-Log "Log folder created" -level INFO
}

Write-Log -message "Starting script execution" -level INFO
Write-Log -message "Log files location is: $logfolder" -level INFO

# Create server log
if (-not (Test-Path "$serverlogfile" -PathType Leaf))
{
  Write-Log -message "Starting serverlog creation and setting file permission" -level INFO
  try
  {
    New-Item -Path "$serverlogfile" -ItemType File -Force 
    Out-File -InputObject $serverlogheadercontent -FilePath "$serverlogfile"
    Start-Process -FilePath "$env:windir\System32\icacls.exe" -ArgumentList "`"$serverlogfile`" /grant *S-1-5-32-545:M"
    Write-Log -message "Serverlog created" -level INFO
  }
  catch
  {
    Write-Log -message "Unable to create $serverlogfile" -level ERROR
  }
}else{
  Write-Log -message "'$serverlogfile' already exists. Setting permissions to User:M" -level INFO
  Start-Process -FilePath "$env:windir\System32\icacls.exe" -ArgumentList "`"$serverlogfile`" /grant *S-1-5-32-545:M"
}

if ($WindowsFeatures -eq $true)
{
  # remove unwanted/unsafe features
  Write-Log -message "Uninstall-WindowsFeature -name XPS-Viewer, PowerShell-v2, FS-SMB1-Client, FS-SMB1-Server, FS-SMB1 -LogPath `"$logfolder\Uninstall-WindowsFeature.log`"" -level INFO
  Uninstall-WindowsFeature -name XPS-Viewer, PowerShell-v2, FS-SMB1-Client, FS-SMB1-Server, FS-SMB1 -LogPath "$logfolder\Uninstall-WindowsFeature.log"

  # install needed features and restart server afterwards
  Write-Log -message "Install-WindowsFeature -name FS-Fileserver, FS-SyncShareService, FS-Ressource-Manager, DHCP, Print-Server, Web-Mgmt-Console, Web-Scripting-Tools, RSAT-DHCP, RSAT-FSRM-Mgmt, RSAT-Print-Services, RSAT-ADDS-Tools, RSAT-AD-PowerShell, GPMC, Remote-Assistance -LogPath `"$logfolder\Install-WindowsFeature.log`"" -level INFO
  Install-WindowsFeature -name FS-Fileserver, FS-SyncShareService, FS-Ressource-Manager, DHCP, Print-Server, Web-Mgmt-Console, Web-Scripting-Tools, RSAT-DHCP, RSAT-FSRM-Mgmt, RSAT-Print-Services, RSAT-ADDS-Tools, RSAT-AD-PowerShell, GPMC, Remote-Assistance -LogPath "$logfolder\Install-WindowsFeature.log"

  # reboot system
  Write-Log -message "Restarting server to disable/enable roles and features" -level INFO
  # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32shutdowntracker-method-in-class-win32-operatingsystem
  # Timeout, Comment, ReasonCode,  Flags (6 = Forced Reboot)
  # https://docs.microsoft.com/en-us/windows/win32/shutdown/system-shutdown-reason-codes
  # SHTDN_REASON_MAJOR_OPERATINGSYSTEM | SHTDN_REASON_MINOR_RECONFIG | SHTDN_REASON_FLAG_PLANNED
  # 0x00020000                         | 0x00000004                  | 0x80000000
  (Get-WmiObject -Class Win32_OperatingSystem).Win32Shutdowntracker(0, "Restart Server after (un)install of roles and features", 0x80020004, 6)
}

# copy folder structure with permissions
Write-Log -message "Starting copy process of '$oldserver' to '$newpath'" -level INFO
if (-not(Test-Path $newpath))
{
  Write-Log -message "New-Item -Path '$newpath' -ItemType Directory -Force" -level INFO
  try
  {
    New-Item -Path "$newpath" -ItemType Directory -Force
  }
  catch
  {
    Write-Log "Unable to create path" -level ERROR
    exit 1
  }
}

Write-Log -message "Each share has its own log file for copied directories and files" -level INFO
foreach ($share in $sharelist)
{
  # shared folder on on old server
  $old = '\\'+$oldserver +'\'+ $share

  # check if source is available, if not stop working on it
  if (-not(Test-Path -Path $old -PathType Container))
  {
    $message = "Unable to access '" + $old + "'"
    Write-Log $message -level ERROR
  }
  else
  {
    #get name for folder on local server
    $folder = Split-Path $(Get-CimInstance -ComputerName $oldserver -ClassName win32_share -Filter "Name = '$share'" | Select-Object -Property Path -ExpandProperty Path) -Leaf

    # new local folder with share name
    $new = $newpath + "\" + $folder

    # log file for each share
    $rLogFile = $logfolder + "\" + $folder + ".log"

    # add log file location to robocopy params
    $arguments = $roboparams + "/UNILOG+:$rLogFile"

    # new folder name is the same as old folder name
    $message = "Starting copy '" + $old + "' -> '" + $new + "'"
    Write-Log $message -level INFO
    Write-Log -message "Logfile is: $rLogFile" -level INFO
    Write-Log -message "Start-Process -Wait -FilePath `"$env:windir\System32\Robocopy.exe`" -ArgumentList `"$old $new $arguments`"" -level INFO
    Start-Process -NoNewWindow -Wait -FilePath "$env:windir\System32\Robocopy.exe" -ArgumentList "`"$old`" `"$new`" $arguments"
    $message = "Finished copy '" + $old + "' -> '" + $new + "'"
    Write-Log -message $message -level INFO 
  }
}

# print server migration

# tool is part of server role, so check if tool is available is necessary before run
$tool = "C:\windows\system32\spool\tools\PrintBrm.exe"
if (-not (Test-Path -Path $tool -PathType Leaf)){
    Write-Log -message "PrintBrm.exe not found. No print server migration" -level WARN
}else{
    $printshare = '\\'+$oldserver+'\print$'
    if (-not (Test-Path -Path $printshare -PathType Container)){
        Write-Log "`$print share on old server not reachable" -level ERROR
    }else{
        $cpath = Get-Location
        Set-Location -Path $(Split-Path -Path $tool -Parent)
        $printbrmbackup = $logfolder+'\'+$oldserver+".printerExport"
        Write-Log -message "Starting print server migration" -level INFO
        if (Test-Path -Path $printbrmbackup -PathType Leaf){
            Write-Log -message "Removing existing"
            Remove-item -Path $printbrmbackup -Force
        }
        $export = & .\$(Split-Path -Path $tool -Leaf) -S "$oldserver" -B -F "$printbrmbackup" -O FORCE
        $exportfile = $logfolder+'\printbrm-export.log'
        Out-File -FilePath $exportfile -InputObject $export -Encoding utf8
        $import = & .\$(Split-Path -Path $tool -Leaf) -R -F "$printbrmbackup" -O FORCE
        $importfile = $logfolder+'\printbrm-import.log'
        Out-File -FilePath $importfile -InputObject $import -Encoding utf8
        Set-Location $cpath.path
    }
}

# dhcp migration
$dhcpbackup = $logfolder+'\'+$oldserver+"_DHCP.xml"
Write-Log -message "Starting migrating DHCP configuration" -level INFO
try{
  Export-DhcpServer -ComputerName $oldserver -File $dhcpbackup -Force
  try{
    Import-DhcpServer -File $dhcpbackup -BackupPath $env:TEMP
  }
  catch
  {
    Write-Log -message "Import of DHCP configuration failed"
  }
}
catch
{
  Write-Log -message "Export of DHCP configuration failed"
}
Write-Log -message "End migrating DHCP configuration" -level INFO


#region certificate
if ($Certificate -eq $true){

  # generate INF for request with specified variables
  Write-Log -message "Generating certificate request" -level INFO
  $INFFile = $logfolder+'\'+$FQDN+'_'+$((Get-Date).ToString('yyyyMMdd'))+'.INF'
  $REQFile = $logfolder+'\'+$FQDN+'_'+$((Get-Date).ToString('yyyyMMdd'))+'_CSR.REQ'
  
  $Signature = '$Windows NT$'
  $SANListe = @("dns=$CertName")

  $INF = @"
  [Version]
  Signature= "$Signature" 
   
  [NewRequest]
  Exportable = TRUE                                                      ; TRUE = Private key is exportable
  KeyLength = 4096                                                       ; Valid key sizes: 1024, 2048, 4096, 8192, 16384
  KeySpec = 1                                                            ; Key Exchange – Required for encryption
  MachineKeySet = TRUE                                                   ; The default is false.
  PrivateKeyArchive = FALSE                                              ; The PrivateKeyArchive setting works only if the corresponding RequestType is set to "CMC"
  ProviderName = "Microsoft Enhanced RSA and AES Cryptographic Provider"
  ProviderType = 24                                                      ; PROV_RSA_AES
  RequestType = PKCS10                                                   ; Determines the standard that is used to generate and send the certificate request (PKCS10 -- 1)
  SMIME = False                                                          ; Refer to symmetric encryption algorithms that may be used by Secure Multipurpose Internet Mail Extensions (S/MIME)
  Subject = "E=$Mail, CN=$FQDN, OU=$OrganizationalUnit, O=$Organization, L=$City, S=$State, C=$Country"
  UseExistingKeySet = FALSE
  UserProtected = FALSE
   
  [Extensions]
  ; If your client operating system is Windows Server 2008, Windows Server 2008 R2, Windows Vista, or Windows 7
  ; SANs can be included in the Extensions section by using the following text format. Note 2.5.29.17 is the OID for a SAN extension.
  ; Multiple alternative names must be separated by an ampersand (&).
  2.5.29.17 = "{text}"
"@
  $SANListe | ForEach-Object { $INF += "_continue_ = `"$($_)&`"`r`n" }
  $INF += "`r`n; EOF`r`n"

  $INF | Out-File -FilePath $INFFile -Force
  & certreq.exe -New $INFFile $REQFile

  Write-Log -message "Certificate Request has been generated" -level INFO
}

#endregion

Write-Log -message "End script execution" -level INFO
#endregion main
