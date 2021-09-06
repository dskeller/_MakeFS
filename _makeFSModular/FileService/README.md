# PrintService
Checks if roles and features are installed and migrates files, shares etc. from old server.

## Examples
```powershell
PS> Import-Module Make-FS
PS> Move-FileService -OldServer "<Old server name>"
```
Migrate files and re-create shares on system.
<br><br>
```powershell
PS> Import-Module Make-FS
PS> Move-FileService -OldServer "<Old server name>" -DataOnly
```
Migrates files only.