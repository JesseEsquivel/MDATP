<#
##################################################################################################################
#
# Microsoft
# BulkTagDevices.ps1
# jesse.esquivel@microsoft.com
# -Bulk tag devices using Defender for Endpoint API
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
# Script variables - Dont forget to set your desired device tag and rbacGroupId!!
##################################################################################################################
#>

$VBCrLf = "`r`n"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$token = Get-Content "$scriptDir\Latest-token.txt"
$DeviceTag = "Testing 1 2"

#You must find your rbacGroupId in order to tag machines, do this by issuing the following in API explorer in the security center portal:
#GET https://api-us.securitycenter.windows.com/api/machines/{machineId} 
#It will look like this:
# 
#"rbacGroupId": 1234,
#"rbacGroupName": "Name of your MachineGroup 1"
#
# Or this:
#
#"rbacGroupId": 4321,
#"rbacGroupName": "Name of your MachineGroup 2"
#
#for example a query for all machines in rbacGroupId 1234 above looks like this:
#https://api.securitycenter.windows.com/api/machines?$filter=rbacGroupId+eq+1234

$rbacGroupId = "1234"

##################################################################################################################
# Functions
##################################################################################################################

Function startScript()
{
    $msg = "Beginning MDE device tagging job from $env:COMPUTERNAME" + $VBCrLf + "@ $(get-date) via PowerShell Script.  Logging is enabled."
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host  "$msg" -ForegroundColor Green
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host
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
    }
    else
    {
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Successfully completed script at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" + $VBCrLf `
        + "Review the logs."
        Write-Host $msg -ForegroundColor Green
        Write-Host "######################################################################################" -ForegroundColor Yellow
    }
    exit $exitCode
}

##################################################################################################################
# Begin Script
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript

#process all EXCHFRST users in Bulk to mail enable
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Get Target Machines based on rbacGroupId and Tag..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

#use the api to get all machines based on rbacGroupId
$machineQueryUrl = "https://api-us.securitycenter.windows.com/api/machines?`$filter=rbacGroupId+eq+$rbacGroupId"

#Set the WebRequest headers
$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $token" 
}

#Send the webrequest and get the results.
try
{ 
    Write-Host "Fetching target device list from API..." -ForegroundColor Cyan
    $response = Invoke-WebRequest -Method Get -Uri $machineQueryUrl -Headers $headers -ErrorAction Stop
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}
catch
{
    Write-Host "Failed to get device list from API: $($_.Exception.Message)" -ForegroundColor Red
    closeScript 1
}

#iterate the returnset and grab the machineId of each machine to be used to call the API and set the new machine tag
$machines = $response.Content | ConvertFrom-Json | select -expand value | select id, computerDNSName
$i = 1
foreach($machine in $machines)
{
    #Write-Host $machine.Id $machine.computerDnsName -ForegroundColor Green
    #$deviceId = $machine.id
    try
    {
        Write-Host "Tagging" $i "of" $machines.Count "Devices ($($machine.computerDnsName))..." -ForegroundColor Cyan
        #tag machine - can put additional logic (string, regex, etc) here via if statement against any available machine property
        Invoke-WebRequest -Method Post -Uri "https://api-us.securitycenter.windows.com/api/machines/$($machine.id)/tags" -Headers $headers -Body "{`"Value`" : `"$DeviceTag`", `"Action`": `"Add`"}" -ErrorAction Stop | Out-Null
        Write-Host "Success." -ForegroundColor Green
    }
    catch
    {
        Write-Host "Failed to tag machine $($machine.computerDnsName)/$($machine.id) with: $($_.Exception.Message)" -ForegroundColor Red
        closeScript 1
    }
    $i = $i + 1
    Write-Host
}

closescript 0
