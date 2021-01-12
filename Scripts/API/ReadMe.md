# :cat: MDE API :cat:
Microsoft Defender for Endpoint API.  An app registration in AzureAD is required to access the API. Documentation is here:

https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/apis-intro

# Various Things
A collection of scripts and items that use the Defender API to perform some actions.

# Bulk Tag Devices
This is a PowerShell script used to access the API and tag machines in bulk.  Additional logic can be added to make tagging decisions based on any available machine property in the schema. Machine properties are documented here:

https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/machine#properties

If you are bulk tagging a large number of devices (thousands) ensure that your token lifetime for your AzureAD application is long enough to support the duration of the tagging job that is running, else your token will expire and your job will error with a 401 unauthorized error. :thumbsup:

https://docs.microsoft.com/en-us/azure/active-directory/develop/configure-token-lifetimes#create-a-policy-for-a-native-app-that-calls-a-web-api
