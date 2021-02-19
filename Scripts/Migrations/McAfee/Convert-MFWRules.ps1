<#
##################################################################################################################
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com
# Convert-MFWRules.ps1
# v1.0 Initial creation 10/08/2020 - Convert McAfee Firewall Rules to Microsoft Defender Firewall (MDF) format
# v1.1 02/19/2021 - Fixed issue where all rules were not exported, added replace strings function
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
# Script variables
##################################################################################################################
#>

$VBCrLf = "`r`n"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[xml]$sourceRules = Get-Content "$scriptDir\yourExported.xml"
$output = "$scriptDir\FWRules-Output.txt"
$FWRuleNamePrepend = "TEST" #whatever string is set here will be prepended to all firewall rule names/displaynames

##################################################################################################################
# Functions
##################################################################################################################

Function startScript()
{
    $msg = "Beginning Migration tasks from $env:COMPUTERNAME" + $VBCrLf + "@ $(get-date) via PowerShell Script.  Logging is enabled."
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host  "$msg" -ForegroundColor Green
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host
    #Write-This $msg $Log
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
        #Write-This $msg $log
    }
    else
    {
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Successfully completed script at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" + $VBCrLf `
        + "Review the logs."
        Write-Host $msg -ForegroundColor Green
        Write-Host "######################################################################################" -ForegroundColor Yellow
        #Write-This $msg $log
    }
    exit $exitCode
}

Function Replace-Strings($raw)
{
    #add more regex here if you need to replace more strings
    Get-Content $raw | Foreach-Object {
        $_ -replace '(\*\*\\)', '' `
           -replace '(.\\Windows\\system32)', '%SystemRoot%\System32' `
           -replace '(C:\\Windows)', '%WinDir%' `
           -replace '(.:\\Program Files \(x86\)\\)', '%ProgramFiles(x86)%\' `
           -replace '(.:\\Program Files\*\\|.:\\Program Files\\)', '%ProgramFiles%\' `
           -replace '(.:\\ProgramData\\)', '%ProgramData%\' `
           -replace '(%ProgramFiles\*%\\)', '%ProgramFiles%\' `
           -replace '(\*\\~)', '\*~'
        } | Set-Content $output
}

##################################################################################################################
# Begin Script
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript

#process xml and output firewall rules in MDF consumable format
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Reading McAfee FW rules, correlating, and exporting..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

$firewallRules = @()
$i = 1
foreach($item in $sourceRules.EPOPolicySchema.EPOPolicySettings.Section)
{
    Write-Host "Capturing" $i "of" $sourceRules.EPOPolicySchema.EPOPolicySettings.Section.Count "Firewall Rule Sections..." -ForegroundColor Cyan
    $HashProps = [PSCustomObject]@{}
    #Loop all sections of XML
    $targetGUIDName = $null            
    $targetGUID = $null
    $targetDestName = $null
    $targetDest = $null

    $settings = $item.Setting
    #For each aggregate section find the GUID value
    foreach($setting in $settings)
    {
        switch($setting.name)
            {
                'GUID'{$targetGUIDName = $setting.name;$targetGUID = $setting.value}
                'Name'{$targetDestName = $setting.name;$targetDest = $setting.value}
                '+AppPath#0'{if($setting.value){$appPath = $setting.value}else{$appPath = 'ANY'}} #<-check for empty string in value
            }
    }
    if(!($targetDest))
    {
        $targetDest = 'ANY'
    }
    #give props where props are due
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "CorrelatedGUID" -Value $targetGUID
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Program" -Value $appPath #pass ANY if null!!
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Remote Address" -Value $targetDest
    #add required Windows Firewall specific params
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Profile" -Value 'ANY'
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Interface Type" -Value 'ANY'
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Local Port" -Value 'ANY' #<-- this is required as header must be present in all hash tables in order to output to CSV
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Remote Port" -Value '' #<-- this is required as header must be present in all hash tables in order to output to CSV
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Protocol" -Value 'TCP' #<-- this is required as header must be present in all hash tables in order to output to CSV - this cant be ANY if a RemotePort value is present, default here to TCP
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Direction" -Value $null #<-- this is required as header must be present in all hash tables in order to output to CSV
    Write-Host "Merging AggregateCriterion Rule Values..." -ForegroundColor DarkCyan
    foreach($item in $sourceRules.EPOPolicySchema.EPOPolicySettings.Section)
    {
        #Search all non-aggregate sections of the xml for the GUID value and scrape the needed values for the FW rule
        $settings = $item.Setting
        foreach($setting in $settings)
        {
            if($setting.value -eq $targetGUID)
            {
                foreach($setting in $settings)
                {
                    if($setting.name -ne "Note") #note column has ; in it which delimit in the csv output even though a different delimeter is selected :\
                    {
                        if(!$appPath)
                        {
                            Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Program" -Value 'ANY' -Force
                        }
                        switch($setting.name)
                        {
                            'Name'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "DisplayName" -Value "$FWRuleNamePrepend-$($setting.value)" -Force}
                            '+LocalPort#0'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Local Port" -Value $setting.value -Force}
                            '+RemotePort#0'{if($setting.value){$remotePort = $setting.value}else{$remotePort = 'ANY'}}
                            '+TransportProtocol#0'{
                            switch($setting.value)
                            {
                                '17'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Protocol" -Value "UDP" -Force}
                                '6'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Protocol" -Value "TCP" -Force}
                                Default{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Protocol" -Value $setting.value -Force}
                            }
                        }
                        'Direction'{
                         switch($setting.value)
                             {
                                'IN'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value 'INBOUND' -Force}
                                'OUT'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value 'OUTBOUND' -Force}
                                'BOTH'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value $setting.value -Force}
                                'EITHER'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value $setting.value -Force}
                             }
                        }
                        'Enabled'{
                         switch($setting.value)
                            {
                                '1'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value 'TRUE' -Force}
                                '0'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value 'FALSE' -Force}
                            }
                        }
                        'Action'{
                            switch($setting.value)
                            {
                                'ALLOW'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value $setting.value -Force}
                                'BLOCK'{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value $setting.value -Force}
                                Default{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value 'ALLOW' -Force}
                            }
                        }
                        #to only export rules in MDF format comment out the next line
                        #Default{Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $setting.name -Value $setting.value -Force}
                        }
                        Add-Member -InputObject $HashProps -MemberType NoteProperty -Name "Remote Port" -Value $remotePort -Force
                    }
                }
            }
        }   
    }
    if($targetGUID)
    {
        $firewallRules += $HashProps
    }
    $i = $i + 1
    $appPath = $null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}

$firewallRules | ConvertTo-CSV -NoTypeInformation -Delimiter '~' | Set-Content $scriptDir\RawOutput.txt
Replace-Strings $scriptDir\RawOutput.txt

closescript 0

<#review CSV output and sanitize before importing firewall rules into test VM
    Reference is here: https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps

    1. Open output.txt in excel, select ~ as the delimiter
    2  Sort output by Remote Address column and remove any invalid values (names etc), follow -Remote address switch guidance 
       for New-NetFirewallRule cmdlet
    3. Sort by Program Column and remove any invalid characters such as "*", follow -Program switch guidance for New-NetFirewallRule
       cmdlet
    4. Sort by Direction column and for each entry listed as BOTH or EITHER, copy those rows and append to the sheet, then change the
       Direction value to INBOUND for original set, and change the Diretion value to OUTBOUND for the copied set. Follow 
       the -Program switch guidance for New-NetFirewallRule cmdlet.  This is required because the switch can only accept Inbound
       or outbound values.
    5. Run the Import-FW Rules script on a VM to import your firewall rules into MDF

#>
