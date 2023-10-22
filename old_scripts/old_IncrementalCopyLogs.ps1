# Set-Item -Path HKCU:\Software\hsg -Value “hsg key”
# Ignore. Used in creation of settings.
New-Item -Path "HKLM:\SOFTWARE\" -Name "Kyndryl"
New-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "Password" -Value "PASSWORD"  -PropertyType "String"
New-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "LastIndex" -Value "0"  -PropertyType "String"
New-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "LastIndex" -Value "0"  -PropertyType "String"
New-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "LastIndex" -Value "0"  -PropertyType "String"

# Variablesa
$global:logType = @('System')
$global:registryLoc = 'HKLM:\SOFTWARE\Kyndryl'
$global:logLocation =  "C:\Kyndryl\Log.txt" # Temp location. Needs to be changed.

# Pre check registry values exist
function Get-PreChecks {
    # Go through each key and check it exists. Used as multiple log types to save
    foreach ($type in $logType) {
        # Check registry exists with the last one used
        if(-Not $(Get-ItemPropertyValue -Path $global:registryLoc -Name $type)) {
            Write-Host "No registry at $($global:registryLoc) with Key $type"
            Exit
        }
    }

    # Check encrypted password registry exists
    if(-Not $(Get-ItemPropertyValue -Path $global:registryLoc -Name $type)) {
        Write-Host "No registry at $($global:registryLoc) with Key EncryptedPassword"
        Exit
    }

    # Check that running as administrator. If yes, return to continue code
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { return }

    # Not running as administrator. End program
    Write-Host "Not running as administrator"
    Exit
}

# Create remote drive
function Set-RemoteDrive {

}

# Get formatted log
function Get-FormattedLog () {
    
}

function Copy-LogsToCentralLocation {
    # Go through each log type and copy over
    foreach ($type in $logType) {
        # Get value from registry
        $lastUpload = Get-ItemPropertyValue -Path $global:registryLoc -Name $type
        #Get-EventLog -LogName System | Where-Object { $_.TimeWritten -gt  (Get-Date).AddDays(-1) } | ForEach-Object {

        # Save last upload date to reg
        Get-EventLog -LogName @type | Where-Object { [convert]::ToInt32($_.Index) -gt [convert]::ToInt32($lastUpload)  } | ForEach-Object {
            $_.Index
    
            $allstring += "`n===================================="
            $allstring += "`n$($_.Index) $($_.Message)" $_.   
    
            # Set last item
            $global:lastItem = $_.Index
        }

        # Temp to see value. This will become the
        Add-Content $global:logLocation -Value $allString
        
        # Set value in registry of 
        Set-Itemproperty -path $global:registryLoc -Name $type -value $global:lastItem
    }
}

Get-PreChecks

Set-RemoteDrive

Copy-LogsToCentralLocation
