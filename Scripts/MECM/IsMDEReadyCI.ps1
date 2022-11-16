<#
##################################################################################################################
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com
# Check-MDE.ps1
# Check that MDE is active and updated for takeover from 3rd party EPP
# v1.0 Initial creation 11/15/2022
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

#values should be N-3 from: https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/manage-updates-baselines-microsoft-defender-antivirus?view=o365-worldwide#monthly-platform-and-engine-versions
[version]$minPlatform = '4.18.2207.7' 
[version]$minEngine = '1.1.19800.3'

##################################################################################################################
# Functions
##################################################################################################################

Function Check-MDE($Platform, $Engine)
{
    $date = Get-Date -Format "yyMM"
    $result = Get-MpComputerStatus | select AMRunningMode,AMEngineVersion,AMProductVersion,AntispywareSignatureLastUpdated
    $return = [pscustomobject]@{
        isMDEReady = ([version]$($result.AMEngineVersion) -ge $Engine)`
            -and ([version]$($result.AMProductVersion) -ge $Platform)`
            -and ($result.AMRunningMode -like "passive" -or $result.AMRunningMode -like "EDR Block"`
            -or $result.AMRunningMode -like "Normal")`
            -and ($result.AntispywareSignatureLastUpdated -ge $result.AntispywareSignatureLastUpdated.AddDays(-7))
        details = [pscustomobject]@{
            AMEngineVersion = $result.AMEngineVersion
            AMProductVersion = $result.AMProductVersion
            AMRunningMode = $result.AMRunningMode
            AntispywareSignatureLastUpdated = $result.AntispywareSignatureLastUpdated
            }
    }
    $return.isMDEReady
}

$ready = Check-MDE $minPlatform $minEngine
$ready
