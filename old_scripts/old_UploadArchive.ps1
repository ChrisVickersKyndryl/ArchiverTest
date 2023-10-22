#-------------------------------------------------------------------------------------------------------------"
#   Upload Archive
#
#  This powershell copies archive event log files to file system for storage. 
#         0   - Sucessful
#         1   - Error
#         10  - No Drive letters avaible to map
#
#-------------------------------------------------------------------------------------------------------------"
  param(
    [String]$SourcePath,
    [String]$EncryptFile,
    [String]$StorageUser,
    [String]$DestLoc
  )
  
  # Build a display date
  $DisplayNow = Get-Date -format "yyyyMMdd_HHmmss" 

  #Build Log file path
  $LogFile = "C:\Kyndryl\UploadEventlogs_{0}.log" -f $DisplayNow  

  # Check if the log file exist and create the file
  if (Test-Path $LogFile) {
    Write-host "File '$LogFile' already exists!" -f Yellow
  }
  else {
    #Create a new file
    New-Item -Path $LogFile -ItemType "File"
  }

  # Add header 
  Add-Content -Path $LogFile -Value "`n`t`t --- Event Log archive upload --- "
  Add-Content -Path $LogFile -Value "`n`t`t`t Today:  $DisplayNow "
  Add-Content -Path $LogFile -Value "`n`t`t`t Path:  $SourcePath "
  Add-Content -Path $LogFile -Value "`n`t`t`t Destination:  $DestLoc "
  Add-Content -Path $LogFile -Value "`n`t`t`t Encrypted File:  $EncryptFile "
  Add-Content -Path $LogFile -Value "`n`t`t`t User:  $StorageUser "

  try {
      Add-Content -Path $LogFile -Value "`n`t Start 1. get Credentials:  $EncryptFile "
      
      if (Test-Path $EncryptFile) {
        # Read the encrypted password from the text file
        $securePassword = $(Get-Content -Path $EncryptFile | ConvertTo-SecureString)
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        
      } Else {
        Add-Content -Path $LogFile -Value "`n`t Error can not get encrypted file content "
        Exit 1
      }
      
  }
  catch {
    Add-Content -Path $LogFile -Value "`n`t Error occured getting creditals "
    $message = $_
        Add-Content -Path $LogFile -Value "`n`t $message"
    Exit 1
  } 
    
  # Go through drives and check if it is being used
  try {
      Add-Content -Path $LogFile -Value "`n`t Start 2. Get drive letter.."
      Foreach ($drvletter in "ABEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()) {
        $checkDrive = "{0}:" -f $drvletter
        
        # Check if the drive is being used. If yes go to next letter
        if(Get-Volume -FilePath $drvletter":\") {  
            write-host " Found Drive  $drvletter "  
            continue 
        } else {  
          Add-Content -Path $LogFile -Value "`n`t Start 2 use drive letter $drvletter "
          break
        }
      }
  }catch {
    Add-Content -Path $LogFile -Value "`n`t Error getting a drive to map to "
    $message = $_
        Add-Content -Path $LogFile -Value "`n`t $message"
    Exit 10
  }
  
  try {
      Add-Content -Path $LogFile -Value "`n`t Start 3. Map drive to $checkDrive  $DestLoc "
      # Temporarily map drive
      #New-PSDrive -Name $drvletter -PSProvider FileSystem -Root $DestLoc -Credential $credential
      New-SmbMapping -LocalPath $checkDrive -RemotePath $DestLoc -user $StorageUser -password $plain
      Add-Content -Path $LogFile -Value "`n`t Start 3. Map drive letter set to: $checkDrive "
      

  }catch {
      Add-Content -Path $LogFile -Value "`n`t Error mapping drive "
      $message = $_
        Add-Content -Path $LogFile -Value "`n`t $message"
      Exit 10
  }    

  try {
        Add-Content -Path $LogFile -Value "`n`t Start 4. If the remote folder there : $drvletter "    
        
        $destname = "{0}:\{1}" -f $drvletter,$env:computername
        
        # Create folder of server name, if it doesn't exist.
        If(!(test-path -PathType container $destname)) {
          New-Item -ItemType Directory -Path $destname
          Add-Content -Path $LogFile -Value "`n`t 4. new folder : $destname"
        }  
  }catch {
        Add-Content -Path $LogFile -Value "`n`t Error adding remote folder "
        $message = $_
        Add-Content -Path $LogFile -Value "`n`t $message"
        Exit 10
  }   
    
    
  try {
      # Move file to remote storage
      Add-Content -Path $LogFile -Value "`n`t Start 5. Process files in: $SourcePath "
      
      # Count files in folder than end with .evtv
      $countList = (Get-ChildItem -Path $SourcePath -Filter 'archive*.evtx').count 
      Add-Content -Path $LogFile -Value "`n`t Start 5. Number of files: $countList"  
      
      #move files  
      ROBOCOPY $SourcePath $destname archive*.evtx /MOV /COPY:DAT /LOG:C:\Kyndryl\eventlog_Move.log  
      
      $countList = (Get-ChildItem -Path $SourcePath -Filter 'archive*.evtx').count 
      Add-Content -Path $LogFile -Value "`n`t Start 4. After count: $countList"
    }catch {
      Add-Content -Path $LogFile -Value "`n`t Error processing files "
      $message = $_
      Add-Content -Path $LogFile -Value "`n`t $message"
      Exit 1
    }     

  try{
      Add-Content -Path $LogFile -Value "`n`t`t remove drive.... "
      # Remove drive
      Remove-SmbMapping $checkDrive -UpdateProfile
    
      write-host " Completed sucessfully"
      Add-Content -Path $LogFile -Value "`n`t`t Completed sucessfull.. "
      # Exit with success return code
      Exit 0

  } catch {
      Add-Content -Path $LogFile -Value "`n`t Error removing drive "
      $message = $_
      Add-Content -Path $LogFile -Value "`n`t $message"
      Exit 1
  }  
