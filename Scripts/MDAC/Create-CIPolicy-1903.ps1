<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# jesse.esquivel@microsoft.com
# Create-CIPolicy.ps1
# Create MDAC CI Policy for VDI as part of MDT task sequence
# v1.0 Initial creation 10-28-19
# v1.1 updated for TS for 1909+ 03-11-21
# V1.2 updated to include java COM object add in whitelisting
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

$scriptRoot = "Z:\Scripts"
$logFile = "C:\Windows\Temp\$($myInvocation.MyCommand).log"

##################################################################################################################
# Begin Script  - please do not change unless you know what you are doing
##################################################################################################################

Start-Transcript $logFile
Write-Host "Logging to $logFile"

#enable and start VSS service to get file hashes and copy HPFiles to master
try
{
    Set-Service -Name VSS -StartupType Manual -ErrorAction Stop
    Start-Service -Name VSS -ErrorAction Stop
    #use this if you need to copy PEs or other files to the machine that need to be whitelisted
    Copy-Item -Path "$scriptroot\Custom\VDI\MDAC\HPFiles" -Destination C:\HPFiles -Recurse -Force -ErrorAction Stop
}
catch
{
    Write-Host "Failed to start VSS service: $($_.Exception.Message)"
}

#create new 1903+ base CI-Policy in audit mode and stop/disable VSS service
try
{
    New-CIPolicy -MultiplePolicyFormat -Level "Publisher" -FilePath "C:\Windows\System32\CodeIntegrity\InitialScan.xml" -Fallback "Hash" -UserPEs 3> "C:\Windows\Temp\CIPolicy.log" -ErrorAction Stop
    Stop-Service -Name VSS -Force -ErrorAction Stop
    Set-Service -Name VSS -StartupType Disabled -ErrorAction Stop
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
}

#merge CI-Policy with Microsoft reccomended block policy, convert to binary, enable, and cleanup
try
{
    #merge and convert CI Policy
    Merge-CIPolicy -PolicyPaths "C:\Windows\System32\CodeIntegrity\InitialScan.xml","$scriptroot\Custom\VDI\MDAC\MicrosoftReccomendedBlockRules.xml" -OutputFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml"
    
    #remove audit mode rule, make supplementable
    Set-RuleOption -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Option 3 -Delete
    Set-RuleOption -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Option 17

    #add allow COM Objects for Java add-in in IE
    Set-CIPolicySetting -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Key "{08B0E5C0-4FCB-11CF-AAA5-00401C608501}" -Provider "IE" -Value true -ValueName "EnterpriseDefinedClsId" -ValueType Boolean
    Set-CIPolicySetting -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Key "{761497BB-D6F0-462C-B6EB-D4DAF1D92D43}" -Provider "IE" -Value true -ValueName "EnterpriseDefinedClsId" -ValueType Boolean
    Set-CIPolicySetting -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Key "{DBC80044-A445-435B-BC74-9C25C1C588A9}" -Provider "IE" -Value true -ValueName "EnterpriseDefinedClsId" -ValueType Boolean
    Set-CIPolicySetting -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Key "{A500A600-5B69-4011-AC50-5ACB97D04B72}" -Provider "IE" -Value true -ValueName "EnterpriseDefinedClsId" -ValueType Boolean
    Set-CIPolicySetting -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Key "{8ad9c840-044e-11d1-b3e9-00805f499d93}" -Provider "IE" -Value true -ValueName "EnterpriseDefinedClsId" -ValueType Boolean
    Set-CIPolicySetting -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Key "{00000000-0000-0000-0000-000000000000}" -Provider "IE" -Value true -ValueName "EnterpriseDefinedClsId" -ValueType Boolean
    
    #convert CI Policy
    ConvertFrom-CIPolicy -xmlFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -BinaryFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.cip"
    
    #backup CI Policies to deployment share
    Copy-Item -Path "C:\Windows\system32\CodeIntegrity\InitialScan.xml" -Destination "$scriptroot\Custom\VDI\MDAC" -Force
    Copy-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Destination "$scriptroot\Custom\VDI\MDAC" -Force
        
    #enforce CI policy
    Move-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.cip" -Destination "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\ORGANIZATION-CI-Policy.cip"
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
}

try
{
    #create supplemental file path based rules policy
    $rules = New-CIPolicyRule -FilePathRule "C:\Program Files (x86)\Java\*"
    New-CIPolicy -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-FilePath-CI-Policy.xml" -Rules $rules -UserPEs
    Set-RuleOption -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-FilePath-CI-Policy.xml" -Option 3 -Delete
    Set-CIPolicyIdInfo -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-FilePath-CI-Policy.xml" -BasePolicyToSupplementPath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml"
    ConvertFrom-CIPolicy -XmlFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-FilePath-CI-Policy.xml" -BinaryFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-FilePath-CI-Policy.cip"
    Move-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-FilePath-CI-Policy.cip" -Destination "C:\Windows\System32\CodeIntegrity\CiPolicies\Active\ORGANIZATION-FilePath-CI-Policy.cip"

    #clean up
    #Remove-Item -Path "C:\Windows\system32\CodeIntegrity\InitialScan.xml" -Force
    #Remove-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Force
    Remove-Item -Path "C:\HPFiles" -Recurse -Force
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
}

#Stop logging 
Stop-Transcript
