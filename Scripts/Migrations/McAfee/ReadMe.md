# Migrate McAfee <> Defender
Migrate your settings from McAfee to Microsoft Defender Firewall (MDF).

# Migrate Firewall Rules
The following two scripts can be used to convert McAfee firewall rules to MDF.

## Convert-FWRules.ps1
The first script Convert-FWRules.ps1 will read in and parse a McAfee firewall exported xml and will then export firewall rules to csv format.  This csv output will contain all of the columns necessary that map to parameters of the PowerShell [New-NetFirewallRule](https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps) cmdlet.  This is important to understand as each switch of the cmdlet ony accepts specific input(please see the linked doc for specifics of each switch).  Exporting to csv also permits the review of the exported firewall rules before importing them into MDF. The CSV output will need to be sanitized for a few reasons.

### The "Remote Address" Column
This column will need to be sanitized.  The reason is that it may have some values that the -RemoteAddress switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -RemoteAddress switch will accept.

Remote Address       | Second Header
| :--- | :--- 
192.168.10.x         | Content Cell
192.168.10.x and .x  | Content Cell
192.168.10.5 and 6   | Content Cell
SERVERGROUP          | Content Cell
DMZIPS               | Content Cell

You will need to map what these group names or IP addresses are and replace them in the CSV with acceptable values, for example:

Remote Address                   | Second Header
| :--- | :--- |
192.168.10.0/24                  | Content Cell
192.168.10.0/24,192.168.10.1/24  | Content Cell
192.168.10.5 and 6               | Content Cell
192.168.100.0/24                 | Content Cell
10.10.10.0/24                    | Content Cell

Note that these above are just examples and not direct maps :)  The important thing is that the fields are in a format that the -RemoteAddress switch accepts.
