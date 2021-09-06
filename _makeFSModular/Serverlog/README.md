# ServerHeader
Create log file in all user startup directory to protocol changes made to server. Header for initialization is 'serverlog-header.txt'.

## Examples
```powershell
PS> Import-Module MakeFS
PS> Initialize-ServerLog -initialHeaderFile "<Path to header file>"
```

```powershell
PS> Import-Module MakeFS
PS> Initialize-ServerLog -initialHeaderFile "<Path to header file>" -logFolder "<Path to log folder>"
```
