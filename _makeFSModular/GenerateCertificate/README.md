# GenerateCertificate
Creates certificate request for PKI. Needed for WorkFolder

```powershell
PS> Import-Module Make-FS
PS> New-CertificateRequest -config "<Path to config>" -OutDir "<directory to save request file>"
```