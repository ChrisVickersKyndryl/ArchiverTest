<#
  .SYNOPSIS
  Designed to maintain the archieved windows event logs on the shared location.

  .DESCRIPTION
  Script is designed to be run manually or as a scheduled task. If the script is run as a scheduled task, the script decrypts
  an encrypted files, containing a password to the logging shared folder.  
 
  .INPUTS
  None. You can't pipe objects to RemoveFiles.ps1.

  .OUTPUTS
  Summary.log a detailed log of the files that have been removed for this run.  

  .EXAMPLE
  PS> .\RemoveFiles.ps1

  Created by: Christopher.Vickers@kyndryl.com
    Last Updated: 19/10/2023
#>

param (
    # Set variables
    $global:jobSummary = "C:\Kyndryl\Summary.log",                                              # Summary log
    $global:jobLog = "C:\Kyndryl\RemoveFilesLog_$(Get-Date -format "yyyyMMdd_HHmmss").log",     # Individual job log  
    $global:drvName = "KyndrylLoggerDrive",                                                     # Drive name
    $global:maxAge = 180,                                            				            # Max age of files
    $global:envDir = ''
)


# Output data to log file and to console
function Set-Output{
    param (
        [String]$Content = '',
        [string]$Indent = 0
    )

    # Add indent based on "Indent" parameter
    $tabs = ''
    For ($i=0; $i -le $Indent; $i++) {
        $tabs += "`t"
    }
    # Output to screen and to file
    Write-Host "$tabs $Content"
    Add-Content -Path $global:jobLog -Value "$(Get-Date -format "yyyy-MM-dd_HHmmss")$tabs$Content"
}

# Save information to summary log. Used for checking it is running correctly.
function Set-SummaryLog{
    param (
        [String]$Content = ""
    )
    # Check if the log file exist and create the file if it doesnt
    Add-Content -Path $global:jobSummary -Value "$(Get-Date -format "yyyy-MM-dd_HHmmss") $Content"
}

# Check if scheduled task
function Get-IsScheduledTask {
    # Check if run as a scheduled task
    if('svchost' -eq (Get-Process -Id (Get-CimInstance Win32_Process -Filter "ProcessID = $pid").ParentProcessId).Name){ return $true }
    
    # Return false if not run at a scheduled task
    return $false
}

# Get parameters to map drive. Adds custom credentials if not run as scheduled task
function Get-MapDriveParameters {

    # Parameters that the map drive will run as
    $param = @{
        "Name" =        $global:drvName
        "Root" =        $global:shareLocation[$global:envDir]
        "PSProvider" =  "FileSystem"
        "Scope" =       "Script"
    }

    # If not run as scheduled task, prompt for username
    if(-Not $(Get-IsScheduledTask)){
        Set-Output -Content '- Script run manually. Username requested via prompt'
        $cred = Get-Credential
        Set-Output -Content '- Credentials Entered'
        $param.Add("Credential", $cred)
    }

    return $param
}

# Map drive (if not already mapped)
function Set-Drive {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DestinationLoc
    )

    # #Check if drive is already mapped. If yes, use it
    if($(Get-PSDrive | Where-Object { $_.Name -eq $($global:drvName) -and $_.Root -eq $DestinationLoc}).Count -ne 0){
        Set-Output -Content '- Drive already mapped. Using existing drive'
        return
    }
  
    # If drive not being used add drive and add to output file
    $val = $(Get-PSDrive | Where-Object { $_.Name -eq $($global:drvName) }).Count
    if( $val -eq 0 ) {
        Set-Output -Content "- Mapping drive `"$($global:drvName)`" to share `"$DestinationLoc`""
        # Map drive. Parameters are taken from the logged in user if scheduled task
        $param = Get-MapDriveParameters
        New-PSDrive @param | Out-Null
        return
    }

    # If a drive already exists with the same name but a different address, end program and log error
    Set-Output -Content "- ERROR running script. A drive called $($global.$drvName) already exists. Program ended."
    Set-SummaryLog -Content "ERROR running script. A drive called $($global.$drvName) already exists. Program ended."
    Exit
}

# Delete all files in each folder
function Remove-Files {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Envir_Dir
    )
        
    # Add header to the log file
    Set-Output -Content "- Deleting logs in `"$Envir_Dir`" that are older that $($global:maxAge) days"

    # Work out date 180 days ago to use in filter below
    $limit = (Get-Date).AddDays(-$global:maxAge)
   
    # Log number of files that meet criteria
    $numberOfFiles = $(Get-Childitem -path "$($global:drvName):\" -Recurse | Where-Object {
        # Filter by: are not a container (folder), that were created 180 days+ and end in the entension *.log 
        !$_.PSIsContainer -and $_.Name -Like "*.evtx" -and  $_.LastWriteTime -lt $limit
    }).Count
    Set-Output -Content "  $numberOfFiles file(s) found that match criteria to be deleted"

    # Get all items in folder
    Get-Childitem -path "$($global:drvName):\" -Recurse | Where-Object {
        # Filter by: are not a container (folder), that were created 180 days+ and end in the entension *.log 
        !$_.PSIsContainer -and $_.Name -Like "*.evtx" -and  $_.LastWriteTime -lt $limit
    } | ForEach-Object {
        # Remove file
        Remove-item -Path $_.FullName

        # Check to see if file was deleted and report result
        if (Test-Path $_.FullName) {
            Set-Output -Content "- Error deleting file. LastWriteDate: $($_.LastWriteTimeUtc). FileName: $($_.FullName)" -Indent 1
            Set-SummaryLog -Content "ERROR deleting file. LastWriteDate: $($_.LastWriteTimeUtc). FileName: $($_.FullName)"
        }
        else {
            Set-Output -Content "- File deleted. LastWriteDate: $($_.LastWriteTimeUtc). FileName: $($_.FullName)" -Indent 1
        }
    }
}

# Define the shared locations to check and remove files from
$shareLocation = @{
    dev = '\\tldbkpprod0201.melb.ad\wineventlogs_nonprod\Dev'
    test = '\\tldbkpprod0201.melb.ad\wineventlogs_nonprod\Test'
    prod = '\\tldbkpprod0201.melb.ad\wineventlogs_prod'
}                                                               

try{
    # Final report
    Set-Output -Content "- Program started. (All times are based on local server)"

    # Loop thur the environments and delete files older than xxx days
    foreach ($envDir in $shareLocation.keys) {               
    
        # Map the network drive
        Set-Drive -DestinationLoc $shareLocation[$envDir]

        # Delete old files
        Remove-Files -Envir_Dir $envDir
    }
    
     # Final report
    Set-Output -Content "- ============================ Program completed ============================"
    Set-SummaryLog -Content "Program ran successfully"
}
# Catch any errors and output to the log file
catch {
    Set-SummaryLog -Content "ERROR $_"
    Exit 2
}