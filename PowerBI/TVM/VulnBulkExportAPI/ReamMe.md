# TVM Bulk Export API
The TVM vulnerability assessement API can be used to create an inclusive vulnerability assessment report of every endpoint onboarded into Defender for Endpoint. The API response via files method is good for organizations with over 100K endpoints.

- TVM Vulnerability assessment API:<br>
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/get-assessment-software-vulnerabilities?view=o365-worldwide

- TVM Vulnerability assessment API schema:<br>
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/get-assessment-software-vulnerabilities?view=o365-worldwide#15-properties

### PowerShell Sample
The PowerShell sample can be used to query the API via application context and download the data from the file based response, culminating in a JSON file that can be imported into PBI.

- Download the PowerShell sample
- Create an AzureAd application to access the API (good for running as a job)<br>
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/exposed-apis-create-app-webapp?view=o365-worldwide
- Grant the appropriate permissions to the AzureAD application<br>
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/get-assessment-software-vulnerabilities?view=o365-worldwide#12-permissions
- Enter the tenantId, appid, and secret into the script
  ```PowerShell
  #enter tenant specific information here
  $tenantId = '' ### Paste your own tenant ID here
  $appId = '' ### Paste your own app ID here
  $appSecret = '' ### Paste your own app keys here
  ```
- Run, use the json file output to import into the PBI template

### PowerBI Template
This sample PowerBI template can be used by importing the JSON file as the data source. Hopefully this sample can get you started on your way to querying the API and making custom reports. 📊 😈

![image](https://user-images.githubusercontent.com/33558203/185193369-70812466-578a-4ab6-8cd4-53237fbca91d.png)

