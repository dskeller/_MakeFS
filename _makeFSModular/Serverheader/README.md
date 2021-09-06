# Serverheader
Create log file in all user startup directory to protocol changes made to server. Header for initialization is 'serverlog-header.txt'.

## Example
```powershell
PS> Import-Module Make-FS
PS> Initialize-Serverheader -header "<Path to header file>"
```
