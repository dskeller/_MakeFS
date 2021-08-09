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
$folderlist = @("share1","share2","groupshare","usershome","usersprofile")

#ab hier finger weg
# #fingerab
$newpath = "C:\fileserv"
$logfolder = "C:\logs"
$roboparams = @('/COPYALL','/MIR','/MT:128','/COPY:DATSOU','/DCOPY:DAT','/DST','/R:1','/W:2','/NC','/NP','/J','/SEC','/B')

# create log folder
if (-not Test-Path "$logfolder"){
  new-item -Path "$logfolder" -ItemType Directory -Force
}

# remove unwanted/unsafe features
Uninstall-WindowsFeature -name XPS-Viewer,PowerShell-v2,FS-SMB1-Client,FS-SMB1-Server,FS-SMB1 -LogPath $logfolder\Uninstall-WindowsFeature.log

# install needed features and restart server afterwards
Install-WindowsFeature -name FS-Fileserver,FS-SyncShareService,FS-Ressource-Manager,DHCP,Print-Server,Web-Mgmt-Console,Web-Scripting-Tools,RSAT-DHCP,RSAT-FSRM-Mgmt,RSAT-Print-Services,RSAT-ADDS-Tools,RSAT-AD-PowerShell,GPMC,Remote-Assistance -LogPath $logfolder\Install-WindowsFeature.log -Restart

#folderstructure with permissions
if (-not(Test-Path $newpath) ){
  new-item -Path "$newpath" -ItemType Directory -Force
}

foreach ($folder in $folderlist){
    $old = $oldpath+"\"+$folder
    $new = $newpath+"\"+$folder
    $LogFile = $logfolder+"\"+$folder+".log"
    $date = get-date -Format "yyyy-MM-dd HH:mm:ss"
    $message = $date +" INFO: Starting copy "+$old+" -> "+$new
    Write-Host $message
    $arguments = $roboparams + "/UNILOG+:$LogFile"
    Write-Host $arguments
    Start-Process -Wait -FilePath "$env:windir\System32\Robocopy.exe" -ArgumentList "$old $new $arguments"
    $date = get-date -Format "yyyy-MM-dd HH:mm:ss"
    $message = $date+" INFO: Finished copy "+$old+" -> "+$new
    Write-Host $message
}
