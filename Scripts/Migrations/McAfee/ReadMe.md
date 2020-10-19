# Migrate McAfee <> Defender
Migrate your settings from McAfee to Microsoft Defender.

# Migrate Firewall Rules
The following two scripts can be used to convert McAfee firewall rules to MDF.

## Convert-FWRules.ps1
The first script Convert-FWRules.ps1 will read in and parse a McAfee firewall exported xml and will then export firewall rules to csv format.  This csv output will contain all of the columns necessary that map to parameters of the PowerShell [New-NetFirewallRule](https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps) cmdlet.  This is important to understand as each switch of the cmdlet ony accepts specific input(please see the linked doc for specifics of each switch).  Exporting to csv also permits the review of the exported firewall rules before importing them into MDF. The CSV output will need to be sanitized for a few reasons.

### The "Remote Address" Column
This column will need to be sanitized.  The reason is that it may have some values that the -RemoteAddress switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -RemoteAddress switch will accept.

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.x                     | **\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.x and .x              | C:\Program Files*\Adobe\acrobat.exe        | EITHER
192.168.10.5 and .6              | C:\Program Files\Adobe\*.exe               | BOTH
SERVERGROUP                      |                                            | BOTH
DMZIPS                           | C:\Program Files\Java\*\java.exe           | EITHER

You'll need to map what these group names or IP addresses are and replace them in the CSV with acceptable values, for example:

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | **\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files*\Adobe\acrobat.exe        | EITHER
192.168.10.5,192.168.10.6        | C:\Program Files\Adobe\*.exe               | BOTH
192.168.100.0/24                 |                                            | BOTH
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe           | EITHER

Note that these above are just examples and not direct maps :)  The important thing is that the fields are in a format that the -RemoteAddress switch accepts.  Be kind and delimit acceptable values with a comma as shown above.  If there are values present that are in an acceptable format but are delimited by something other than a comma, this should be handled by the other script, it will remove those and replace them with a comma.

### The Program Column
This column will need to be sanitized.  The reason is that it may have some values that the -Program switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -Program switch will accept. Same story as the Remote Address column.

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | **\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files*\Adobe\acrobat.exe        | EITHER
192.168.10.5,192.168.10.6        | C:\Program Files\Adobe\*.exe               | BOTH
192.168.100.0/24                 |                                            | BOTH
10.10.10.0/24                    | C:\Program Files\Java\*\java.exe           | EITHER

The New-NetFirewallRule cmdlet -program switch only accepts a FULL path to a file name.  So you must do some investigation to find what those full paths would be.  Also you may need to create multiple rules if multiple programs are required (for example acrobat.exe and acrobatupdater.exe will require two different rules).  You'll need to map what these application names are  to a full path and file name and replace them in the CSV with acceptable values, for example:

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | EITHER
192.168.10.5,192.168.10.6        | C:\Program Files\Adobe\acrobat.exe         | BOTH
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | BOTH
10.10.10.0/24                    | C:\Program Files\Java\15\java.exe          | EITHER

### The Direction Column
lastly the direction column which will also need to be sanitized.  The reason is that it may have some values that the -Direction switch does not accept.  Some of these unacceptable values are listed below and will need to be replaced with values that the -Program switch will accept. Same story as the Remote Address column.

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | EITHER
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | EITHER
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | BOTH
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | BOTH
10.10.10.0/24                    | C:\Program Files\Java\15\java.exe          | EITHER

The New-NetFirewallRule cmdlet -Desitnation switch only accepts either "Inbound" or "Outbound" as a value, not both.  You will want to sort the CSV by this column, then identify all rules that are set to EITHER or BOTH.  You will need to duplicate all of those entries and rename the direction to Inbound for the original rows, and Outbound for the duplicated rows.  For example you will end up with an output like this:

Remote Address                   | Program                                    | Direction
| :--- | :--- | :---
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | INBOUND
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | INBOUND
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | INBOUND
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | INBOUND
10.10.10.0/24                    | C:\Program Files\Java\15\java.exe          | INBOUND
192.168.10.0/24                  | C:\Program Files\Adobe\acrobat.exe         | OUTBOUND
192.168.10.0/24,192.168.10.1/24  | C:\Program Files(x86)\Adobe\acrobat.exe    | OUTBOUND
192.168.10.5 and 6               | C:\Program Files\Adobe\acrobat.exe         | OUTBOUND
192.168.100.0/24                 | C:\Program Files\Adobe\acrobatupdater.exe  | OUTBOUND
10.10.10.0/24                    | C:\Program Files\Java\15\java.exe          | OUTBOUND

Once you have all three of these columns sanitized for your environment you can move on to importing the firewall rules into MDF.

## Import-MFWRules.ps1
The second script will take the sanitized csv output (by file name), and use it to import the firewall rules into MDF on a Windows 10/Server 2016 or above machine in bulk. The csv contains all of the columns necessary that map to parameters of the PowerShell [New-NetFirewallRule](https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps) cmdlet, and the three columns above have been sanitized according to the environment.  This is reccomended to be done on a virtual machine for testing, this way you can import all of the firewall rules and view them in the Windows Firewall with Advanced Security snap-in.

A few things to be aware of here. This first is line 109, this line contains a regular expression that looks for common whitespace character combinations that were used to delimit values in the McAfee xml, since these are not supported by MDF they must be removed and replaced with a comma.  The comma is required to split the value into an array, as the -RemoteAddress switch requires multiple values be passed as an array.

```PowerShell
RemoteAddress = $($Rule.'Remote Address') -replace ('(\s+-\s+|\s+,\s+,\s+|\s+,\s+|,\s+|\s-\s|and|\s+and\s+|and\s+|-\s+|\s+-|-|\sand)', ",") -split "," #<--remove human induced whitespace and nonvalid characters
```
Note that you may (depending on what is in your source xml file) encounter different whitespace character combinations used as value delimiters for the RemoteAddress column.  We cannot account for all of them, so you can modify the RegEx in line 109 to find and replace additional patterns!

Second thing to be aware of are lines 112-115. On the MDF side you can only specify a port (using the -RemotePort switch) if the -Protocol switch is TCP or UDP.  So if you for instance specify a RemotePort of 200 and a protocol of 2 (IGMP), the cmdlet will fail.  These lines handle the situation:

```PowerShell
    		RemotePort = if($rule.Protocol -eq "TCP" -or $rule.Protocol -eq "UDP")
    		{
        	    ListToStringArray $rule.'Remote Port'.replace(" ","") # <--- There must be no space in this string or cmdlet will fail :(
    		};
```
Once you execute this script (on your VM), it will begin to import the firewall rules into MDF.  When it is complete you can click refresh on the Inbound and Outbound sections and you will see your firewall rules for review.




