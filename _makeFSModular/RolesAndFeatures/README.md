# RolesAndFeatures
Disables and enables server roles and features depending on config files.
After disabling / enabling roles and features the server will reboot.

## Example
```powershell
PS> Import-Module Make-FS
PS> Remove-WindowsRaF -config "<Path to config file with features to be removed>"
```
```powershell
PS> Import-Module Make-FS
PS> Install-WindowsRaF -config "<Path to config file with features to be activated>"
```