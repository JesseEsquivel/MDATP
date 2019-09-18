<#
##################################################################################################################
#
# Microsoft
# OnboardMDATP.ps1
# jesse.esquivel@microsoft.com
# -MDT script to peform onboarding of VDI master image
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
#>

#--------------------------------------------------------------------------------------------------------------- 
# Main Routine 
#--------------------------------------------------------------------------------------------------------------- 

#Get log path. Will log to Task Sequence log folder if the script is running in a Task Sequence 
#Otherwise log to \windows\temp

try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $logPath = $tsenv.Value("LogPath")
    $scriptRoot = "$($tsenv.Value("DeployRoot"))\Scripts"
}

catch

{
    Write-Host "This script is not running in a task sequence"
    $logPath = $env:windir + "\temp"
}

$logFile = "$logPath\$($myInvocation.MyCommand).log"

#Start logging 
Start-Transcript $logFile
Write-Host "Logging to $logFile"

function Check-Key($path, $value)
{
    if(!(Test-Path $path))
    {
        New-Item $path -Value -Force
    }
}


#configure bare minimum Defender settings for signature updates
if(!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates"))
{
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -ItemType Key -Force
}

New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType string -Name DefinitionUpdateFileSharesSources -Value \\fileserver.fqdn\mdatp$\wdav-update
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType string -Name FallbackOrder -Value "FileShares|InternalDefinitionUpdateServer|MicrosoftUpdateServer|MMPC"
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType dword -Name ASSignatureDue -Value 7
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType dword -Name AVSignatureDue -Value 7
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType dword -Name ScheduleDay -Value 0
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType dword -Name SignatureUpdateInterval -Value 2
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -PropertyType dword -Name UpdateOnStartUp -Value 1

$scriptPath = "$env:systemRoot\System32\GroupPolicy\Machine\Scripts\Startup"
if(!(Test-Path $scriptPath))
{
    New-Item $scriptPath -ItemType Directory -Force
}

#copy onboarding script files
Copy-Item "$scriptRoot\Custom\Workstation\MDATP\Onboard-NonPersistentMachine.ps1" -Destination "$env:systemRoot\System32\GroupPolicy\Machine\Scripts\Startup" -Force
Copy-Item "$scriptRoot\Custom\Workstation\MDATP\WindowsDefenderATPOnboardingScript.cmd" -Destination "$env:systemRoot\System32\GroupPolicy\Machine\Scripts\Startup" -Force
Copy-Item "$scriptRoot\Custom\Workstation\MDATP\psscripts.ini" -Destination "$env:systemRoot\System32\GroupPolicy\Machine\scripts" -Force

#create startup script keys in registry
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Startup\0\0",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Startup\0\0" |
ForEach-Object {
    if(!(Test-Path $_))
    {
        New-Item -Path $_ -Force
    }
}

#place required entries for startup script
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Startup\0",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Startup\0" |
ForEach-Object {
    New-ItemProperty -Path $_ -Name DisplayName -PropertyType string -Value "Local Group Policy"
    New-ItemProperty -Path $_ -Name FileSysPath -PropertyType string -Value "$env:systemRoot\System32\GroupPolicy\Machine"
    New-ItemProperty -Path $_ -Name GPO-ID -PropertyType string -Value "LocalGPO"
    New-ItemProperty -Path $_ -Name GPOName -PropertyType string -Value "Local Group Policy"
    New-ItemProperty -Path $_ -Name SOM-ID -PropertyType string -Value "Local"
    New-ItemProperty -Path $_ -Name PSScriptOrder -PropertyType dword -Value 1
}

#place required entries for startup script
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\Startup\0\0",
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Startup\0\0" |
ForEach-Object {
    New-ItemProperty -Path $_ -Name Script -PropertyType string -Value "Onboard-NonPersistentMachine.ps1"
    New-ItemProperty -Path $_ -Name Parameters -PropertyType string -Value ""
    New-ItemProperty -Path $_ -Name IsPowershell -PropertyType string -Value 1
    New-ItemProperty -Path $_ -Name ExecTime -PropertyType qword -Value 0
}

#Stop logging 
Stop-Transcript