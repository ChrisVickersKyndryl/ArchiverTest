># tpa_log_windows
>

>## Synopsis
>This repository contains playbooks and scripts to setup a custom Windows Event log archive solution. The playbooks create Windows Schedule Task's that run daily to copy archive files to a central file system, maintain the archive files to 180 days. 
---

>## Playbook Overview and Execution

>
>### Upload schedule creation 
>**CreateScheduleTask.yml** This playbook will create a Windows Schedule Task that will run the *UploadArchive.ps1* PowerShell script. The Schedule time will be a random time between 11:00pm and 12:00pm that will run daily. 
>#### Variables
>| Variable | Default  | Comment |
>| --- | ---  | --- |
>| env | None | **Mandatory** This string is an Environment value either *dev*,*test* and *prod*. This helps define the target destination.
>| storage_password | None | **Mandatory** this is the password for the user that is attached to the Schedule Task. 

>### Execution Report
>**ExecutionReport.yml** This playbook will check the Windows Schedule Task *'Copy archived logs to server'* on hosts and produce an execution report email. It looks at last task result value and reports good if 0, else bad on any other status. It also checks if the schedule exists, if it does not it then reports a bad status.
>#### Variables
>| Variable | Default  | Comment |
>| --- | ---  | --- |
>| destination_email | None | **Mandatory** The email address for the report to be sent to.

>### 180 day clean up
>**CreateRemoveFileTask.yml**
>#### Variables
>| Variable | Default  | Comment |
>| --- | ---  | --- |
>| kyndryl_folder | C:\Kyndryl\ | **Mandatory** A script folder to execute powershell files from. |
>| remove_script | RemoveFiles.ps1 | **Mandatory** Powershell script to find and remove files over 180 days.|
>| storage_user | ###  | **Mandatory** User to run Schedule Task and has access to the storage array.|
>| storage_password | ###| **Mandatory** User password.|
>| log_directory | logs | **Mandatory** The folder on the storage array the log file will be stored.|
>#### Script
>**RemoveFiles.ps1** This is a PowerShell script which removes any archive files that have a creation date greater than 180 days. The script will produce a deletion report.

<!-- >| storage_password | None | **Mandatory** This password string is required to create the creditals for running this upload process. -->
>### Clean Project
>**ProjectClean.yml** This ansible playbook can be run to clean up the related Scheduled Tasks, scripts and files that are created for this project.

