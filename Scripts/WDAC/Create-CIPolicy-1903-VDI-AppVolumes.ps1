<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# jesse.esquivel@microsoft.com
# Create-CIPolicy-1903-VDI.ps1
# Create MDAC CI Policy
# v1.0 Initial creation 11-9-22
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
$scriptRoot = "Z:\Scripts"
$logFile = "C:\Windows\Temp\$($myInvocation.MyCommand).log"
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

Start-Transcript $logFile
Write-Host "Logging to $logFile"
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
startScript

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Phase 1 - Create WDAC base policy and merge Windows default policy..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

#enable and start VSS service to get file hashes and copy HPFiles to master
try
{
    Set-Service -Name VSS -StartupType Manual -ErrorAction Stop
    Start-Service -Name VSS -ErrorAction Stop
    Copy-Item -Path "$scriptroot\Custom\VDI\MDAC\HPFiles" -Destination C:\HPFiles -Recurse -Force -ErrorAction Stop
}
catch
{
    Write-Host "Failed to start VSS service: $($_.Exception.Message)"
}

#create new 1903+ base CI-Policy in audit mode and stop/disable VSS service
try
{
    Write-Host "Creating WDAC base policy..." -ForegroundColor Cyan
    New-CIPolicy -MultiplePolicyFormat -Level "Publisher" -FilePath "C:\Windows\System32\CodeIntegrity\InitialScan.xml" -Fallback "Hash" -UserPEs -OmitPaths 'C:\Windows\','C:\Program Files\WindowsApps\','c:\windows.old\' -ErrorAction Stop
    Stop-Service -Name VSS -Force -ErrorAction Stop
    Set-Service -Name VSS -StartupType Disabled -ErrorAction Stop
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
    #9/5/24 - create policy xml files for all vmware appvolumes virtualized apps
    $appVolMountPoints = Get-ChildItem -Path "C:\SnapVolumesTemp\MountPoints"
    $TargetFileName = $appVolMountPoints.Name -replace "^." -replace ".$"
    foreach($appVolMountPoint in $appVolMountPoints)
    {
        New-CIPolicy -ScanPath "$($appvolMountPoint.FullName)" -PathToCatroot "$($appvolMountPoint.FullName)" -MultiplePolicyFormat -Level "Publisher" -FilePath "C:\Windows\System32\CodeIntegrity\$($TargetFileName)-InitialScan.xml" -Fallback "Hash" -UserPEs -ErrorAction Stop
    }
    
    #9/5/24 - merge and convert CI Policies for initial scan, default Windows enforced, and appvolumes apps
    Write-Host "Merging base policy, default Windows enforced policy, and appvolume apps policies..." -ForegroundColor Cyan
    Copy-Item -Path "C:\Windows\schemas\CodeIntegrity\ExamplePolicies\DefaultWindows_Enforced.xml" -Destination "C:\Windows\System32\CodeIntegrity" -Force
    $Xmls = @{PolicyPaths = @($($(Get-ChildItem -Path "C:\Windows\System32\CodeIntegrity\*.xml").FullName))}
    Merge-CIPolicy @Xmls -OutputFilePath "C:\Windows\System32\CodeIntegrity\$org-CI-Policy.xml" -Verbose
    Write-Host "Success." -ForegroundColor Green
    Write-Host
    
    #remove audit mode rule, make supplementable, etc.
    Write-Host "Configuring WDAC base policy options..." -ForegroundColor Cyan
    Set-RuleOption -FilePath "C:\Windows\System32\CodeIntegrity\$org-CI-Policy.xml" -Option 3 -Delete -Verbose #3 Enabled:Audit Mode (Default)
    Set-RuleOption -FilePath "C:\windows\system32\CodeIntegrity\$org-CI-Policy.xml" -Option 17 -Verbose #17 Enabled:Allow Supplemental Policies
    Set-RuleOption -FilePath "C:\windows\system32\CodeIntegrity\$org-CI-Policy.xml" -Option 10 -Verbose #10 Enabled:Boot Audit on Failure
    Set-RuleOption -FilePath "C:\windows\system32\CodeIntegrity\$org-CI-Policy.xml" -Option 11 -Verbose #11 Disabled:Script Enforcement
    Set-RuleOption -FilePath "C:\windows\system32\CodeIntegrity\$org-CI-Policy.xml" -Option 16 -Verbose #16 Enabled:Update Policy No Reboot
    Set-CIPolicyIdInfo -FilePath "C:\windows\system32\CodeIntegrity\$org-CI-Policy.xml" -PolicyName "$org-CI-Policy" -PolicyId "$(Get-Date -UFormat %d%m%Y)"
    Write-Host "Success." -ForegroundColor Green
    Write-Host

    #convert CI Policy
    Write-Host "Converting CI policy to binary..." -ForegroundColor Cyan
    ConvertFrom-CIPolicy -xmlFilePath "C:\Windows\System32\CodeIntegrity\$org-CI-Policy.xml" -BinaryFilePath "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-CI-Policy.cip"
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
    #create supplemental reccomended block rules policy
    Write-Host "Creating Microsoft Reccomended Block Rules policy and converting to binary..." -ForegroundColor Cyan
    Set-CIPolicyIdInfo -FilePath "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedBlockRules.xml" -ResetPolicyID | Out-Null
    Set-RuleOption -FilePath "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedBlockRules.xml" -Option 3 -Delete -Verbose #3 Enabled:Audit Mode (Default)
    ConvertFrom-CIPolicy -XmlFilePath "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedBlockRules.xml" -BinaryFilePath "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-ReccomendedBlockRules-CI-Policy.cip" | Out-Null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
    
    #create supplemental reccomended driver block rules policy
    Write-Host "Creating Microsoft Reccomended Driver Block Rules policy and converting to binary..." -ForegroundColor Cyan
    Set-CIPolicyIdInfo -FilePath "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedDriverBlockRules.xml" -ResetPolicyID | Out-Null
    ConvertFrom-CIPolicy -XmlFilePath "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedDriverBlockRules.xml" -BinaryFilePath "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-ReccomendedDriverBlockRules-CI-Policy.cip" | Out-Null
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
    closeScript 1
}

    
#backup generated CI Policies to deployment share
Copy-Item -Path "C:\Windows\system32\CodeIntegrity\*.xml" -Destination "$scriptroot\Custom\VDI\MDAC" -Force
        
#rename policy files with PolicyID attribute value for activation
Activate-Policy "C:\Windows\System32\CodeIntegrity\$org-CI-Policy.xml" "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-CI-Policy.cip"
Activate-Policy "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedBlockRules.xml" "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-ReccomendedBlockRules-CI-Policy.cip"
Activate-Policy "$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedDriverBlockRules.xml" "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\$org-ReccomendedDriverBlockRules-CI-Policy.cip"

#clean up
Remove-Item -Path "C:\Windows\system32\CodeIntegrity\*.xml" -Force
Remove-Item -Path "C:\HPFiles" -Recurse -Force

closeScript 0
