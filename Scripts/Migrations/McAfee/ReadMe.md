# Migrate McAfee <> Defender
Migrate your settings from McAfee to Microsoft Defender.

# Migrate Firewall Rules
The following two scripts can be used to convert McAfee firewall rules to MDF.

## Convert-FWRules.ps1
The first script Convert-FWRules.ps1 will read in and parse a McAfee firewall exported xml and will then export firewall rules to csv format.  This csv output will contain all of the columns necessary that map to parameters of the PowerShell [New-NetFirewallRule](https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps) cmdlet.  This is important to understand as each switch of the cmdlet ony accepts specific input(please see the linked doc for specifics of each switch).  Exporting to csv also permits the review of the exported firewall rules before importing them into MDF. The CSV output will need to be sanitized for a few reasons.

### The "Remote Address" Column
This column will need to be sanitized.  The reason is that it may have some values that the -RemoteAddress switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -RemoteAddress switch will accept.

Remote Address       | Program                      | Direction
| :--- | :--- | :---
192.168.10.x         | Content Cell                 | EITHER
192.168.10.x and .x  | Content Cell                 | EITHER
192.168.10.5 and 6   | Content Cell                 | BOTH
SERVERGROUP          | Content Cell                 | BOTH
DMZIPS               | Content Cell                 | EITHER

You'll need to map what these group names or IP addresses are and replace them in the CSV with acceptable values, for example:

Remote Address                   | Program           | Direction
| :--- | :--- | :---
192.168.10.0/24                  | Content Cell      | EITHER
192.168.10.0/24,192.168.10.1/24  | Content Cell      | EITHER
192.168.10.5 and 6               | Content Cell      | BOTH
192.168.100.0/24                 | Content Cell      | BOTH
10.10.10.0/24                    | Content Cell      | EITHER

Note that these above are just examples and not direct maps :)  The important thing is that the fields are in a format that the -RemoteAddress switch accepts.  Be kind and delimit acceptable values with a comma as shown above.  If there are values present that are in an acceptable format but are delimited by something other than a comma, this should be handled by the other script, it will remove those and replace them with a comma.

### The Program Column
This column will need to be sanitized.  The reason is that it may have some values that the -Program switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -Program switch will accept. Same story as the Remote Address column.

Remote Address                   | Program                                | Direction
| :--- | :--- | :---
192.168.10.0/24                  | **\Program Files\Adobe\acrobat.exe     | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files*\Adobe\acrobat.exe    | EITHER
192.168.10.5 and 6               | C:\Program Files\Adobe\*.exe           | BOTH
192.168.100.0/24                 |                                        | BOTH
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe       | EITHER

The New-NetFirewallRule cmdlet -program switch only accepts a FULL path to a file name.  So you must do some investigation to find what those full paths would be.  Also you may need to create multiple rules if multiple programs are required (for example acrobat.exe and acrobatupdater.exe will require two different rules).  You'll need to map what these application names are  to a full path and file name and replace them in the CSV with acceptable values, for example:

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | EITHER
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | BOTH
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | BOTH
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe           | EITHER

### The Direction Column
lastly the direction column which will also need to be sanitized.  The reason is that it may have some values that the -Direction switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -Program switch will accept. Same story as the Remote Address column.

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | EITHER
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | BOTH
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | BOTH
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe           | EITHER

The New-NetFirewallRule cmdlet -Desitnation switch only accepts either "Inbound" or "Outbound" as a value, not both.  You will want to sort the CSV by this column, then identify all rules that are set to EITHER or BOTH.  You will need to duplicate all of those entries and rename the direction to Inbound for the original rows, and Outbound for the duplicated rows.  For example you will end up with an output like this:

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | INBOUND
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | INBOUND
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | INBOUND
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | INBOUND
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe           | INBOUND
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | OUTBOUND
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | OUTBOUND
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | OUTBOUND
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | OUTBOUND
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe           | OUTBOUND

Once you have all three of these columns sanitized for your environment you can move on to importing the firewall rules into MDF.

## Import-MFWRules.ps1






