<#
##################################################################################################################
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com
# Convert-SEPExclusions.ps1
# v1.0 Initial creation 12/10/2020 - Export SEP AV Exclusions into Defender format from xml
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
[xml]$sourceExclusions = Get-Content "$scriptDir\yourExported.xml"
$rawOutput = "$scriptDir\AVExclusions-RawOutput.txt"
$output = "$scriptDir\AVExclusions-Output.txt"

Function Write-This($data, $log)
{
    try
    {
        Add-Content -Path $log -Value $data -ErrorAction Stop
    }
    catch
    {
        write-host $_.Exception.Message
    }
}

Function Replace-Strings($raw)
{
    #add more regex here if you need to replace more strings
    Get-Content $raw | Foreach-Object {
        $_ -replace '(C:\\Windows)', '%windir%' `
           -replace '(C:\\Windows\\System32)', '%windir%\System32' `
           -replace '(^.:\\Program Files \(x86\)\\)', '%ProgramFiles(x86)%\' `
           -replace '(^.:\\Program Files\*\\|.:\\Program Files\\)', '%ProgramFiles%\' `
           -replace '(^.:\\ProgramData\\)', '%ProgramData%\' `
           -replace '(^%ProgramFiles\*%\\)', '%ProgramFiles%\' `
        } | Set-Content $output
}

#write CSV header delmite by "~" character
Write-This "Exclusion~Note" $rawOutput

$ip = 1
$if = 1

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Reading SEP AV exclusions and exporting..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

foreach($item in $sourceExclusions.SchemaContainer.PolicyOverride.OverrideItem)
{
    if($item)
    {
        $settings = $item
        foreach($setting in $settings)
        {
            if($setting.TamperProtectionOverride)
            {
                Write-Host "Processing AV exclusion $ip..."
                foreach($app in $setting.TamperProtectionOverride.PermittedApplication)
                {
                    Write-This $app.ApplicationName $rawOutput
                    Write-Host $app.ApplicationName -ForegroundColor Green
                    Write-Host
                }
                $ip = $ip + 1
            }
            elseif($setting.SecurityRiskOverride)
            {
                $childNodes = $setting.SecurityRiskOverride.ChildNodes
                if($childNodes.'#Text')
                {
                    Write-Host "Processing AV exclusion $ip..."
                    Write-This $childNodes.'#Text' $rawOutput
                    Write-Host $childNodes.'#Text' -ForegroundColor Green
                    Write-Host
                    $ip = $ip + 1
                }
                foreach($item in $setting.SecurityRiskOverride.DirectoryOverride)
                {
                    Write-Host "Processing AV exclusion $ip..."
                    Write-This $item.DirectoryPath $rawOutput
                    Write-Host $item.DirectoryPath -ForegroundColor Green
                    Write-Host
                    $ip = $ip + 1
                }
                foreach($item in $setting.SecurityRiskOverride.FileOverride)
                {
                    Write-Host "Processing AV exclusion $ip..."
                    Write-This $item.FilePath $rawOutput
                    Write-Host $item.FilePath -ForegroundColor Green
                    Write-Host
                    $ip = $ip + 1
                }
            }
            elseif($setting.DnsHostFileOverride)
            {
                foreach($item in $setting.DnsHostFileOverride.DetectedProcesses)
                {
                    Write-Host "Processing AV exclusion $ip..."
                    Write-This $item.Path $rawOutput
                    Write-Host $item.Path -ForegroundColor Green
                    Write-Host
                    $ip = $ip + 1
                }
            }
            elseif($setting.HeuristicPolicyOverride)
            {
                foreach($item in $setting.HeuristicPolicyOverride.DetectedProcesses)
                {
                    Write-Host "Processing AV exclusion $ip..."
                    Write-This $item.Path $rawOutput
                    Write-Host $item.Path -ForegroundColor Green
                    Write-Host
                    $ip = $ip + 1
                }
            }
        }
    }
}

Replace-Strings $rawOutput
