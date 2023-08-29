<#
##################################################################################################################
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com
# DefenderEPP.ps1
# v1.0 - 6/12/2023
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

##################################################################################################################
# Menu art
##################################################################################################################

$ninjaCat = @"

                                                            .*//////////////.
                                                           .%@@@&&@@@@@@@@@@@@*   ,(%%#*
                                            ,%&&%*        /@@@@(#&&(((#&@@&/#@@@@@@@&.
                                           *@@&&@@@@@@@*&@@(((((((#%&&&&&&@@@@%((#&@@/
                                           .&@@%*#@@&/#&@@@@&(*/((((#%%%%%%%%%&@@%(&@@@@@@@(
                                             (@@&(,**   /((%&, .(((#%#(((((((##&@%(&@&(*/%@@/
                                             (@@&/*,.   .*#&&@@@@@@#((((((((((((##(&%**/@@@@(
                                            *@@@@&, ,      *#%&&&&&%##(//////((((#&@%**/@@*
                                           ,&@@&*  (&.   (&&%%(****(%&&&%%%#(((((&@@%**/@@&.
                                          /@@&*          (&(*****(****#&&((((%&@@@#**/@@&.
                                       ,(#&@&,     ....  /****%%#***%&&%((#%&&&&&%**/&@@/
                                   .,(&@@@@@@(    .%@@&*  #&(***(/***#&(.,((/....     .#@@&,
                               *%@@@@@@@@%####&&%&@@@@@@*  #******%&(. ,((/. ..       ,&@&.
                         *(%%&@@@@&%#((/((((#&@@@@@@@@@@@*  *%//%&%, ./(((/. ..        (@@(
                   ,#&&&@@@@@@@%(//////////(&@@@@@@@@@@@@@*   .(%%/,.............        (@@(
                 *&@@@@@@&(//////////////(#&&@@@@@%////////.               .,..          (@@(
             /&@@@@@%/**//***///////////&&%@@@@@@%.                       *            (@@(
           ,&@@@%#%%/**************////%@@@@@@@@@%. .%@@@@@*            /&@@#            (@@(
        *%@@@@%***********************/&@@@@@@@@@%. .%@@@@&,   .,,,*(%&@@@@@(     ,%*    (@@(
      .&@@@#/,,,**********************//#@@@@@@%.  ,&@&*   *&@@@@@@@@@@@&,    *&@@@&.  #@@(
     .&@@%*,,,,,,,,,,,,********************(//(&@@&* .%@,   (@@@@@@@@@@@@(    (&@@@@#  .%@@#
     /@@&*,,,,,,,,,,,,,,,,,,*******************/%#%&@@@@@#.   (&&&@@@@@&,  .#@@@@@@/  *&@@/
     (@@&,,,,,,,,,,,,,,,,,,,,,,,,,******************%@@@@@@#.    *&@@@(  ,&@@@@@@&,  (@@&,
     (@@&,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,************/&@@@@@@@@%###%@@@@/  *@@@@@@#  .%@@#
     *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@&&&@@@/
      .#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,

"@

$menuArt = @"

                                  __________________________________________________
                                  |                                                 |
                                  | HELLO                                           |
                                  |                                                 |
                                  | A STRANGE GAME.                                 |
                                  | THE ONLY LOSING MOVE IS                         |
                                  | NOT TO PLAY.                                    |
                                  |                                                 |
                                  | HOW ABOUT A NICE GAME OF CHESS?                 |
                                  |                                                 |
                                  |  1.  CHECK PLATFORM/ENGINE                      |
                                  |  2.  CHECK TAMPER PROTECTION                    |
                                  |  3.  CONFIGURE EPP OPTIMALLY                    |
                                  |  4.  REVERT EPP OPTIMAL CONFIG                  |
                                  |  5.  REMOVE AV EXCLUSIONS                       |                                  
                                  |                                                 |
                                  |  Q.  Quit'                                      |
                                  |                                                 |
                                  |                                                 |
                                  |_________________________________________________|

"@

$base64File = "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
BYWFQTMjG/rFRQWNAyKiweNBUUFsWFWRUUb/8VFkGhUUFvxUUTEFNRTMuOTguMgA
AAAA//uyYAAP8AAAaQAAAAgAAA0gAAABAAABpAAAACAAADSAAAAETEFNRTMuOTgu
MgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAA
"

##################################################################################################################
# Functions - please do not change these unless you know what you are doing
##################################################################################################################

Function closeScript($exitCode)
{
    if($exitCode -ne 0)
    {
        Write-Host
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Script execution unsuccessful, and terminted at $(get-date)" + $VBCrLf `
        + "Examine the script output and previous events logged to resolve errors."
        Write-Host $msg -ForegroundColor Red
        Write-Host "######################################################################################" -ForegroundColor Yellow
    }
    else
    {
        Write-Host "Bye!"
    }
    exit $exitCode
}
function Check-TP()
{
    $tp = Get-MpComputerStatus | select IsTamperProtected, TamperProtectionSource
    if($tp.IsTamperProtected -eq "True")
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Checking Tamper Protection State" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        Write-Host "Tamper Protection state" -ForegroundColor Cyan
        Write-Host "IsTamperProtected: $($tp.IsTamperProtected)" -ForegroundColor Green
        Write-Host
        Write-Host "Tamper Protection Source" -ForegroundColor Cyan
        Write-Host $tp.TamperProtectionSource -ForegroundColor Green
        Write-Host
    }
    else
    {
        Write-Host "Tamper Protection state:" -ForegroundColor Cyan
        Write-Host "IsTamperProtected: $($tp.IsTamperProtected)" -ForegroundColor Red
        Write-Host "Enable Tamper Protection on this machine via Intune or the M365D Portal" -ForegroundColor Red
        closeScript 1
    }
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Finished Checking Tamper Protection State" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
}

Function Check-Platform()
{
    Write-Host
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Checking Defender Platform/Engine/Signature State" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
    try
    {
        Write-Host "Fetching latest platform/engine version from published xml..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Method Get -Uri "https://www.microsoft.com/security/encyclopedia/adlpackages.aspx?action=info" -useBasicParsing -ErrorAction Stop
        $latestPlatform = ([xml]$response.Content).versions.platform
        $latestEngine = ([xml]$response.Content).versions.engine
        Write-Host "Success." -ForegroundColor Green
        Write-Host
    }
    catch
    {
        Write-Host "Failed to check latest platform/engine versions from URL." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        closeScript 1
    }

    Write-Host "Comparing latest platform/engine against machines current versions..." -ForegroundColor Cyan
    $result = Get-MpComputerStatus | select AMRunningMode,AMEngineVersion,AMProductVersion,AntispywareSignatureLastUpdated
    $return = [pscustomobject]@{
        isMDEReady = ([version]$($result.AMEngineVersion) -ge $latestEngine)`
            -and ([version]$($result.AMProductVersion) -ge $latestPlatform)`
            -and ($result.AMRunningMode -like "passive" -or $result.AMRunningMode -like "EDR Block"`
            -or $result.AMRunningMode -like "Normal")`
            -and ($result.AntispywareSignatureLastUpdated -ge $result.AntispywareSignatureLastUpdated.AddDays(-1))
        details = [pscustomobject]@{
            AMEngineVersion = $result.AMEngineVersion
            AMProductVersion = $result.AMProductVersion
            AMRunningMode = $result.AMRunningMode
            AntispywareSignatureLastUpdated = $result.AntispywareSignatureLastUpdated
            }
    }
    
    if($return.isMDEReady -eq $False)
    {
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        if([version]$($result.AMEngineVersion) -lt $latestEngine)
        {
            Write-Host "AMEngineVersion (Engine): $($result.AMEngineVersion)" -ForegroundColor Red
        }
        else
        {
            Write-Host "AMEngineVersion (Engine): $($result.AMEngineVersion)" -ForegroundColor Green
        }
        if([version]$($result.AMProductVersion) -lt $latestPlatform)
        {
            Write-Host "AMProductVersion (Platform): $($result.AMProductVersion)" -ForegroundColor Red
        }
        else
        {
            Write-Host "AMProductVersion (Platform): $($result.AMProductVersion)" -ForegroundColor Green
        }
        if($result.AntispywareSignatureLastUpdated -ge $result.AntispywareSignatureLastUpdated.AddDays(-1))
        {
            Write-Host "AntispywareSignatureLastUpdated: $($result.AntispywareSignatureLastUpdated)" -ForegroundColor Green
        }
        else
        {
            Write-Host "AntispywareSignatureLastUpdated: $($result.AntispywareSignatureLastUpdated)" -ForegroundColor Red
        }
        Write-Host
        Write-Host "**Please run Windows update to resolve**" -ForegroundColor Yellow
        Write-Host
    }
    else
    {
        Write-Host "MDE is up to date: $($return.isMDEReady)" -ForegroundColor Green
        Write-Host $return.details -ForegroundColor Green
        Write-Host
    }
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Finished checking Defender Platform/Engine/Signature State" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
}

function EPP-Harden()
{
    Write-Host
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Configuring Defender EPP Optimally" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
    try
    {
        #Defender AV Engine
        Write-Host "Setting CloudBlockLevel to 0..." -ForegroundColor Cyan
        Set-MpPreference -CloudBlockLevel 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting MAPSReporting to 2..." -ForegroundColor Cyan
        Set-MpPreference -MAPSReporting 2
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting SubmitSamplesConsent to 3..." -ForegroundColor Cyan
        Set-MpPreference -SubmitSamplesConsent 3
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableBlockAtFirstSeen to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableBlockAtFirstSeen 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting PUAProtection to 1..." -ForegroundColor Cyan
        Set-MpPreference -PUAProtection 1
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting EnableControlledFolderAccess to 1..." -ForegroundColor Cyan
        Set-MpPreference -EnableControlledFolderAccess 1
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting EnableNetworkProtection to 1..." -ForegroundColor Cyan
        Set-MpPreference -EnableNetworkProtection 1
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableRealtimeMonitoring to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableRealtimeMonitoring 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableBehaviorMonitoring to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableBehaviorMonitoring 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableIOAVProtection to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableIOAVProtection 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableScriptScanning to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableScriptScanning 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableRemovableDriveScanning to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableRemovableDriveScanning 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableArchiveScanning to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableArchiveScanning 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableEmailScanning to 0..." -ForegroundColor Cyan
        Set-MpPreference -DisableEmailScanning 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        if((Get-WMIObject win32_operatingsystem).Name -Like "*Server*" -or (Get-WMIObject win32_operatingsystem).Name -Like "*MultiSession*")
        {
            Write-Host "Server or AVD found...setting AllowNetworkProtectionOnWinServer to 1..." -ForegroundColor Cyan
            Set-MpPreference AllowNetworkProtectionOnWinServer 1
            Write-Host "Success." -ForegroundColor Green
            Write-Host
            Write-Host "Server or AVD found...setting AllowDatagramProcessingOnWinServer to 1..." -ForegroundColor Cyan
            Set-MpPreference -AllowDatagramProcessingOnWinServer 1
            Write-Host "Success." -ForegroundColor Green
            Write-Host
        }
        elseif((Get-WMIObject win32_operatingsystem).Name -Like "*Server 2012 R2*" -or (Get-WMIObject win32_operatingsystem).Name -Like "*Server 2016*")
        {
            Write-Host "Server 2012 R2 or Server 2016 found...setting AllowNetworkProtectionDownLevel to 1..." -ForegroundColor Cyan
            Set-MpPreference -AllowNetworkProtectionDownLevel 1
            Write-Host "Success." -ForegroundColor Green
            Write-Host
        }

        #ASR Rules
        Write-Host "Setting ASR Rule `"Block abuse of exploited vulnerable signed drivers`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 56a863a9-875e-4185-98a7-b882c64b5ce5 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Adobe Reader from creating child processes`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block all Office applications from creating child processes`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block credential stealing from the Windows local security authority subsystem`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block executable content from email client and webmail`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids be9ba2d9-53ea-4cdc-84e5-9b1eeee46550 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block executable files from running unless they meet a prevalence, age, or trusted list criterion`" to Audit mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-cd74-433a-b99e-2ecdc07bfc25 -AttackSurfaceReductionRules_Actions AuditMode
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"BBlock JavaScript or VBScript from launching downloaded executable content`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids d3e037e1-3eb8-44c8-a917-57927947596d -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Office applications from creating executable content`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 3b576869-a4ec-4529-8536-b80a7769e899 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Office applications from injecting code into other processes`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Office communication application from creating child processes`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 26190899-1602-49e8-8b27-eb1d0a1ce869 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block persistence through WMI event subscription`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids e6db77e5-3df2-4cf1-b95a-636979351e5b -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block process creations originating from PSExec and WMI commands`" to Audit mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids d1e49aac-8f56-4280-b9ba-993a6d77406c -AttackSurfaceReductionRules_Actions AuditMode
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block untrusted and unsigned processes that run from USB`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Win32 API calls from Office macro`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Use advanced protection against ransomware`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids c1db55ab-c21a-4637-bb3f-a12568109d35 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Defender is now configured Optimally for POC/Assessment." -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
    }
    catch
    {
        Write-Host "Failed to configure EPP settings" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        closeScript 1
    }
}

function EPP-Defaults()
{
    Write-Host
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Setting Defender EPP defaults" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
    try
    {
        #Defender AV Engine
        Write-Host "Setting CloudBlockLevel to 0..." -ForegroundColor Cyan
        Set-MpPreference -CloudBlockLevel 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting MAPSReporting to 0..." -ForegroundColor Cyan
        Set-MpPreference -MAPSReporting 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting SubmitSamplesConsent to 1..." -ForegroundColor Cyan
        Set-MpPreference -SubmitSamplesConsent 1
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting DisableBlockAtFirstSeen to 1..." -ForegroundColor Cyan
        Set-MpPreference -DisableBlockAtFirstSeen 1
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting PUAProtection to 0..." -ForegroundColor Cyan
        Set-MpPreference -PUAProtection 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting EnableControlledFolderAccess to 0..." -ForegroundColor Cyan
        Set-MpPreference -EnableControlledFolderAccess 0
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting EnableNetworkProtection to 2..." -ForegroundColor Cyan
        Set-MpPreference -EnableNetworkProtection 2
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        if((Get-WMIObject win32_operatingsystem).Name -Like "*Server*" -or (Get-WMIObject win32_operatingsystem).Name -Like "*MultiSession*")
        {
            Write-Host "Server or AVD found...setting AllowNetworkProtectionOnWinServer to 0..." -ForegroundColor Cyan
            Set-MpPreference AllowNetworkProtectionOnWinServer 0
            Write-Host "Success." -ForegroundColor Green
            Write-Host
            Write-Host "Server or AVD found...setting AllowDatagramProcessingOnWinServer to 0..." -ForegroundColor Cyan
            Set-MpPreference -AllowDatagramProcessingOnWinServer 0
            Write-Host "Success." -ForegroundColor Green
            Write-Host
        }
        elseif((Get-WMIObject win32_operatingsystem).Name -Like "*Server 2012 R2*" -or (Get-WMIObject win32_operatingsystem).Name -Like "*Server 2016*")
        {
            Write-Host "Server 2012 R2 or Server 2016 found...setting AllowNetworkProtectionDownLevel to 0..." -ForegroundColor Cyan
            Set-MpPreference -AllowNetworkProtectionDownLevel 0
            Write-Host "Success." -ForegroundColor Green
            Write-Host
        }

        #ASR Rules
        Write-Host "Setting ASR Rule `"Block abuse of exploited vulnerable signed drivers`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 56a863a9-875e-4185-98a7-b882c64b5ce5 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Adobe Reader from creating child processes`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block all Office applications from creating child processes`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids d4f940ab-401b-4efc-aadc-ad5f3c50688a -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block credential stealing from the Windows local security authority subsystem`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block executable content from email client and webmail`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids be9ba2d9-53ea-4cdc-84e5-9b1eeee46550 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block executable files from running unless they meet a prevalence, age, or trusted list criterion`" to Audit mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-cd74-433a-b99e-2ecdc07bfc25 -AttackSurfaceReductionRules_Actions AuditMode
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"BBlock JavaScript or VBScript from launching downloaded executable content`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids d3e037e1-3eb8-44c8-a917-57927947596d -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Office applications from creating executable content`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 3b576869-a4ec-4529-8536-b80a7769e899 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Office applications from injecting code into other processes`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Office communication application from creating child processes`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 26190899-1602-49e8-8b27-eb1d0a1ce869 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block persistence through WMI event subscription`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids e6db77e5-3df2-4cf1-b95a-636979351e5b -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block process creations originating from PSExec and WMI commands`" to Audit mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids d1e49aac-8f56-4280-b9ba-993a6d77406c -AttackSurfaceReductionRules_Actions AuditMode
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block untrusted and unsigned processes that run from USB`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block Win32 API calls from Office macro`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Use advanced protection against ransomware`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids c1db55ab-c21a-4637-bb3f-a12568109d35 -AttackSurfaceReductionRules_Actions Disabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Defender is now set to EPP defaults." -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
    }
    catch
    {
        Write-Host "Failed to revert EPP settings" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        closeScript 1
    }
}

function EPP-Allow()
{
    Write-Host
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Configuring Defender for EDR only alerting" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host

    try
    {
   
        #Defender AV Engine
        Write-Host "Disabling Behavior Monitoring..." -ForegroundColor Cyan
        Set-MpPreference -DisableBehaviorMonitoring $true
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Disabling IOAV Protection..." -ForegroundColor Cyan
        Set-MpPreference -DisableIOAVProtection $true
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Disabling Email Scanning..." -ForegroundColor Cyan
        Set-MpPreference -DisableEmailScanning $true
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Disabling RealTime Monitoring..." -ForegroundColor Cyan
        Set-MpPreference -DisableRealtimeMonitoring $true
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Disabling Script Scanning..." -ForegroundColor Cyan
        Set-MpPreference -DisableScriptScanning $true
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        #Set-MpPreference DisableInboundConnectionFiltering $true
    }
    catch
    {
        Write-Host "Failed to configure EPP Allow settings" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        closeScript 1
    }
}

function EPP-AllowRevert()
{
    Write-Host
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Configuring Defender, reverting EDR only alerting" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host

    try
    {
   
        #Defender AV Engine
        Write-Host "Enabling Behavior Monitoring..." -ForegroundColor Cyan
        Set-MpPreference -DisableBehaviorMonitoring $false
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Enabling IOAV Protection..." -ForegroundColor Cyan
        Set-MpPreference -DisableIOAVProtection $false
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Enabling Email Scanning..." -ForegroundColor Cyan
        Set-MpPreference -DisableEmailScanning $false
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Enabling RealTime Monitoring..." -ForegroundColor Cyan
        Set-MpPreference -DisableRealtimeMonitoring $false
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Enabling Script Scanning..." -ForegroundColor Cyan
        Set-MpPreference -DisableScriptScanning $false
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        #Set-MpPreference DisableInboundConnectionFiltering $true
    }
    catch
    {
        Write-Host "Failed to revert EPP Allow settings" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        closeScript 1
    }
}

function Remove-AVExclusions()
{
    $AV = Get-MpPreference
    if ($AV.ExclusionPath -ne $NULL)
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Processing AV ExclusionPath entry removals" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        foreach ($i in $AV.ExclusionPath)
        {
            try
            {
                Write-Host "Removing ExclusionPath: $i" -ForegroundColor Cyan
                Remove-MpPreference -ExclusionPath $i
                Write-Host "Success." -ForegroundColor Green
                Write-Host
            }
            catch
            {
                Write-Host "Failed to remove ExclusionPath $i" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                closeScript 1
            }
        }
        Write-Host("Total ExclusionPath entries deleted:", $AV.ExclusionPath.Count) -ForegroundColor Cyan
        Write-Host
    }
    else
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Processing AV ExclusionPath entry removals" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        Write-Host "No ExclusionPath entries present. Skipping..." -ForegroundColor Green
    }

    if ($AV.ExclusionProcess -ne $NULL)
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Removing the following AV ExclusionProcess entries" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        foreach ($i in $AV.ExclusionProcess)
        {
            try
            {
                Write-Host "Removing Exclusion Process: $i" -ForegroundColor Cyan
                Remove-MpPreference -ExclusionProcess $i
                Write-Host "Success." -ForegroundColor Green
                Write-Host
            }
            catch
            {
                Write-Host "Failed to remove ExclusionProcess $i" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                closeScript 1
            }
        }
        Write-Host("Total ExclusionProcess entries deleted:", $AV.ExclusionProcess.Count) -ForegroundColor Cyan
        Write-Host
    }
    else
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Processing AV ExclusionProcess entry removals" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        Write-Host "No ExclusionProcess entries present. Skipping..." -ForegroundColor Green
    }

    if ($AV.ExclusionExtension -ne $NULL)
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Removing the following AV ExclusionExtension entries" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        foreach ($i in $AV.ExclusionExtension)
        {
            try
            {
                Write-Host "Removing Exclusion extension: $i" -ForegroundColor Cyan
                Remove-MpPreference -ExclusionExtension $i
                Write-Host "Success." -ForegroundColor Green
                Write-Host
            }
            catch
            {
                Write-Host "Failed to remove ExclusionExtension $i" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                closeScript 1
            }
        }
        Write-Host("Total ExclusionExtension entries deleted:", $AV.ExclusionExtension.Count) -ForegroundColor Cyan
        Write-Host
    }
    else
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Processing AV ExclusionExtension entry removals" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        Write-Host "No ExclusionExtension entries present. Skipping..." -ForegroundColor Green
    }
    <#
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Finished processing AV Exclusion entry removal" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
    #>
    if ($AV.ExclusionIpAddress -ne $NULL)
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Removing the following AV ExclusionIpAddress entries" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        foreach ($i in $AV.ExclusionIpAddress)
        {
            try
            {
                Write-Host "Removing Exclusion IpAddress: $i" -ForegroundColor Cyan
                Remove-MpPreference -ExclusionIpAddress $i
                Write-Host "Success." -ForegroundColor Green
                Write-Host
            }
            catch
            {
                Write-Host "Failed to remove ExclusionIpAddress $i" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                closeScript 1
            }
        }
        Write-Host("Total ExclusionIpAddress entries deleted:", $AV.ExclusionExtension.Count) -ForegroundColor Cyan
        Write-Host
    }
    else
    {
        Write-Host
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host "Processing AV ExclusionIpAddress entry removals" -ForegroundColor Magenta
        Write-Host "##########################################################################" -ForegroundColor White
        Write-Host
        Write-Host "No ExclusionIpAddress entries present. Skipping..." -ForegroundColor Green
        Write-Host
    }
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host "Finished processing AV Exclusion entry removal" -ForegroundColor Magenta
    Write-Host "##########################################################################" -ForegroundColor White
    Write-Host
}

function Black-Hole()
{
    Write-Host ";P"
    Write-Host
}

function Color-ASCII($art)
{
    for ($i=0;$i -lt $art.length;$i++) {
    if ($i%2)
    {
        $c = "red"
    }
        elseif ($i%5) {
        $c = "yellow"
    }
        elseif ($i%7) {
        $c = "green"
    }
        else {
        $c = "white"
    }
        write-host $art[$i] -NoNewline -ForegroundColor $c
    }
}

function Menu()
{
 Clear-Host        
  Do
  {
    Clear-Host
    $ask
    Write-Host
    #Color-ASCII
    $ninjaCat
    Write-Host
    $menuArt
    Write-Host -Object $errout
    $Menu = Read-Host -Prompt '(0-5 or Q to Quit)'
    switch ($Menu) 
        {
            0 
            {Black-Hole
            pause}
            1 
            {Check-Platform
            pause}
            2 
            {Check-TP
            pause}
            3 
            {EPP-Harden
            pause}
            4 
            {EPP-Defaults
            pause}
            5 
            {Remove-AVExclusions
            pause}
            6
            {EPP-Allow
            pause
            }
            7
            {EPP-AllowRevert
            pause
            }
            Q 
            {Exit}   
            default
            {$errout = 'Invalid option please try again........Try 0-6 or Q only'}
        }
    }
    until ($Menu -eq 'q')
}   

$filename = "$scriptDir\play.mp3"
$isFileExist = Test-Path $filename -PathType Leaf

if($isFileExist -eq $false)
{
    [IO.File]::WriteAllBytes($filename, [Convert]::FromBase64String($base64File))
}

Add-Type -AssemblyName presentationCore
$mediaPlayer = New-Object system.windows.media.mediaplayer
$mediaPlayer.open("$scriptDir\play.mp3")
$mediaPlayer.Play()  

#Launch The Menu
Menu
