# DHCPService
Check if needed roles and features are enabled and migrate DHCP service and disables service on old server

## Examples
```powershell
PS> Import-Module Make-FS
PS> Move-DHCPService -OldServer "<old server name>"
```
Migrates data only<br><br>

```powershell
PS> Import-Module Make-FS
PS> Move-DHCPService -OldServer "<old server name>" -DisableOld
```
Migrates data and disables service on old server.
