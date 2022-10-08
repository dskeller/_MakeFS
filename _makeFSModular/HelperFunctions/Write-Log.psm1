<#
  Write-Log.psm1 (c) 2022 dskeller
#>

#region HelpFunction
function Write-Log {
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
  if ($level -eq 'INFO') {
    [System.ConsoleColor]$color = 'Green'
  }
  elseif ($level -eq 'WARN') {
    [System.ConsoleColor]$color = 'Yellow'
  }
  elseif ($level -eq 'ERROR') {
    [System.ConsoleColor]$color = 'Red'
  }
  else {
    [System.ConsoleColor]$color = 'White'
  }
  $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $output = $date + " " + $level + " : " + $message
  Write-Host -Object $output -ForegroundColor $color
  Out-File -InputObject $output -FilePath $LogFile -Encoding utf8 -Append
}
#endregion HelpFunction