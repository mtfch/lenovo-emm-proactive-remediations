<#
.SYNOPSIS
  Remediate Lenovo UEFI Update
.DESCRIPTION
  Remediate Script for Lenovo UEFI Update for Endpoint Manager proactive remediations
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Tobias Meier
  Creation Date:  24.02.2022
  Purpose/Change: Initial release
  
.EXAMPLE
  Remediate-Lenovo-UEFI-Update.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

$logpath = "C:\ProgramData\Lenovo-UEFI-Update-Remediate.csv"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
 
    [pscustomobject]@{
        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity
    } | Export-Csv -Path $logpath -Append -NoTypeInformation
 }

 function Install-Module {
     try {
        Write-Log -Severity Information -Message "Checking for Powershell module LSUClient"
        $module = Get-Module -Name 'LSUClient'
        if ( !$module ) {
            Write-Log -Severity Information -Message "Install for Powershell module LSUClient"
            Install-PackageProvider -Name NuGet -Force -ForceBootstrap -ErrorAction SilentlyContinue
            Sleep -Seconds 5
            Invoke-Expression 'cmd /c start powershell -Command { Install-Module -Name LSUClient -Force -Confirm:$false }'
        }
    }
    catch {
        $errMsg = "Installation of LSUClient failed"
        Write-Log -Severity Error -Message "Installation of LSUClient failed"
        Write-Error $errMsg
        exit 1
    }
 }

  function Invoke-Notification {
      param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )
    Add-Type -AssemblyName System.Windows.Forms 
    $global:balloon = New-Object System.Windows.Forms.NotifyIcon
    $path = (Get-Process -id $pid).Path
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
    $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $balloon.BalloonTipText = $Message
    $balloon.BalloonTipTitle = $Title
    $balloon.Visible = $true 
    $balloon.ShowBalloonTip(5000)
 }

#-----------------------------------------------------------[Execution]------------------------------------------------------------

try
{  

    Write-Log -Severity Information -Message "Starting Script"

    #install powershell module
    Install-Module

    #get critical UEFI updates
    Write-Log -Severity Information -Message "Getting updates"
    $updates = Get-LSUpdate | Where-Object { $_.Type -eq 'BIOS' -and $_.Severity -eq 'Critical' }

    Write-Log -Severity Information -Message "Downloading updates"
    $updates | Save-LSUpdate -Verbose

    Write-Log -Severity Information -Message "Installing updates"
    $updates | Install-LSUpdate -Verbose

    Invoke-Notification -Title 'PC Reboot Required' -Message 'Your computer needs to install an important UEFI update, please reboot. Note UEFI update installation needs 5 minutes to complete'

    exit 0
}
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
