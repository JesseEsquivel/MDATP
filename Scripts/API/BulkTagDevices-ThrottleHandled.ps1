<#
##################################################################################################################
#
# Microsoft
# BulkTagDevices.ps1
# jesse.esquivel@microsoft.com
# -Bulk tag devices using Defender API
# -01/12/21 Updated to handle more than 10K objects from API
# -08/18/21 Started update to handle API throttling (unfinished still needs debugged)
#
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
# Script variables - Dont forget to set your desired device tag and rbacGroupId!!
##################################################################################################################
#>

$VBCrLf = "`r`n"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$token = Get-Content "$scriptDir\Latest-token.txt"
$DeviceTag = "Test Tag"

#You must find your rbacGroupId in order to tag machines, do this by issuing the following in API explorer in the security center portal:
#GET https://api-us.securitycenter.windows.com/api/machines/{machineId} 
#It will look like this:
# 
#	"rbacGroupId": 1442,
#	"rbacGroupName": "RBAC Group 1"
#
#Or this:
#
#	"rbacGroupId": 2364,
#	"rbacGroupName": "RBAC Group 2"
#
#query for all machines in rbacGroupId 2364 above looks like this:
#https://api.securitycenter.windows.com/api/machines?$filter=rbacGroupId+eq+2364

#working with current rbacgroup below
$rbacGroupId = "4153"

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

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Get Target Machines based on rbacGroupId..." -ForegroundColor White
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

#Add the machines from the API response to a hashtable
$queryResponse = $response.Content | ConvertFrom-Json | select -expand value | select id, computerDNSName
$next = $response.Content | ConvertFrom-Json | Select-Object '@odata.nextLink'
$nextLink = $next.'@odata.nextLink'
$machines = @()
$machines += $queryResponse

#Determine if more machines need to be queried (@odata.nextLink exists), if so chase and repeat
if($nextLink)
{
    do
    {
        try
        {
            Write-Host "Additional returnset exists, querying API..." -ForegroundColor Cyan
            $moreObjects = Invoke-WebRequest -Method Get -Uri $nextLink -Headers $headers -ErrorAction Stop
            $queryResponse = $moreObjects.Content | ConvertFrom-Json | select -expand value | select id, computerDNSName
            $next = $moreObjects.Content | ConvertFrom-Json | Select-Object '@odata.nextLink'
            $nextLink = $next.'@odata.nextLink'  
            Write-Host "Success. Machines returned this query: $($queryResponse.Count)" -ForegroundColor Green
            Write-Host
            $machines += $queryResponse
        }
        catch
        {
            Write-Host "Failed to get device list from API: $($_.Exception.Message)" -ForegroundColor Red
            closeScript 1
        }
    }
    while($nextLink)
}

Write-Host "Data query completed..." -ForegroundColor Cyan
Write-Host "Success. Total machines returned: $($machines.Count)" -ForegroundColor Green
Write-Host

#Phase 2 tag machines
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 2 - Tag Target Machines..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

$i = 1
$coolDown = 0
foreach($machine in $machines)
{
    try
    {
        Write-Host "Tagging" $i "of" $machines.Count "Devices ($($machine.computerDnsName))..." -ForegroundColor Cyan
        #tag machine - can put additional logic (string, regex, etc) here via if statement against any available machine property
        
        do
        {
            if($coolDown -gt 0)
            {
                Write-Host -Object "Throttled; calming down for $coolDown seconds..."
                Start-Sleep -Seconds $coolDown
                #$headers.Calm = $true
            }

            try
            {
                $response = Invoke-WebRequest -Method Post -Uri "https://api-us.securitycenter.windows.com/api/machines/$($machine.id)/tags" -Headers $headers -Body "{`"Value`" : `"$DeviceTag`", `"Action`": `"Add`"}" -ErrorAction SilentlyContinue
            }
            catch
            {
                if($($_.Exception.Message) -notlike "*429*")
                {      
                    Write-Host "Failed to tag machine $($machine.computerDnsName)/$($machine.id) with: $($_.Exception.Message)" -ForegroundColor Red
                    closeScript 1
                }
            }            
            #$response = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing
            $ratelimit = $response.Headers['X-Rate-Limit-Remaining']
            write-host $ratelimit -ForegroundColor Yellow

            if([int]$ratelimit)
            {
                Write-Host -Object "Calm may be needed: rate limit remaining - $($ratelimit)" -ForegroundColor Yellow
            }
            $coolDown = $response.Headers["Retry-After"]
        }
        while($response.StatusCode -eq 429)
        Write-Host "Success." -ForegroundColor Green

        Invoke-WebRequest -Method Post -Uri "https://api-us.securitycenter.windows.com/api/machines/$($machine.id)/tags" -Headers $headers -Body "{`"Value`" : `"$DeviceTag`", `"Action`": `"Add`"}" | Out-Null #-ErrorAction Stop | Out-Null
        Write-Host "Success." -ForegroundColor Green
    }
    catch
    {
        if($($_.Exception.Message) -notlike "*429*")
        {      
            Write-Host "Failed to tag machine $($machine.computerDnsName)/$($machine.id) with: $($_.Exception.Message)" -ForegroundColor Red
            closeScript 1
        }
    }

    $i = $i + 1
    Write-Host
}

closescript 0
