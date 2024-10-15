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
            Set-MpPreference -AllowNetworkProtectionOnWinServer 1
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
        Write-Host "Setting ASR Rule `"Block executable files from running unless they meet a prevalence, age, or trusted list criterion`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-cd74-433a-b99e-2ecdc07bfc25 -AttackSurfaceReductionRules_Actions Enabled
        Write-Host "Success." -ForegroundColor Green
        Write-Host
        Write-Host "Setting ASR Rule `"Block JavaScript or VBScript from launching downloaded executable content`" to Block mode..." -ForegroundColor Cyan
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
        Write-Host "Setting ASR Rule `"Block execution of potentially obfuscated scripts`" to Block mode..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 5beb7efe-fd9a-4556-801d-275e5ffc04cc -AttackSurfaceReductionRules_Actions Enabled
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
            Set-MpPreference -AllowNetworkProtectionOnWinServer 0
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
        Write-Host "Setting ASR Rule `"Block execution of potentially obfuscated scripts`" to Disabled..." -ForegroundColor Cyan
        Add-MpPreference -AttackSurfaceReductionRules_Ids 5beb7efe-fd9a-4556-801d-275e5ffc04cc -AttackSurfaceReductionRules_Actions Disabled
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
        Write-Host "Disabling SubmitSamplesConsent..." -ForegroundColor Cyan
        Set-MpPreference -SubmitSamplesConsent 2
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
        Write-Host "Enabling SubmitSamplesConsent..." -ForegroundColor Cyan
        Set-MpPreference -SubmitSamplesConsent 1
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

#Launch The Menu
Menu
