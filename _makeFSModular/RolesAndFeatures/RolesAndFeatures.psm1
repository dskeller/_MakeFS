<#
  RolesAndFeatures.psm1 (c) 2021 dskeller
#>

#region HelpFunction
function Write-Log
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    $message,
    [Parameter(Mandatory = $false)]
    [ValidateSet('INFO', 'WARN', 'ERROR')]
    [string]$level = 'HINT',
    [Parameter(Mandatory = $false)]
    [string]$LogFile
  )
  if ($level -eq 'INFO')
  {
    [System.ConsoleColor]$color = 'Green'
  }
  elseif ($level -eq 'WARN')
  {
    [System.ConsoleColor]$color = 'Yellow'
  }
  elseif ($level -eq 'ERROR')
  {
    [System.ConsoleColor]$color = 'Red'
  }
  else
  {
    [System.ConsoleColor]$color = 'White'
  }
  $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $output = $date + " " + $level + " : " + $message
  Write-Host -Object $output -ForegroundColor $color
  Out-File -InputObject $output -FilePath $LogFile -Encoding utf8 -Append
}
#endregion HelpFunction

#region MainFunctions
#region Enable-RolesAndFeatures
function Enable-RolesAndFeatures
{
  [CmdletBinding()]
  param (
    # Configuration file
    [Parameter(Mandatory=$true)]
    [ValidateScript({
      if (-not(Test-Path -Path "$_" -PathType Leaf))
      {
        throw "File not found. Please check file and permissions."
      }
      return $true
    })]
    [System.IO.FileInfo]$configFile,
    [Parameter(Mandatory=$false)]
    [System.IO.FileInfo]$logFolder="C:\logs"
  )
    
  begin
  {
    $LogFile = $logfolder.FullName.TrimEnd('\') + "\" + $MyInvocation.MyCommand.Name + ".log"

    # create log folder
    if (-not (Test-Path "$logFolder"))
    {
      try
      {
        New-Item -Path "$logFolder" -ItemType Directory -Force
      }
      catch
      {
        Write-Host "ERROR: Unable to create log folder '$logFolder'"
        exit 1
      }
      Write-Log "Log folder created" -logFile "$LogFile" -level INFO
    }      
  }
    
  process
  {
    Write-Log -message "Starting function execution" -LogFile "$LogFile" -level INFO
    Write-Log -message "Log file location is: $LogFile" -LogFile "$LogFile" -level INFO

    [xml]$config = Get-Content -Path "$configFile"
    if ($($config.config.raf.Count) -eq 0)
    {
      Write-Log -message "NO roles and features to be enabled!" -LogFile "$LogFile" -level WARN
    }
    else
    {
      [string]$raf = ""
      foreach ($rf in $config.config.raf)
      {
        $raf = $rf+", "+$raf
      }
      $raf = $raf.TrimEnd(', ')
      Write-Log -message "Install-WindowsFeature -name $raf -LogPath `"$logfolder\Install-WindowsFeature.log`"" -level INFO
      Install-WindowsFeature -name $raf -LogPath "$LogFile"
      #
      # TODO: HANDLING
      #

      Write-Log -message "Restarting server to enable roles and features" -level INFO
      # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32shutdowntracker-method-in-class-win32-operatingsystem
      # Timeout, Comment, ReasonCode,  Flags (6 = Forced Reboot)
      # https://docs.microsoft.com/en-us/windows/win32/shutdown/system-shutdown-reason-codes
      # SHTDN_REASON_MAJOR_OPERATINGSYSTEM | SHTDN_REASON_MINOR_RECONFIG | SHTDN_REASON_FLAG_PLANNED
      # 0x00020000                         | 0x00000004                  | 0x80000000
      # adding clean-ui (https://devblogs.microsoft.com/oldnewthing/20100831-00/?p=12993) 0x04000000
      # -> 0x80020004
      # -> [uint32]"0x84020004"
      $rargs = @{
        Timeout    = [System.UInt32]0
        Comment    = 'Install Windows roles and features'
        ReasonCode = [System.UInt32]2214723588
        Flags      = 6
      }
      Invoke-CimMethod -Query 'SELECT * FROM Win32_OperatingSystem' -MethodName 'Win32ShutdownTracker' -Arguments $rargs
    }
  }
    
  end
  {
    Write-Log -message "Stopping function execution" -LogFile "$LogFile" -level INFO
  }
}
#endregion Enable-RolesAndFeatures

#region Disable-RolesAndFeatures
function Disable-RolesAndFeatures
{
  [CmdletBinding()]
  param (
    # Configuration file
    [Parameter(Mandatory=$true)]
    [ValidateScript({
      if (-not(Test-Path -Path "$_" -PathType Leaf))
      {
        throw "File not found. Please check file and permissions."
      }
      return $true
    })]
    [System.IO.FileInfo]$configFile,
    [Parameter(Mandatory=$false)]
    [System.IO.FileInfo]$logFolder="C:\logs"
  )
    
  begin
  {
    $LogFile = $logfolder.FullName.TrimEnd('\') + "\" + $MyInvocation.MyCommand.Name + ".log"

    # create log folder
    if (-not (Test-Path "$logFolder"))
    {
      try
      {
        New-Item -Path "$logFolder" -ItemType Directory -Force
      }
      catch
      {
        Write-Host "ERROR: Unable to create log folder '$logFolder'"
        exit 1
      }
      Write-Log "Log folder created" -logFile "$LogFile" -level INFO
    }
  }
    
  process
  {
    Write-Log -message "Starting function execution" -LogFile "$LogFile" -level INFO
    Write-Log -message "Log file location is: $LogFile" -LogFile "$LogFile" -level INFO

    [xml]$config = Get-Content -Path "$configFile"
    if ($($config.config.raf.Count) -eq 0)
    {
      Write-Log -message "NO roles and features to be disabled!" -LogFile "$LogFile" -level WARN
    }
    else
    {
      [string]$raf = ""
      foreach ($rf in $config.config.raf)
      {
        $raf = $rf+", "+$raf
      }
      $raf = $raf.TrimEnd(', ')
      Write-Log -message "Uninstall-WindowsFeature -name $raf -LogPath `"$logfile`"" -level INFO
      Uninstall-WindowsFeature -name $raf -LogPath "$logfile"
      #
      # TODO: HANDLING
      #

      Write-Log -message "Restarting server to disable roles and features" -level INFO
      # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32shutdowntracker-method-in-class-win32-operatingsystem
      # Timeout, Comment, ReasonCode,  Flags (6 = Forced Reboot)
      # https://docs.microsoft.com/en-us/windows/win32/shutdown/system-shutdown-reason-codes
      # SHTDN_REASON_MAJOR_OPERATINGSYSTEM | SHTDN_REASON_MINOR_RECONFIG | SHTDN_REASON_FLAG_PLANNED
      # 0x00020000                         | 0x00000004                  | 0x80000000
      # adding clean-ui (https://devblogs.microsoft.com/oldnewthing/20100831-00/?p=12993) 0x04000000
      # -> 0x80020004
      # -> [uint32]"0x84020004"
      $rargs = @{
        Timeout    = [System.UInt32]0
        Comment    = 'Uninstall Windows roles and features'
        ReasonCode = [System.UInt32]2214723588
        Flags      = 6
      }
      Invoke-CimMethod -Query 'SELECT * FROM Win32_OperatingSystem' -MethodName 'Win32ShutdownTracker' -Arguments $rargs
    }
  }
    
  end
  {
    Write-Log -message "Stopping function execution" -LogFile "$LogFile" -level INFO
  }
}
#endregion Disable-RolesAndFeatures
#endregion