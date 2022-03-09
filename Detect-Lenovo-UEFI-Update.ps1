<#
.SYNOPSIS
  Detect Lenovo UEFI Update
.DESCRIPTION
  Detection Script for Lenovo UEFI Update for Endpoint Manager proactive remediations
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
  Detect-Lenovo-UEFI-Update.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

$logpath = "C:\ProgramData\Lenovo-UEFI-Update-Detect.csv"

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

#-----------------------------------------------------------[Execution]------------------------------------------------------------

try
{  
    Write-Log -Severity Information -Message "Starting Script"

    #install powershell module
    Install-Module

    #get critical UEFI updates
    Write-Log -Severity Information -Message "Getting updates"
    try {
        $updates = Get-LSUpdate | Where-Object { $_.Type -eq 'BIOS' -and $_.Severity -eq 'Critical' }
    }
    catch {
        if ( $_.Exception.Message -eq "Could not parse computer model number. This may not be a Lenovo computer, or an unsupported model." ) {
           Write-Log -Severity Information -Message "No Lenovo computer"
           exit 0 
        }
    }

    if ( $updates ) {
        Write-Log -Severity Information -Message "Found UEFI updates"
        exit 1
    }
    else {
        Write-Log -Severity Information -Message "No critical UEFI updates found"
        exit 0
    }
}

catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}