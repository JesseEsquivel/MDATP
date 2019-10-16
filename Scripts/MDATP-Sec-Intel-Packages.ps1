<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# jesse.esquivel@microsoft.com
# MDATP-Sec-Intel-Packages.ps1
# v1.0 08/05/2019 Initial creation - Download MDATP Security Intelligence Packages
# v1.1 10/16/2019 Bug fix for extraction method, and test for x64 dir 
#
# 
# 
# Microsoft Disclaimer for custom scripts
# ================================================================================================================
# The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts
# are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, 
# without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire
# risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event
# shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be
# liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business
# interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to 
# use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
# ================================================================================================================
#
##################################################################################################################
# Script variables - please do not change these unless you know what you are doing
##################################################################################################################
#>

$VBCrLf = "`r`n"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[System.Diagnostics.EventLog]$evt = New-Object System.Diagnostics.EventLog("Application")
[String]$evt.Source = "MDATP Security Intelligence Package Downloader"
[System.Diagnostics.EventLogEntryType]$infoEvent = [System.Diagnostics.EventLogEntryType]::Information
[System.Diagnostics.EventLogEntryType]$warningEvent = [System.Diagnostics.EventLogEntryType]::Warning
[System.Diagnostics.EventLogEntryType]$errorEvent = [System.Diagnostics.EventLogEntryType]::Error
$vdmpathbase = 'C:\Windows\wdav-update\{00000000-0000-0000-0000-'
$vdmpathtime = Get-Date -Format "yMMddHHmmss"
$vdmpath = $vdmpathbase + $vdmpathtime + '}'
$vdmpackage = $vdmpath + '\mpam-fe.exe'
$args = @("/X")

##################################################################################################################
# Functions - please do not change these unless you know what you are doing
##################################################################################################################

Function startScript()
{
    $msg = "Beginning WDAV download tasks from $env:COMPUTERNAME" + $VBCrLf + "@ $(get-date) via PowerShell Script.  Logging is enabled."
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host  "$msg" -ForegroundColor Green
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host
    log-This $infoEvent $msg
}

Function log-This()
{
    param([System.Diagnostics.EventLogEntryType]$entryType = $infoEvent, [String]$message)
    [int]$eventID = 1
    switch([System.Diagnostics.EventLogEntryType]$entryType)
    {
        $infoEvent{$eventId = 411}
        $warningEvent{$eventId = 611}
        $errorEvent{$eventId = 011}
        default{$eventID = 411}
    }
    try
    {
        $evt.WriteEntry($message,$entryType,$eventID)
    }
    catch
    {
        $msg = "`nDid you remember to register the Eventlog source`n"
        $msg += "Try: c:\eventcreate /ID 411 /L APPLICATION /T INFORMATION /SO " + $evt.Source + " /D 'New event source'`n"
        $msg += "using an account who has been delegated the user right 'manage auditing and security log'`n"
        Write-Host $msg
        Write-Host $_.Exception.Message
        closescript 1
     }
}

Function Prune-Folders($Daysback, $path)
{
    try
    {
        $currentDate = Get-Date
        $dateToDelete = $currentDate.AddDays($Daysback)
        Get-ChildItem $path -Recurse | Where-Object{$_.LastWriteTime -lt $dateToDelete -and $_.FullName -ne "x64"} | Remove-Item -Recurse -Force
    }
    catch
    {
        Write-Host "Failed to remove folders older than 7 days in $vdmpath with error:  $($_.Exception.Message)" -ForegroundColor Red
        log-This $errorEvent "Failed to remove folders older than 7 days in $vdmpath with error:  $($_.Exception.Message)"
        closescript 1
    }
}

Function closeScript($exitCode)
{
    if($exitCode -ne 0)
    {
        Write-Host
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Script execution unsuccessful, and terminted at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" `
        + $VBCrLf + "Examine the script output and previous events logged to resolve errors."
        Write-Host $msg -ForegroundColor Red
        Write-Host "######################################################################################" -ForegroundColor Yellow
        log-This $errorEVent $msg
    }
    else
    {
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Successfully completed script at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" + $VBCrLf `
        + "Review the logs."
        Write-Host $msg -ForegroundColor Green
        Write-Host "######################################################################################" -ForegroundColor Yellow
        log-This $infoEvent $msg
    }
    exit $exitCode
}

##################################################################################################################
# Begin Script  - please do not change unless you know what you are doing
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Fetching Security Intelligence Packages..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

Write-Host "Fetching x64 Security Intelligence Package..."
try
{
    New-Item -ItemType Directory -Force -path $vdmpath | Out-Null
    Invoke-WebRequest -uri 'https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64' -OutFile $vdmpackage -ErrorAction Stop
}
catch
{
    Write-Host "Failed to download package:  $($_.Exception.Message)" -ForegroundColor Red
    Remove-Item -LiteralPath $vdmpath -Force | Out-Null
    log-This $errorEvent "Failed to download package https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64 with error:  $($_.Exception.Message)"
    closescript 1
}

Write-Host "Success." -ForegroundColor Green
log-This $infoEvent "Successfully fetched Security Intelligence Package: $vdmPackage"
Write-Host

try
{
    Write-Host "Extracting Security Intelligence Package..."
    Start-Process C:\windows\system32\cmd.exe -ArgumentList "/c cd $vdmpath & mpam-fe.exe /x" -Wait -WindowStyle Hidden
}
catch
{
    Write-Host "Failed to extract security intelligence package $vdmPackage : $($_.Exception.Message)" -ForegroundColor Red
    log-This $errorEvent "Failed to extract security intelligence package $vdmPackage : $($_.Exception.Message)"
    closescript 1
}

Write-Host "Success." -ForegroundColor Green
log-This $infoEvent "Successfully extracted Security Intelligence Package: $vdmPackage"
Write-Host

try
{
    Write-Host "Copying extracted files to share..."
    Copy-Item -Path $vdmpath -Destination "\\fileserver.fqdn\mdatp$\wdav-update" -Force -Recurse | Out-Null
    Get-ChildItem "\\fileserver.fqdn\mdatp$\wdav-update\x64" -Recurse | ForEach-Object {Remove-Item $_.FullName -Recurse -Force}
    If(!(Test-Path -Path "\\fileserver.fqdn\mdatp$\wdav-update\x64"))
    {
        New-Item -ItemType Directory -Force -path "\\fileserver.fqdn\mdatp$\wdav-update\x64" | Out-Null
    }
    Copy-Item -Path "$vdmpath\*" -Destination "\\fileserver.fqdn\mdatp$\wdav-update\x64" -Force -Recurse | Out-Null
}
catch
{
    Write-Host "Failed to copy extracted files to share \\fileserver.fqdn\mdatp$\: $($_.Exception.Message)" -ForegroundColor Red
    log-This $errorEvent "Failed to copy extracted files to share \\fileserver.fqdn\mdatp$\: $($_.Exception.Message)"
    closescript 1
}

Write-Host "Success." -ForegroundColor Green
log-This $infoEvent "Successfully copied extracted files to share: \\fileserver.fqdn\mdatp$\wdav-update\x64"
Write-Host

try
{
    Write-Host "Pruning Folders older than 7 days..."
    Prune-Folders "-7" "\\fileserver.fqdn\mdatp$\wdav-update"
    Prune-Folders "-7" "C:\Windows\wdav-update"
}
catch
{
    Write-Host "Failed to prune folders older than 7 days: $($_.Exception.Message)" -ForegroundColor Red
    log-This $errorEvent "Failed to prune folders older than 7 days: $($_.Exception.Message)"
    closescript 1
}

Write-Host "Success." -ForegroundColor Green
log-This $infoEvent "Successfully pruned folders older than 7 days in C:\Windows\wdav-update, and in \\fileserver.fqdn\mdatp$\wdav-update"
Write-Host

closescript 0