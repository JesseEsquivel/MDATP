<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# steve.pucelik@micrsoft.com
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com - just for the guts ;)
#
# Convert-SFWRules.ps1
# v1.0 Initial creation 1/13/2021 - Export SEP FW Exclusions into Defender format from xml
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

$VBCrLf = "`r`n"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
[xml]$sourceRules = Get-Content "$scriptDir\source.xml"

##################################################################################################################
# Functions
##################################################################################################################

Function startScript()
{
    $msg = "Beginning Firewall conversion tasks from $env:COMPUTERNAME" + $VBCrLf + "@ $(get-date) via PowerShell Script.  Logging is enabled."
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host  "$msg" -ForegroundColor Green
    Write-Host "######################################################################################" -ForegroundColor Yellow
    Write-Host
}

Function closeScript($exitCode)
{
    if($exitCode -ne 0)
    {
        Write-Host
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Script execution unsuccessful, and terminted at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" `
        + $VBCrLf + "Examine the script output and previous events logged to resolve errors."
        Write-Host $msg -ForegroundColor Red
        Write-Host "######################################################################################" -ForegroundColor Yellow
    }
    else
    {
        Write-Host "######################################################################################" -ForegroundColor Yellow
        $msg = "Successfully completed script at $(get-date)" + $VBCrLf + "Time Elapsed: ($($elapsed.Elapsed.ToString()))" + $VBCrLf `
        + "Review the logs."
        Write-Host $msg -ForegroundColor Green
        Write-Host "######################################################################################" -ForegroundColor Yellow
    }
    exit $exitCode
}

function GetFwNetworkInterfaceGroup
{
    param ($TargetID)
    #/SchemaContainer/FwNetworkInterfaceGroup
    $ns = New-Object System.Xml.XmlNamespaceManager($sourceRules.NameTable);
    $ns.AddNamespace("ns", $sourceRules.DocumentElement.NamespaceURI)
    $fwNetworkfInterfaceGroup = $sourceRules.SelectSingleNode("//SchemaContainer/FwNetworkInterfaceGroup[@Id='$TargetID']/FwInterfaceContainer/FwNetworkInterface",$ns)
    $interfaceType = $fwNetworkfInterfaceGroup.Attributes.GetNamedItem("NetworkInterfaceType").Value
    return  $interfaceType
}

function GetPort
{
    param($rawProtocol)

    #The port can be either the 1st or 2nd attribute in the element.
    if($rawProtocol.Attributes[0].Name -eq "LocalPort" -or $rawProtocol.Attributes[0].Name -eq "RemotePort")
    {
        $index = 0
    }
    else
    {
        $index = 1
    }
    switch ($rawProtocol.Attributes[$index].Name) {
        'LocalPort' 
        { 
            $localPort = $rawProtocol.Attributes.GetNamedItem("LocalPort").value
            AddRuleProperty "Local Port" $localPort
            AddRuleProperty "Remote Port" "Any"
        }
        'RemotePort'
        {
            $remotePort = $rawProtocol.Attributes.GetNamedItem("RemotePort").value
            AddRuleProperty "Local Port" "Any"
            AddRuleProperty "Remote Port" $remotePort
        }
    }
}

function AddRuleProperty
{
    param([String] $ruleName, $ruleValue)
    Add-Member -InputObject $HashProps -MemberType NoteProperty -Name $ruleName -Value $ruleValue
}

function CreateRule 
{
    param($HashProps)
    $global:firewallRules += $HashProps
}

function ProcessItem
{
    param($item)
    Write-Host "Capturing rule $i of $($item.ParentNode.ChildNodes.Count) - $($item.Name)"  -ForegroundColor Cyan
    if($item.ToString() -eq "FirewallRule")
    {
        try 
        {
            #**************Interface Type ************************
            $itemNetworkInterfaceTrigger = $item.GetElementsByTagName("FwNetworkInterfaceTrigger")
            $itemNetworkInterfaceGroup = $itemNetworkInterfaceTrigger.GetElementsByTagName("ObjReference")
            $InterfaceType = GetFwNetworkInterfaceGroup($itemNetworkInterfaceGroup.Attributes.GetNamedItem("TargetId").value)
            if($interfaceType -eq "ALL")
            {
                $InterfaceType = "Any"
            }
        }
        catch 
        {
            $InterfaceType = "Any"    
        }
        $Enabled = $item.Attributes.GetNamedItem("Enable").value
        if($Enabled =1)
        {
            $Enabled = "True"
        }
        else
        {
            $Enabled ="False"   
        }
        $Direction = $item.Attributes.GetNamedItem("RuleType").value
        if($Direction = "N")
        {
            $Direction = "Outbound"
        }
        else {
            $Direction = "Inbound"
        }
        #**************Action*********************************
        $PacketProcess = $item.GetElementsByTagName("PacketProcess")
        $Action = $PacketProcess.Attributes[0].Value
        if($Action -eq "PASS")
        {
            $Action = "Allow"
        }
        else
        {
            $Action = "Block"    
        }
        #Protocol and port information can be in the FwProtocolContainer or FwServiceTrigger elements.
        try 
        {
            $FwServiceTrigger = $item.GetElementsByTagName("FwServiceTrigger")
            if ($FwServiceTrigger.Count -gt 0 -and $FwServiceTrigger[0].FirstChild.LocalName -eq "ObjReference" )
            {
                $ObjReference = $FwServiceTrigger.ChildNodes
                foreach ($obj in $ObjReference) 
                {
                    $targetID = $obj.Attributes.GetNamedItem("TargetId").value
                    $ns = New-Object System.Xml.XmlNamespaceManager($sourceRules.NameTable);
                    $ns.AddNamespace("ns", $sourceRules.DocumentElement.NamespaceURI)
                    $FwProtocolGroup = $sourceRules.SchemaContainer.FwNetworkServiceGroup | Where-Object Id -eq "$targetID"
                    $FwProtocolContainer = $FwProtocolGroup.ChildNodes
                    $protocolContainer = $FwProtocolContainer.ChildNodes
                    foreach ($protocolItem in $protocolContainer) 
                    {
                        $HashProps = New-Object PSObject
                        AddRuleProperty "DisplayName" $item.Name  
                        #AddRuleProperty "Profile" $ProfileName
                        AddRuleProperty "Interface Type" $interfaceType
                        AddRuleProperty "Action" $Action
                        AddRuleProperty "Direction" $Direction
                        AddRuleProperty "Enabled" $Enabled  
                        AddRuleProperty "Profile" "Any"
                        $localPort = ''
                        $rawProtocol = $protocolItem.LocalName
                        #$rawProtocol = $protocolItem.FirstChild
                        $Protocol = $rawProtocol.Substring(3,$rawProtocol.Length-3) 
                        switch($Protocol)
                        {
                            #For IP, get the ProtocolNumber attribute
                            'Ip'
                            {
                                $Protocol = "Any"
                                AddRuleProperty "Local Port" "Any"
                                AddRuleProperty "Remote Port" "Any"
                            }
                            'Icmp'
                            {
                                $Protocol = "ICMPv4"
                            }
                            #For TCP/UDP, get the LocalPort or RemotePort attributes
                            {$_ -eq 'Tcp' -or $_ -eq 'Udp'}
                            {
                                $localPort = GetPort($protocolItem)
                            }
                            Default
                            {
                                $Protocol = "Any"
                                AddRuleProperty "Local Port" "Any"
                                AddRuleProperty "Remote Port" "Any"
                            }
                        }
                        AddRuleProperty "Remote Address" "Any"
                        AddRuleProperty "Protocol" $Protocol
                        CreateRule $HashProps
                    }
                }   
            }
        }
        catch 
        {
            #Write-Host "Protocol not present"
        }
        try 
        {
            $fwProtocolContainer = $item.GetElementsByTagName("FwProtocolContainer")
            if($fwProtocolContainer.Count -gt 0)
            {
                foreach ($protocolItem in $fwProtocolContainer) 
                {
                    $HashProps = New-Object PSObject
                    AddRuleProperty "DisplayName" $item.Name  
                    #AddRuleProperty "Profile" $ProfileName
                    AddRuleProperty "Interface Type" $interfaceType
                    AddRuleProperty "Action" $Action
                    AddRuleProperty "Direction" $Direction
                    AddRuleProperty "Enabled" $Enabled
                    AddRuleProperty "Profile" "Any"
                    $localPort = ''
                    $rawProtocol = $protocolItem.FirstChild
                    $Protocol = $rawProtocol.Name.Substring(3,$rawProtocol.Name.Length-3)                     
                    switch($Protocol)
                    {
                        #For IP, get the ProtocolNumber attribute
                        'Ip'
                        {
                            $Protocol = "Any"                                
                            AddRuleProperty "Local Port" "Any"
                            AddRuleProperty "Remote Port" "Any"
                        } 
                        'Icmp'
                        {
                            $Protocol = "ICMPv4"
                        }
                        #For TCP/UDP, get the LocalPort or RemotePort attributes
                        {$_ -eq 'Tcp' -or $_ -eq 'Udp'}
                        {
                            $localPort = GetPort($rawProtocol)
                        }
                        Default
                        {
                            $Protocol = "Any"
                            AddRuleProperty "Local Port" "Any"
                            AddRuleProperty "Remote Port" "Any"
                        }
                    }
                    AddRuleProperty "Remote Address" "Any"
                    AddRuleProperty "Protocol" $Protocol
                    CreateRule $HashProps
                }
            }
        }
        catch 
        {
            Write-Host "Protocol not present"
        }
        try 
        {  
            #Get the remote IpRanges
            $RemoteAddressContainer = $item.GetElementsByTagName("RemoteHostTrigger")
            $fwHostContainer = $RemoteAddressContainer.GetElementsByTagName("IpRange")
            if($RemoteAddressContainer[0].FirstChild.LocalName -eq "ObjReference")
            {
                $ObjReference = $RemoteAddressContainer.ChildNodes
                foreach ($obj in $ObjReference) 
                {
                    #TODO:  Get all the IP's for the target ID.
                    $targetID = $obj.Attributes.GetNamedItem("TargetId").value
                    $ns = New-Object System.Xml.XmlNamespaceManager($sourceRules.NameTable);
                    $ns.AddNamespace("ns", $sourceRules.DocumentElement.NamespaceURI)
                    $FwProtocolGroup = $sourceRules.SchemaContainer.FwNetworkHostGroup | Where-Object Id -eq "$targetID"
                    $FwProtocolContainer = $FwProtocolGroup.ChildNodes
                    $protocolContainer = $FwProtocolContainer.ChildNodes
                    foreach ($protocolItem in $protocolContainer) 
                    {
                        if($rawProtocol = $protocolItem.LocalName -eq "IpAddress")
                        {
                            $HashProps = New-Object PSObject
                            AddRuleProperty "DisplayName" $item.Name  
                            #AddRuleProperty "Profile" $ProfileName
                            AddRuleProperty "Interface Type" $interfaceType
                            AddRuleProperty "Action" $Action
                            AddRuleProperty "Direction" $Direction
                            AddRuleProperty "Enabled" $Enabled  
                            AddRuleProperty "Profile" "Any"
                            $localPort = ''
                            $rawProtocol = $protocolItem.LocalName
                            AddRuleProperty "Remote Address" $protocolItem.InnerText
                            AddRuleProperty "Protocol" "Any"
                            AddRuleProperty "Local Port" "Any"
                            AddRuleProperty "Remote Port" "Any"
                            CreateRule $HashProps
                        }
                    }
                }
            }
        if($fwHostContainer.Count -gt 0)
        {
                foreach ($hostItem in $fwHostContainer) 
                {
                    #$HashProps = [PSCustomObject]@{}
                    $HashProps = New-Object PSObject
                    AddRuleProperty "DisplayName" $item.Name  
                    #AddRuleProperty "Profile" $ProfileName
                    AddRuleProperty "Interface Type" $interfaceType
                    AddRuleProperty "Action" $Action
                    AddRuleProperty "Direction" $Direction
                    AddRuleProperty "Enabled" $Enabled 
                    AddRuleProperty "Profile" "Any"
                    AddRuleProperty "Protocol" "Any"
                    AddRuleProperty "Local Port" "Any"
                    AddRuleProperty "Remote Port" "Any"
                    $RemoteAddress = $hostItem.Attributes.GetNamedItem("Start").value + "-" + $hostItem.Attributes.GetNamedItem("End").value
                    AddRuleProperty "Remote Address" $RemoteAddress
                    CreateRule $HashProps
                }
            }
        }
        catch 
        {
            #Write-Host "IPRanges not present."    
        }
    }
    Write-Host "Success." -ForegroundColor Green
    Write-Host
}

##################################################################################################################
# Begin Script
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript
$i = 1

$firewallRules = @()

<# These sections will export the MacOS firewall rules, reserved for future use
foreach($item in $sourceRules.SchemaContainer.FwFirewallPolicy.MacFwFirewallPolicy.FirewallRuleSystem.EnforcedFirewallRuleArray.FirewallRule)
{
    ProcessItem $item
    $i = $i + 1
}
$i = 1
foreach($item in $sourceRules.SchemaContainer.FwFirewallPolicy.MacFwFirewallPolicy.FirewallRuleSystem.BaselineFirewallRuleArray.FirewallRule)
{
    ProcessItem $item
    $i = $i + 1
}
#>

#export Windows FW rules
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Reading SEP Enforced Windows FW exclusions and exporting..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

$i = 1
foreach($item in $sourceRules.SchemaContainer.FwFirewallPolicy.FirewallRuleSystem.EnforcedFirewallRuleArray.FirewallRule)
{
    ProcessItem $item
    $i = $i + 1
}

Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host "Reading SEP Baseline Windows FW exclusions and exporting..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

$i = 1
foreach($item in $sourceRules.SchemaContainer.FwFirewallPolicy.FirewallRuleSystem.BaselineFirewallRuleArray.FirewallRule)
{
    ProcessItem $item
    $i = $i + 1
}

$global:firewallRules | ConvertTo-CSV -NoTypeInformation -Delimiter '~' | Set-Content $scriptDir\output.txt

closescript 0
