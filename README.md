# _MakeFS
create standard file server with needed roles and features and default shares

## Infos
This script was created during mass server migration from 2012R2 to 2019

The script disables SMBv1 and XPS-Viewer
The script enables file service, work folder, DHCP and print service with the corresponding RSAT-Mgmt-Tools and in addition some RSAT-Mgmt-Tools for Active Directory

All specified shares are copied to the new server to data drive.

To run the script log on to the new server and run script as admin. 

It is possible to re-run the script to copy files before actual migration day.

## Example
Server migration of FS-01 to FS-02
```powershell
.\_MakeFS.ps1 -$oldpath "\\FS-01\e$\fileserv"
```

Server migration of FS-01 to FS-02 with specified folders
```powershell
.\_MakeFS.ps1 -$oldpath "\\FS-01\e$\fileserv" -$folderlist GroupShare,usershome,Share1
```