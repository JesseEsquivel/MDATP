<#
##################################################################################################################
#
# Microsoft Customer Experience Engineering
# 
# Apply-CIPolicy.ps1
# Apply WDAC CI Policy
# v1.0 Initial creation 03-07-2024
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

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$RefreshPolicyTool = "$scriptDir\RefreshPolicy.exe"
$DestinationFolder = $env:windir+"\System32\CodeIntegrity\CIPolicies\Active\"

##################################################################################################################
# Main
##################################################################################################################

#set MECM as managed installer - REQUIRED for Managed Installer to function
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\CCM -Name EnableManagedInstaller -Value 1 -Force

#start required applocker services - REQUIRED for Managed Installer to function
appidtel.exe start -mionly
sc.exe config appidsvc start=auto

#remove any existing WDAC policies
Remove-Item $DestinationFolder\*.cip

# Policy binary files should be named as {GUID}.cip for multiple policy format files (where {GUID} = <PolicyId> from the Policy XML)
$MainPolicyBinary = "$scriptDir\{248F2534-7F16-4332-8563-2BA7F606960C}.cip"
#$SupPolicyBinary = "$scriptDir\{7133A3B8-C588-4DFA-BEC3-86C70BE9E689}.cip"

#copy new WDAC policy
Copy-Item -Path $MainPolicyBinary -Destination $DestinationFolder -Force
#Copy-Item -Path $SupPolicyBinary -Destination $DestinationFolder -Force

#rebootless refresh of WDAC policy
& $RefreshPolicyTool
