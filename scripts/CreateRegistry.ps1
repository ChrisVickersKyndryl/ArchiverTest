<#
  .SYNOPSIS
  Create a user credital registry key for windows event log archiving.

  .DESCRIPTION
  The CreateRegistry.ps1 script creates a registry key on the windows server called Kyndryl, 
  and adds two values USER and PASSWORD.  

  .PARAMETER User
  Specifies the user that will be used to upload the windows event logs to the archive location.

  .PARAMETER PlainTxtPass
  Specifies the password string that will be encrypted and stored in the registry for future use.

  .INPUTS
  None. You can't pipe objects to CreateRegistry.ps1.

  .OUTPUTS
  None. CreateRegistry.ps1 doesn't generate any output.

  .EXAMPLE
  PS> .\CreateRegistry.ps1 -User "user id" -Password "password"

#>

param(
    $User = "User",
    $PlainTxtPass = "Password"
)

# Check if registry Key exists. If not, add the Key
if (-Not $(Test-Path -Path 'HKLM:\SOFTWARE\Kyndryl')) {
    New-Item -Path 'HKLM:\SOFTWARE\' -Name "Kyndryl" | Out-Null
}

# Write user to registry value USER
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "User" -Value $User | Out-Null

# Convert password plain text to secure string.
$securePassword = ConvertTo-SecureString $PlainTxtPass -AsPlainText -Force

# Convert secure string to plain text
$securePassword = $securePassword | ConvertFrom-SecureString

# Write password to registry value PASSWORD
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "Password" -Value $securePassword | Out-Null