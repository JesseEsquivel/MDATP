<#
##################################################################################################################
#
# Microsoft
# Get-latestAPIToken.ps1
# jesse.esquivel@microsoft.com
# -Get a token using an appid and secret to use against the DoD Graph API
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

#Get current working directory
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# That code gets the App Context Token and save it to a file named "Latest-token.txt" under the current directory
# Paste below your Tenant ID, App ID and App Secret (App key).

$tenantId = '' ### Paste your tenant ID here
$appId = '' ### Paste your Application ID here
$appSecret = '' ### Paste your Application key here

$resourceAppIdUri = 'https://dod-graph.microsoft.us' #resource request parameter is not supported when using v2.0 oauthUri
$oAuthUri = "https://login.microsoftonline.us/$TenantId/oauth2/v2.0/token" #v2 uri

$authBody = [Ordered] @{
    #resource = "$resourceAppIdUri"  #required only if using for v1 uri
    scope = "https://dod-graph.microsoft.us/.default" #required only if using v2 uri
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$token = $authResponse.access_token
Out-File -FilePath "$scriptDir\Latest-token.txt" -InputObject $token
return $token

#validate token at https://jwt.ms/
