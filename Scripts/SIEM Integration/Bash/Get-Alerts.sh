#!/bin/bash
##################################################################################################################
#
# Microsoft
# Get-Alerts.sh
# jesse.esquivel@microsoft.com
# -sample code taken from MDATP-Hello-World and modified:
#  https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/api-hello-world
# -Use to test your MDATP SIEM API for integration
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

#Get current working directory
scriptDir=$(pwd)

#get the token
token=$(<$scriptDir/Latest-token.txt)

#test MDATP security center api, change date if needed
url="https://api.securitycenter.windows.com/api/alerts?\$filter=alertCreationTime%20ge%202020-03-24T08:42:01.2164594Z"

#send web requst to API and echo JSON content
apiResponse=$(curl -s X GET "$url" -H "Content-Type: application/json" -H "Accept: application/json"\
         -H "Authorization: Bearer $token" | cut -d "[" -f2 | cut -d "]" -f1)
echo "If you see Alert info in JSON format, congratulations you accessed the MDATP Security center API!"
echo
echo $apiResponse
