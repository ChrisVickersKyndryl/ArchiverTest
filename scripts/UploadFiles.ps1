<#
  .SYNOPSIS
  Designed to maintain the archieved windows event logs on the shared location.

  .DESCRIPTION
  Script maps a remote drive using credentials from registry keys. Copies all evtx files (event files)
  from a local server and copies to a remote location. The script is designed to be run as a scheduled task.  
 
  .PARAMETER ShareLocation
  Specifies the remote shared location to store the logging files.

  .INPUTS
  None. You can't pipe objects to RemoveFiles.ps1.

  .OUTPUTS
  Summary.log a detailed log of the files that have been removed for this run.  

  .EXAMPLE
  PS> .\UploadFiles.ps1

  Created by: Christopher.Vickers@kyndryl.com
    Last Updated: 19/10/2023
#>

param(
    $ShareLocation = ""
)

# Set variables
$global:shareLocation = $ShareLocation
$global:jobLog = "C:\Kyndryl\EventArchiver.log"                 # Individual job log 
$global:drvName = "KyndrylLoggerDrive"                          # Drive name                                                                              
$global:registryLoc = 'HKLM:\SOFTWARE\Kyndryl'                  # Registry location
$global:logLocation = "C:\WINDOWS\system32\config\"             # Location of log evtx log files to copy

# Output data to log file
function Set-Log{
    param (
        [String]$Content = ''
    )
    # Output to screen and to file
    Add-Content -Value "$(Get-Date -format "yyyyMMdd_HHmmss") $Content" -Path $($global:jobLog)
}

# Pre check registry values exist and script is running as administrator
function Get-PreChecks {

    # Check encrypted password registry exists
    if(-Not $(Get-ItemPropertyValue -Path $($global:registryLoc) -Name "Password")) {
        Set-Log -Content "No registry at $($global:registryLoc) with Key `"Password`""
        Exit 2
    }

    # Check encrypted password registry exists
    if(-Not $(Get-ItemPropertyValue -Path $($global:registryLoc) -Name "User")) {
        Set-Log -Content "No registry at $($global:registryLoc) with Key `"User`""
        Exit 2
    }

    # Check that running as administrator. If yes, return and continue code
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { return }

    # Not running as administrator. End program
    Set-Log -Content "Not running as administrator"
    Exit
}

# Get parameters to map drive. Adds custom credentials if not run as scheduled task
function Get-CredentialsFromRegistry {
    # Get values from registry
    $userName = Get-ItemPropertyValue -Path $($global:registryLoc) -Name "User"
    $password = Get-ItemPropertyValue -Path $($global:registryLoc) -Name "Password" | ConvertTo-SecureString

    return New-Object System.Management.Automation.PSCredential ($userName, $password)
}

# Map drive (if not already mapped)
function Set-Drive {
    # #Check if drive is already mapped. If yes, use it
    if($(Get-PSDrive | Where-Object { $_.Name -eq $($global:drvName) -and $_.Root -eq $($global:shareLocation)}).Count -ne 0){
        Set-Log -Content '- Drive already mapped. Using existing drive'
        return
    }

    # If drive not being used add drive and add to output file
    $val = $(Get-PSDrive | Where-Object { $_.Name -eq $($global:drvName) }).Count
    if( $val -eq 0 ) {
        Set-Log -Content "Mapping drive `"$($global:drvName)`" to share `"$($global:shareLocation)`""

        # Map drive. Parameters are taken from the logged in user if scheduled task
        New-PSDrive -Name $($global:drvName) -Root $($global:shareLocation) -PSProvider "FileSystem" -Scope "Script" -Credential $(Get-CredentialsFromRegistry) | Out-Null
        return
    }

    # If a drive already exists with the same name but a different address, end program and log error
    Set-Log -Content "- Error running script. A drive called $($global:drvName) already exists. Program ended."
    Exit 10
}

# Delete all files in each folder
function Copy-ArchiveFiles {

    # Check if folder exists. If it doesn't create it
    if (-Not $(Test-Path -Path "$($global:drvName):\$($env:computername)")) {
        New-Item -ItemType Directory -Path "$($global:drvName):\$($env:computername)"
    }

    # Get all evtx files in folder and copy over to remote location
    # Set the date, to prevent conflcits with naming
    $date = $(Get-Date -format "yyyyMMdd_HHmmss")
    Get-ChildItem -Path $global:logLocation -File -Filter "*.evtx" | ForEach-Object {
        # set the name of the file
        $newName = "$($date)_$($_.Name)"

        # Copy file to new location
        Set-Log -Content "Copying from `"$($_.FullName)`" to `"$($global:drvName):\$($env:computername)\$($newName)`""
        Copy-Item -Path $_.FullName -Destination "$($global:drvName):\$($env:computername)\$($newName)"

        # Check new file exists. If not, go to next file (do not delete the old file)
        if (-Not $(Test-Path -Path "$($global:drvName):\$($env:computername)\$($newName)")) {
            Set-Log -Content "ERROR: File `"$($global:drvName):\$($env:computername)\$($newName)`" was not created."
            return
        }

        # Try to delete original file
        Remove-Item -Path $_.FullName -Confirm:$false

        # Check if the old file was removed
        if (Test-Path -Path $_.FullName) {
            Set-Log -Content "ERROR: File `"$($_.FullName)`" could not be deleted."
        }
        else {
            Set-Log -Content "File `"$($_.FullName)`" was removed from host"
        }
    }
}

try{
    # Pre checks to identify issues
    Get-PreChecks

    # Map the network drive
    Set-Drive

    # Move archive files
    Copy-ArchiveFiles

    # Set final summary
    Set-Log -Content "Program ran successfully"
}
# Catch any errors and output to the log file
catch {
    Set-Log -Content  "ERROR $_"
}

Exit 0
