<#
  _makefs.ps1
  
  create standardized file-server with
  - Fileservice
  - SyncShareService
  - Print-Service
  - DHCP
  - RSAT-Tools for roles and Active Directory
#>

# create log folder
if (-not Test-Path "C:\logs"){
  new-item -Path "C:\" -Name "logs" -ItemType Directory
}

# remove unwanted/unsafe features
Uninstall-WindowsFeature -name XPS-Viewer,PowerShell-v2,FS-SMB1-Client,FS-SMB1-Server,FS-SMB1 -LogPath C:\logs\Uninstall-WindowsFeature.log
# install needed features and restart server afterwards
Install-WindowsFeature -name FS-Fileserver,FS-SyncShareService,FS-Ressource-Manager,DHCP,Print-Server,Web-Mgmt-Console,Web-Scripting-Tools,RSAT-DHCP,RSAT-FSRM-Mgmt,RSAT-Print-Services,RSAT-ADDS-Tools,RSAT-AD-PowerShell,GPMC,Remote-Assistance -LogPath C:\logs\Install-WindowsFeature.log -Restart

