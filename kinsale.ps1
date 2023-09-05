
# ********************************************
# *** Scriptname:palltronic.ps1
# *** Author: Shannon
# *** Version: 1.1
# *** Program file for PALLTRONIC XML DATA File Copy from Shared Location to DEV 3.5 Server
# ********************************************


#Configuration variable ...
#Update the log file and logfiles folder as dynamic
$config = Get-Content 'E:\DIA_SPLUNK_FIT\Config\Config.txt' | Select -Skip 1 | ConvertFrom-StringData
#$StartTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
#Creating Log File
$Logfilename = "Log_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt"
$Logfilenamepath = $config.LOGfile+"\$Logfilename"
New-Item $Logfilenamepath
$message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " Splunk File Copy job Started" 
Add-Content $Logfilenamepath $message
$isFailure =0


Try
    {
    $SRCFolderDir = $Config.SRCFldr
    $TRGTFolderDir = $Config.TRGTFldr

    $message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " Copying file from "+ $SRCFolderDir +" to " +$TRGTFolderDir
    Add-Content $Logfilenamepath $message


    robocopy $SRCFolderDir $TRGTFolderDir *.xml /LOG+:$Logfilenamepath

        if ($lastexitcode -lt 8)
         {
              $message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") +  " Splunk File Copy job  succeeded with exit code:" + $lastexitcode
              $isFailure =0
             
         }
        else
        {
              $message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") +  " Splunk File Copy job  failed with exit code:" + $lastexitcode
              $isFailure =1
        }
        Add-Content $Logfilenamepath $message;

   
    }
CATCH 
    {
      $isFailure =2
      $message  = "An error occurred:" + $_.ScriptStackTrace
      Add-Content $Logfilenamepath $message  
      $message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") +  " Splunk File Copy job could not completed." 
    }

if ($isFailure -gt 0)
{

      Send-mail;
}
 
$message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " Deleteing old files from: "+ $TRGTFolderDir
Add-Content $Logfilenamepath $message 
Get-ChildItem $TRGTFolderDir  -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item
$message= (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " Deleteing old files from: "+ $config.LOGfile
Add-Content $Logfilenamepath $message 
Get-ChildItem $config.LOGfile -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item


  Function Send-Mail
    {

     $MailServer=$Config.EmailSrvr
     $MailSender =$Config.EmailSndr
     $MailAddresses=$Config.EmailRCPNT
     $Mailsubject =$Config.EmailSbjct
    $SummaryText += "There is an Error occured, please refer the attached log file."
     Send-MailMessage -From $MailSender -To $MailAddresses -Subject $Mailsubject -BodyAsHtml $SummaryText -Attachments $Logfilenamepath -SmtpServer $MailServer 
    }
   
   
#ExitCodes:
#0	No action performed. Source and destination are synchronized.
#1	At least one file was copied successfully.
#2	Extra files or directories were detected. Examine log.
#3	Exit codes 2 and 1 combined.
#4	Mismatched files or directories found. Examine log.
#5	Exit codes 4 and 1 combined.
#6	Exit codes 4 and 2 combined.
#7	Exit codes 4, 1 and 2 combined.
#8	At least one file or directory could not be copied. Retry limit exceeeded. Examine log.
#16	Copy failed catastrophically.


    



