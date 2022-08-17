<#
##################################################################################################################
#
# Microsoft
# TVMBulkVulnExport.ps1
# jesse.esquivel@microsoft.com
# -Call TVM vulnerability assessement bulk export API
# -Produces json file that can be imported into PBI for reporting
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
# Script variables - 
##################################################################################################################
#>

$VBCrLf = "`r`n"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

##################################################################################################################
# Functions 
##################################################################################################################

Function startScript()
{
    $msg = "Querying TVM Vulnerability Assessment API" + $VBCrLf + "@ $(get-date) via PowerShell Script."
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
        + $VBCrLf + "Examine the script output to resolve errors. Ensure you are using the correct API and login endpoints"
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

Function UnZip-File{
    Param(
        $infile,
        $outfile = ($infile -replace '\.gz$','')
    )
    $input = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
    $buffer = New-Object byte[](1024)
    while($true)
    {
        $read = $gzipstream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
    }
    $gzipStream.Close()
    $output.Close()
    $input.Close()
}

##################################################################################################################
# Begin Script
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript

#enter tenant specific information here
$tenantId = '' ### Paste your own tenant ID here
$appId = '' ### Paste your own app ID here
$appSecret = '' ### Paste your own app keys here

#OAuth
#$resourceAppIdUri = 'https://api-gcc.securitycenter.microsoft.us' #GCC-M
#$resourceAppIdUri = 'https://api-gov.securitycenter.microsoft.us' #GCC-H/DoD
$resourceAppIdUri = 'https://api.securitycenter.microsoft.com' #commercial
$oAuthUri = "https://login.windows.net/$TenantId/oauth2/token" # commercial/GCC-M
#$oAuthUri = "https://login.microsoftonline.us/$TenantId/oauth2/token" #GCC-H/DoD


$authBody = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}

try 
{
    $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
    $token = $authResponse.access_token
}
catch
{
    Write-Host "Failed to fetch OAuth token: $($_.Exception.Message)" -ForegroundColor Red
    closeScript 1
}

# Store OAuth token into header for future use
$headers = @{
        'Content-Type' = 'application/json'
        Accept = 'application/json'
        Authorization = "Bearer $token"
    }

#API URL, select EU, US, or USGOV
#$url = 'https://api-eu.securitycenter.microsoft.com/api/machines/SecureConfigurationsAssessmentExport'
$url = 'https://api-us.securitycenter.microsoft.com/api/machines/SecureConfigurationsAssessmentExport'
#$url = 'https://api-gov.securitycenter.microsoft.us/api/machines/SoftwareVulnerabilitiesExport'

try
{
    $webResponse = Invoke-RestMethod -Method Get -Uri $url -Headers $headers -ErrorAction Stop
}
catch
{
    Write-Host "Failed to call API: $($_.Exception.Message)" -ForegroundColor Red
    closeScript 1
}

$i = 0
$c = 1
foreach($exportfile in $WebResponse.exportFiles)
{
    $ObjectId = $webResponse.exportFiles[$i]
    Write-Host "Getting URL $c of $($WebResponse.exportFiles.count) " -ForegroundColor Yellow
    Write-Host $ObjectId -ForegroundColor Cyan

    try 
    {
        Invoke-WebRequest -Uri $ObjectId  -OutFile "$scriptDir\File$i.gz"
        UnZip-File "$scriptDir\File$i.gz" "$scriptDir\File$i.json"
        Remove-Item "$scriptDir\File$i.gz" -Filter * -Recurse -ErrorAction Ignore
    }
    catch
    {
        Write-Host "Failed to download output file from API: $($_.Exception.Message)" -ForegroundColor Red
        closeScript 1
    }

    $i++
    $c++
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}

Get-Content "$scriptDir\File*.json" | Out-File "$scriptDir\Final.json"
Remove-Item "$scriptDir\File*.json"  -Filter * -Recurse -ErrorAction Ignore
Write-Host "json output for PowerBI is provided at $scriptDir\Final.json" -ForegroundColor DarkGreen
closeScript 0
