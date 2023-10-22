$user = "User"
$password = "Password"

# Check if registry folder exists. If not, add it 
if (-Not $(Test-Path -Path 'HKLM:\SOFTWARE\Kyndryl')) {
    New-Item -Path 'HKLM:\SOFTWARE\' -Name "Kyndryl" | Out-Null
}

# Check if user exists
if(Test-Path -Path 'HKLM:\SOFTWARE\Kyndryl\User') { 
    # Registry exists. Change it
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "User" -Value $user | Out-Null
}
else {
    # Regitry doesn't exist. Create it
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "User" -Value $user | Out-Null
}

# Convert text to secure string
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Convert secure string to plain text
$securePassword = $securePassword | ConvertFrom-SecureString

# Check if password exists
if(Test-Path  -Path 'HKLM:\SOFTWARE\Kyndryl\Password') { 
    # Registry exists. Change it
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "Password" -Value $securePassword | Out-Null
}
else {
    # Regitry doesn't exist. Create it
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Kyndryl' -Name "Password" -Value $securePassword | Out-Null
}
