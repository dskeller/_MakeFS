<#
  Initialize-Serverlog.psm1 (c) 2022 dskeller
#>

function Initialize-ServerLog {
  [CmdletBinding()]
  param (
    # File with default content of new header file
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-not(Test-Path -Path "$_" -PathType Leaf)) {
          throw "File not found. Please check file and permissions."
        }
        return $true
      })]
    [System.IO.FileInfo]$initialHeaderFile,
    [Parameter(Mandatory = $false)]
    [System.IO.FileInfo]$logFolder = "C:\logs"
  )

  begin {
    $LogFile = $logfolder.FullName.TrimEnd('\') + "\" + $MyInvocation.MyCommand.Name + ".log"
    $serverlogfile = $env:ProgramData + "\Microsoft\Windows\Start Menu\Programs\StartUp\serverlog.txt"

    # create log folder
    if (-not (Test-Path "$logFolder")) {
      try {
        New-Item -Path "$logFolder" -ItemType Directory -Force
      }
      catch {
        Write-Host "ERROR: Unable to create log folder '$logFolder'"
        exit 1
      }
      Write-Log "Log folder created" -logFile "$LogFile" -level INFO
    }
  }

  process {
    Write-Log -message "Starting function execution" -LogFile "$LogFile" -level INFO
    Write-Log -message "Log file location is: $LogFile" -LogFile "$LogFile" -level INFO

    # create server log in startup directory
    if (-not (Test-Path "$serverlogfile" -PathType Leaf)) {
      Write-Log -message "Starting serverlog creation and setting file permission" -logFile "$LogFile" -level INFO
      try {
        [void]$(New-Item -Path "$serverlogfile" -ItemType File -Force)
        Out-File -InputObject $initialHeaderFile -FilePath "$serverlogfile"
        Start-Process -FilePath "$env:windir\System32\icacls.exe" -ArgumentList "`"$serverlogfile`" /grant *S-1-5-32-545:M"
        Write-Log -message "Serverlog created" -logFile "$LogFile" -level INFO
      }
      catch {
        Write-Log -message "Unable to create $serverlogfile" -logFile "$LogFile" -level ERROR
      }
    }
    else {
      Write-Log -message "'$serverlogfile' already exists. Setting permissions to User:M" -logFile "$LogFile" -level INFO
      Start-Process -FilePath "$env:windir\System32\icacls.exe" -ArgumentList "`"$serverlogfile`" /grant *S-1-5-32-545:M"
    }
  }

  end {
    Write-Log -message "Stopping function execution" -LogFile "$LogFile" -level INFO
  }
}