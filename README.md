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
Preparation (old server is needed also not used):
```powershell
.\Make_FS.ps1 -oldserver "FS-01" -Serverlog $true -WindowsFeatures $true
```
The server auto reboots after install of roles and features.<br><br><br>
The first migration only of file shares and print service
```powershell
.\_MakeFS.ps1 -oldserver "FS-01" -FileService $true -PrintService $true 
```
This migrates default shares on FS-01 to local system.<br><br><br>
File service migration of FS-01 to local system with specified folders
```powershell
.\_MakeFS.ps1 -oldserver "FS-01" -FileService $true -$sharelist GroupShare,usershome$,Share1
```