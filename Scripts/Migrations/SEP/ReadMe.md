# Migrate Symantec Endpoint Protection --> Defender for Endpoint
Migrate your settings from Symantec to Microsoft Defender. :thumbsup:


                                             @@@@@@@@@@@@@@                     
                                          @@#@@@@@@@(//////@@@@                 
                     %@@              @@@. /@@@@@@@((@((@(@@@@@@                
                      @@.@@@   @@@@@@@@@@@@(@@@@@@@@(*@  @@#..(#@               
                        @@..,@//   ////@@@@@#@//////// ,.////////@(             
                          @@,.       //////@@@@@@@///.////@@@@@@@@              
                         &@@            //@@@@@@@@../////@@@@((@@@              
                 @@@@##@@%                 /@@@@#//,....@@@@@@@((@              
             @@@###/./....# @@@@@@     .    .....//////(((((((((@@@@@           
       @@#@@@####//////...#@@@@@@@@    ..    ..//////,...     @/(((///@@@       
    @@ @######///////,/###@@@@@@@@@@         .,///......        ////(((///@@@//@ 
    @#####//######/######@@@@@      ..           ###,....        @@(((/////////@@
    @@@@#####///#//####@@@@@@@                      ##### .         @@@@@(((((((@@  
    &@@@@@@/######@@@@@@@@@   @...@@   @@@@@@@@@@@@@(  @&         @@@@@@@@@@@@@    
     @@@@#&@@%@@@@@@@@@@  @@@..@@@                    @@       ...@@@@@@@@      
         (@@@@@@@@@@@@@@@@@@@@                           (@@*    ...@@@@@       
                                                             @&   @...@@        
                                                               @@    @@         
                                                                 @@@@@@         

# Migrate Firewall Rules
The following two scripts can be used to convert SEP firewall rules to MDF.


## Convert-SFWRules.ps1
The first script Convert-SFWRules.ps1 will read in and parse a SEP firewall exported xml and will then export firewall rules to csv format.  This csv output will contain all of the columns necessary that map to parameters of the PowerShell [New-NetFirewallRule](https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps) cmdlet.  This is important to understand as each switch of the cmdlet ony accepts specific input(please see the linked doc for specifics of each switch).  Exporting to csv also permits the review of the exported firewall rules before importing them into MDF.

<div class="text-red mb-2">Note:</div> When downloading sample script save in a .txt file in notepad as ANSI type, then rename .ps1.  We have seen issues where the code does not behave if it is saved as UTF-8.

## Import-FWRules.ps1
The second script will take the sanitized csv output (by file name), and use it to import the firewall rules into MDF on a Windows 10/Server 2016 or above machine in bulk. The csv contains all of the columns necessary that map to parameters of the PowerShell [New-NetFirewallRule](https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule?view=win10-ps) cmdlet, and the three columns above have been sanitized according to the environment.  This is reccomended to be done on a virtual machine for testing, this way you can import all of the firewall rules and view them in the Windows Firewall with Advanced Security snap-in.

### Human induced whitespace and non-valid characters
A few things to be aware of here. This first is line 109, this line contains a regular expression that looks for common whitespace character combinations that were used to delimit values in the McAfee xml, since these are not supported by MDF they must be removed and replaced with a comma.  The comma is required to split the value into an array, as the -RemoteAddress switch requires multiple values be passed as an array.

```PowerShell
RemoteAddress = $($Rule.'Remote Address') -replace ('(\s+-\s+|\s+,\s+,\s+|\s+,\s+|,\s+|\s-\s|and|\s+and\s+|and\s+|-\s+|\s+-|-|\sand)', ",") -split "," #<--remove human induced whitespace and nonvalid characters
```
Note that you may (depending on what is in your source xml file) encounter different whitespace character combinations used as value delimiters for the RemoteAddress column.  We cannot account for all of them, so you can modify the RegEx in line 109 to find and replace additional patterns! :thumbsup:

### RemotePort Usage with regards to Protocol
Second thing to be aware of are lines 112-115. On the MDF side you can only specify a port (using the -RemotePort switch) if the -Protocol switch is TCP or UDP.  So if you for instance specify a RemotePort of 200 and a protocol of 2 (IGMP), the cmdlet will fail.  These lines handle the situation by omitting the ReportPort column if the protocol is NOT TCP or UDP:

```PowerShell
RemotePort = if($rule.Protocol -eq "TCP" -or $rule.Protocol -eq "UDP")
{
    ListToStringArray $rule.'Remote Port'.replace(" ","") # <--- There must be no space in this string or cmdlet will fail :(
};
```
Once you execute this script (on your VM), it will begin to import the firewall rules into MDF.  When it is complete you can click refresh on the Inbound and Outbound sections and you will see your firewall rules for review. Please note that these are sample scripts, your mileage may vary! :grinning:

## Convert-SAVExclusions.ps1
This script will read in an exported SEP AV exclusion xml, and export the AV exclusions in Microsoft Defender AV format!  It produces two columns in a CSV:

Exclusion                    | Note
| :--- | :---
C:\Program Files\Rock Band\  | Typically there are no notes exported from the xml

Enjoy! :smiling_imp:
