<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# jesse.esquivel@microsoft.com
# Create-CIPolicy.ps1
# Create MDAC CI Policy for VDI as part of MDT task sequence
# v1.0 Initial creation 10-28-19
# Expiremental - CAUTION as this will break your task sequence if you enforce MDAC and reboot the machine
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

try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
}
catch
{
    Write-Host "This script is not running in a task sequence"
    $logPath = $env:windir + "\temp"
}

$scriptRoot = "$($tsenv.Value("DeployRoot"))\Scripts"
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
    Copy-Item -Path "Z:\Scripts\Custom\Workstation\MDAC\HPFiles" -Destination C:\HPFiles -Recurse -Force -ErrorAction Stop
}
catch
{
    Write-Host "Failed to start VSS service: $($_.Exception.Message)"
}

#create new CI-Policy in audit mode and stop/disable VSS service
try
{
    New-CIPolicy -Level "Publisher" -FilePath "C:\Windows\System32\CodeIntegrity\InitialScan.xml" -Fallback "Hash" -UserPEs 3> "C:\Windows\Temp\CIPolicy.log" -ErrorAction Stop
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
    Merge-CIPolicy -PolicyPaths "C:\Windows\System32\CodeIntegrity\InitialScan.xml","$scriptroot\Custom\Workstation\MDAC\MicrosoftReccomendedBlockRules.xml" -OutputFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml"
    
    #remove audit mode rule
    Set-RuleOption -FilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Option 3 -Delete
    
    #convert CI Policy
    ConvertFrom-CIPolicy -xmlFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -BinaryFilePath "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.bin"
    
    #backup CI Policies to deployment share
    Copy-Item -Path "C:\Windows\system32\CodeIntegrity\InitialScan.xml" -Destination "$scriptroot\Custom\Workstation\MDAC" -Force
    Copy-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Destination "$scriptroot\Custom\Workstation\MDAC" -Force
        
    #enforce CI policy - you will want this if building a non persistent VDI Master - Use caution here!
    Rename-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.bin" -NewName "C:\Windows\System32\CodeIntegrity\SIPolicy.p7b" -Force
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -ItemType Key -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -PropertyType string -Name ConfigCIPolicyFilePath -Value "C:\Windows\System32\CodeIntegrity\SIPolicy.p7b"
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -PropertyType dword -Name DeployConfigCIPolicy -Value 1

    #clean up
    Remove-Item -Path "C:\Windows\system32\CodeIntegrity\InitialScan.xml" -Force
    Remove-Item -Path "C:\Windows\System32\CodeIntegrity\ORGANIZATION-CI-Policy.xml" -Force
    Remove-Item -Path "C:\HPFiles" -Recurse -Force
}
catch
{
    Write-Host "A fatal exception occurred: $($_.Exception.Message)"
}

#Stop logging 
Stop-Transcript