#-------------------------------------------------------------------------------------------------------------"
#   Create Encrypted File 
#
#  This powershell creates a encrypted password file to be used in a upload of windows event log archives. 
#         
#-------------------------------------------------------------------------------------------------------------"
param(
  $PassString,
  $SaveLocation
)

# Convert text to secure string
$securePassword = ConvertTo-SecureString $PassString -AsPlainText -Force
        
# Save the secure password to a text file
$securePassword | ConvertFrom-SecureString | Out-File -FilePath $SaveLocation
