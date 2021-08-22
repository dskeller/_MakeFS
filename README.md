# _MakeFS
create standard file server with needed roles and features and default shares

## Infos
This script was created during mass server migration from 2012R2 to 2019

- If specified, the server log is created
- If specified, the script disables SMBv1 and XPS-Viewer and enables file service, work folder, DHCP and print service with the corresponding RSAT-Mgmt-Tools and in addition some RSAT-Mgmt-Tools for Active Directory.
- If specified, all specified shares are copied to the new server to data drive.
- If specified, print service is migrated
- If specified, dhcp service is migrated
- If specified, ssl certificate request for IIS (work folder) is created

To run the script log on to the new server and run script as admin. 

It is possible to re-run parts of the script to pre migrate services and files before actual migration day.

## Example
Server migration of FS-01 to FS-02<br>
Preparation:
```powershell
.\Make_FS.ps1 -serverlog
```
This creates the logfile for the script in the default location and the serverlog for manual changes to the server later on.<br><br>
```powershell
.\Make_FS.ps1 -UninstallWindowsFeatures
```
This removes SMBv1, Powershellv2 and XPS-Viewer and reboots server.<br><br>
```powershell
.\Make_FS.ps1 -InstallWindowsFeatures
```
This enables Fileserver, SyncShareService, Ressource-Manager, DHCP, Print-Server, Web-Mgmt-Console, RSAT Tools for Active Directory and Remote-Assistance and reboots server.
<br><br><br>
Migration of file shares
```powershell
.\_MakeFS.ps1 -FileService -oldserver "FS-01"
```
This migrates default shares on FS-01 to local system.<br><br><br>
File service migration of FS-01 to local system with specified folders
```powershell
.\_MakeFS.ps1 -FileService -oldserver "FS-01" -$sharelist GroupShare,usershome$,Share1
```
