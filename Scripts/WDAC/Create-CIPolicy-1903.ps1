<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# jesse.esquivel@microsoft.com
# Create-CIPolicy.ps1
# Create MDAC CI Policy
# v1.0 Initial creation 10-31-22
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
$org = "Proseware"

##################################################################################################################
# Functions
##################################################################################################################

Function startScript()
{
    $msg = "Beginning WDAC Policy creation from reference machine: $env:COMPUTERNAME" + $VBCrLf + "@ $(get-date) via PowerShell Script."
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
        $msg = "Script execution unsuccessful, and terminated at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" `
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

Function Activate-Policy($xml, $cip)
{
    [xml]$sourceXml = Get-Content $xml
    Rename-Item $cip -NewName "$($sourceXml.SiPolicy.PolicyID).cip"
}

##################################################################################################################
# Begin Script  - please do not change unless you know what you are doing
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
startScript

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Create WDAC base policy and merge Windows default policy..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

#create new 1903+ base CI-Policy in audit mode and stop/disable VSS service
try
{
    #New-CIPolicy -MultiplePolicyFormat -Level "FilePublisher" -SpecificFileNameLevel ProductName -FilePath "$scriptDir\InitialScan.xml" -Fallback "Hash" -UserPEs 3> "C:\Windows\Temp\CIPolicy.log" -ErrorAction Stop -OmitPaths "-OmitPaths c:\Windows,'C:\Program Files\WindowsApps\',c:\windows.old\"
    Write-Host "Creating WDAC base policy..." -ForegroundColor Cyan
    New-CIPolicy -MultiplePolicyFormat -Level "Publisher" -FilePath "$scriptDir\InitialScan.xml" -Fallback "Hash" -UserPEs -OmitPaths 'C:\Windows\','C:\Program Files\WindowsApps\','c:\windows.old\' -ErrorAction Stop #3> "C:\Windows\Temp\CIPolicy.log"
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
    closeScript 1
}

#merge CI-Policy with Microsoft windows default policy, convert to binary, configure, and cleanup
try
{
    #merge and convert CI Policy for default Windows Allow
    Write-Host "Merging base policy and default Windows enforced policy..." -ForegroundColor Cyan
    Merge-CIPolicy -PolicyPaths "$scriptDir\InitialScan.xml","C:\Windows\schemas\CodeIntegrity\ExamplePolicies\DefaultWindows_Enforced.xml" -OutputFilePath "$scriptDir\$org-CI-Policy.xml" | Out-Null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
    
    #remove audit mode rule, make supplementable, etc.
    Write-Host "Configuring WDAC base policy options..." -ForegroundColor Cyan
    Set-RuleOption -FilePath "$scriptDir\$org-CI-Policy.xml" -Option 3 -Delete -Verbose #3 Enabled:Audit Mode (Default)
    Set-RuleOption -FilePath "$scriptDir\$org-CI-Policy.xml" -Option 17 -Verbose #17 Enabled:Allow Supplemental Policies
    Set-RuleOption -FilePath "$scriptDir\$org-CI-Policy.xml" -Option 10 -Verbose #10 Enabled:Boot Audit on Failure
    Set-RuleOption -FilePath "$scriptDir\$org-CI-Policy.xml" -Option 11 -Verbose #11 Disabled:Script Enforcement
    Set-RuleOption -FilePath "$scriptDir\$org-CI-Policy.xml" -Option 16 -Verbose #16 Enabled:Update Policy No Reboot
    Set-RuleOption -FilePath "$scriptDir\$org-CI-Policy.xml" -Option 13 -Verbose #13 Enabled:Managed Installer
    Write-Host "Success." -ForegroundColor Green
    Write-Host

    #convert CI Policy
    Write-Host "Converting CI policy to binary..." -ForegroundColor Cyan
    ConvertFrom-CIPolicy -xmlFilePath "$scriptDir\$org-CI-Policy.xml" -BinaryFilePath "$scriptDir\$org-CI-Policy.cip" | Out-Null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)" -ForegroundColor Red
    closeScript 1
}

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 2 - Create additional reccomended block policies..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

try
{
    <#
    create supplemental file path based rules policy
    $rules = New-CIPolicyRule -FilePathRule "C:\Program Files (x86)\Java\*"
    New-CIPolicy -FilePath "$scriptDir\$org-FilePath-CI-Policy.xml" -Rules $rules -UserPEs
    Set-RuleOption -FilePath "$scriptDir\$org-FilePath-CI-Policy.xml" -Option 3 -Delete
    Set-CIPolicyIdInfo -FilePath "$scriptDir\$org-FilePath-CI-Policy.xml" -BasePolicyToSupplementPath "$scriptDir\$org-CI-Policy.xml"
    ConvertFrom-CIPolicy -XmlFilePath "$scriptDir\$org-FilePath-CI-Policy.xml" -BinaryFilePath "$scriptDir\$org-FilePath-CI-Policy.cip"
    Move-Item -Path "$scriptDir\$org-FilePath-CI-Policy.cip" -Destination "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-FilePath-CI-Policy.cip"
    #>

    #create supplemental reccomended block rules policy
    Write-Host "Creating Microsoft Reccomended Block Rules policy and converting to binary..." -ForegroundColor Cyan
    Set-CIPolicyIdInfo -FilePath "$scriptDir\MicrosoftReccomendedBlockRules.xml" -ResetPolicyID | Out-Null
    Set-RuleOption -FilePath "$scriptDir\MicrosoftReccomendedBlockRules.xml" -Option 3 -Delete -Verbose #3 Enabled:Audit Mode (Default)
    ConvertFrom-CIPolicy -XmlFilePath "$scriptDir\MicrosoftReccomendedBlockRules.xml" -BinaryFilePath "$scriptDir\$org-ReccomendedBlockRules-CI-Policy.cip" | Out-Null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
    
    #create supplemental reccoemended driver block rules policy
    Write-Host "Creating Microsoft Reccomended Driver Block Rules policy and converting to binary..." -ForegroundColor Cyan
    Set-CIPolicyIdInfo -FilePath "$scriptDir\MicrosoftReccomendedDriverBlockRules.xml" -ResetPolicyID | Out-Null
    ConvertFrom-CIPolicy -XmlFilePath "$scriptDir\MicrosoftReccomendedDriverBlockRules.xml" -BinaryFilePath "$scriptDir\$org-ReccomendedDriverBlockRules-CI-Policy.cip" | Out-Null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
    closeScript 1
}

#rename policy files with PolicyID attribute value for activation
Activate-Policy "$scriptDir\$org-CI-Policy.xml" "$scriptDir\$org-CI-Policy.cip"
Activate-Policy "$scriptDir\MicrosoftReccomendedBlockRules.xml" "$scriptDir\$org-ReccomendedBlockRules-CI-Policy.cip"
Activate-Policy "$scriptDir\MicrosoftReccomendedDriverBlockRules.xml" "$scriptDir\$org-ReccomendedDriverBlockRules-CI-Policy.cip"

closeScript 0 
