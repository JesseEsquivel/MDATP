<#
##################################################################################################################
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com
# Convert-AVExclusions.ps1
# v1.0 Initial creation 12/03/2020 - Export McAfee AV Exclusions into Defender format from xml
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
$output = "$scriptDir\AVExclustions-Output.txt"

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
        $_ -replace '(^\*\*.+~)', "$($_.split("\")[1])~" `
           -replace '(\*\.\*|\*\*)', '*' `
           -replace '(C:\\Windows)', '%windir%' `
           -replace '(C:\\Windows\\System32)', '%windir%\System32' `
           -replace '(^.:\\Program Files \(x86\)\\)', '%ProgramFiles(x86)%\' `
           -replace '(^.:\\Program Files\*\\|.:\\Program Files\\)', '%ProgramFiles%\' `
           -replace '(^.:\\ProgramData\\)', '%ProgramData%\' `
           -replace '(^%ProgramFiles\*%\\)', '%ProgramFiles%\' `
           -replace '(\*\\~)', '\*~'
        } | Set-Content $output
}

#write CSV header delmite by "~" character
Write-This "Exclusion~Note" $rawOutput

$ip = 1
$if = 1

foreach($item in $sourceExclusions.EPOPolicySchema.EPOPolicySettings.Section)
{
    if($item.name -LIKE "*Exclusions*")
    {
        Write-Host "*************************************************************************************" -ForegroundColor White
        Write-Host "Reading McAfee AV path exclusions section and exporting..." -ForegroundColor White
        Write-Host "*************************************************************************************" -ForegroundColor White
        Write-Host 
        $settings = $item.setting
        foreach($setting in $settings)
        {
            Write-Host "Processing path exclusion $ip..."
            if($setting.value.split("|")[3])
            {    
                $noteString = $setting.value.split("|")[3].replace("`n","")
            }
            Write-This "$($setting.value.split("|")[2])~$noteString" $rawOutput
            Write-Host "Success." -ForegroundColor Green
            Write-Host
            $ip = $ip + 1
        }
    }
    elseif($item.name -eq "Application")
    {
        Write-Host "*************************************************************************************" -ForegroundColor White
        Write-Host "Reading McAfee AV file exclusions and exporting..." -ForegroundColor White
        Write-Host "*************************************************************************************" -ForegroundColor White
        Write-Host
        $settings = $item.setting
        foreach($setting in $settings)
        {
            
            if($setting.name -LIKE "*ApplicationItem*")
            {
                Write-Host "Processing file exclusion $if..."
                Write-Host $setting.value -ForegroundColor Green
                Write-This "$($setting.value)~" $rawOutput
                $if = $if + 1
                Write-Host "Success." -ForegroundColor Green
                Write-Host
            }
            
        }
    }
    $i = $i + 1
}

Replace-Strings $rawOutput
