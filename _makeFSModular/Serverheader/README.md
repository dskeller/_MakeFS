# ServerHeader
Create log file in all user startup directory to protocol changes made to server. Header for initialization is 'serverlog-header.txt'.

## Example
```powershell
PS> Import-Module Make-FS
PS> Initialize-ServerHeader -header "<Path to header file>"
```
