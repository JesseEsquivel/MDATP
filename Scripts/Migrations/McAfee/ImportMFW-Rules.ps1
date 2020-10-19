<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# jesse.esquivel@microsoft.com
# ImportMFW-Rules.ps1
# v1.0 Initial creation 10/19/2020 - Import MDF rules from McAfee output CSV
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
$CSVFile = "$scriptDir\input.csv"
$FirewallRules = Get-Content $CSVFile | ConvertFrom-CSV

##################################################################################################################
# Functions - please do not change these unless you know what you are doing
##################################################################################################################

Function startScript()
{
    $msg = "Beginning MDF rules import from $env:COMPUTERNAME" + $VBCrLf + "@ $(get-date) via PowerShell Script.  Logging is enabled."
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

function ListToStringArray([STRING]$List, $DefaultValue = "Any")
{
	if (![STRING]::IsNullOrEmpty($List))
	{	return ($List -split ",")	}
	else
	{	return $DefaultValue}
}

##################################################################################################################
# Begin Script  - please do not change unless you know what you are doing
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Importing MDF rules..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

$i = 1
ForEach ($Rule In $FirewallRules)
{
    Write-Host "Importing" $i "of" $($FirewallRules.count) "Firewall Rules..." -ForegroundColor Cyan
	$RuleSplatHash = @{
		#Name = $Rule.Name
		Displayname = $Rule.DisplayName
		#Description = $Rule.Description
		#Group = $Rule.Group
		Enabled = $Rule.Enabled
		Profile = $Rule.Profile
		#Platform = ListToStringArray $Rule.Platform @()
    Direction = $Rule.Direction
		Action = $Rule.Action
		#EdgeTraversalPolicy = $Rule.EdgeTraversalPolicy
		#LooseSourceMapping = ValueToBoolean $Rule.LooseSourceMapping
		#LocalOnlyMapping = ValueToBoolean $Rule.LocalOnlyMapping
		#LocalAddress = ListToStringArray $Rule.LocalAddres
    RemoteAddress = $($Rule.'Remote Address') -replace ('(\s+-\s+|\s+,\s+,\s+|\s+,\s+|,\s+|\s-\s|and|\s+and\s+|and\s+|-\s+|\s+-|-|\sand)', ",") -split "," #<--remove human induced whitespace and nonvalid characters
		Protocol = $($Rule.Protocol)
		LocalPort = ListToStringArray $Rule.'Local Port'.replace(" ","")
    RemotePort = if($rule.Protocol -eq "TCP" -or $rule.Protocol -eq "UDP")
    {
        ListToStringArray $rule.'Remote Port'.replace(" ","") # <--- There must be no space in this string or cmdlet will fail :(
    };
		#IcmpType = ListToStringArray $Rule.IcmpType
		#DynamicTarget = if ([STRING]::IsNullOrEmpty($Rule.DynamicTarget)) { "Any" } else { $Rule.DynamicTarget }
		Program = $Rule.Program
		#Service = $Rule.Service
		#InterfaceAlias = ListToStringArray $Rule.InterfaceAlias
		InterfaceType = $Rule.'Interface Type'
		#LocalUser = $Rule.LocalUser
		#RemoteUser = $Rule.RemoteUser
		#RemoteMachine = $Rule.RemoteMachine
		#Authentication = $Rule.Authentication
		#Encryption = $Rule.Encryption
		#OverrideBlockRules = ValueToBoolean $Rule.OverrideBlockRules
	}    

	#Write-Output "Generating firewall rule `"$($Rule.DisplayName)`" ($($Rule.Name))" <--add rule name to conversion script
	# remove rule if present
	#Get-NetFirewallRule -EA SilentlyContinue -Name $Rule.Name | Remove-NetFirewallRule

	# generate new firewall rule
    try
    {
        New-NetFirewallRule @RuleSplatHash -ErrorAction Stop #| Out-Null
    }
    catch
    {
        Write-Host $_.Exception.Message -ForegroundColor Red
        closescript 1
    }
    $i = $i + 1
    Write-Host "Firewall Rule: $($rule.Displayname) created successfully!" -ForegroundColor Green
    Write-Host
}

closescript 0
