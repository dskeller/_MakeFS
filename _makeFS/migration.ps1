<#
    migration.ps1

    example for using _makefs.ps1 to copy nested shares on remote host
    This example assumes that both scripts are in the same directory
    
#>

#change to current directory with migration.ps1 and _makeFS.ps1
Set-Location "$PSScriptRoot"

# list remote shares from <OLDSERVER>
$session = New-CimSession -Authentication Kerberos -ComputerName <OLDSERVER> -SkipTestConnection
Get-SmbShare -CimSession $session

Name          ScopeName Path                          Description
----          --------- ----                          -----------
ADMIN$        *         C:\WINDOWS                    Remoteverwaltung
C$            *         C:\                           Standardfreigabe
D$            *         D:\                           Standardfreigabe
Ablage        *         D:\Ablage                     Ablage
Verwaltung    *         D:\Ablage\Verwaltung          Verwaltungsablage
Einkauf       *         D:\Ablage\Einkauf             Einkaufsablage
IT-Stelle$    *         D:\Ablage\IT-Stelle           IT-Stelle
Software$     *         D:\Ablage\IT-Stelle\Software  SW-Install
UserProfile$  *         D:\UserProfile                Benutzerprofile
IPC$          *                                       Remote-IPC


# Copy folders from <OLDSERVER> (first time and create shares)
.\_makeFS.ps1 -oldserver <OLDSERVER> -FileService -sharelist Ablage,usersprofile$ -newpath E:\fileserv -createshare
.\_makeFS.ps1 -oldserver <OLDSERVER> -FileService -sharelist Verwaltung -newpath E:\fileserv\Ablage -createshare
.\_makeFS.ps1 -oldserver <OLDSERVER> -FileService -sharelist Einkauf -newpath E:\fileserv\Ablage -createshare
.\_makeFS.ps1 -oldserver <OLDSERVER> -FileService -sharelist IT-Stelle$ -newpath E:\fileserv\Ablage -createshare
.\_makeFS.ps1 -oldserver <OLDSERVER> -FileService -sharelist Software$ -newpath E:\fileserv\Ablage\IT-Stelle -createshare

# Copy folders from <OLDSERVER> again, as the other shares are all sub directories of 'Ablage' no additional copy is needed
.\_makeFS.ps1 -oldserver <OLDSERVER> -FileService -sharelist Ablage,usersprofile$ -newpath E:\fileserv
