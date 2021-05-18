<#
##################################################################################################################
#
# Microsoft Premier Field Engineering
# steve.pucelik@micrsoft.com
#
# Microsoft Customer Experience Engineering
# jesse.esquivel@microsoft.com - just for the guts, re-write to v1.1
#
# Convert-SFWRules.ps1
# v1.0 Initial creation 1/13/2021 - Export SEP FW Exclusions into Defender format from xml
# v1.1 Re-write 5/10/2021 - Re-write to handle new scenarios and attributes
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
[xml]$sourceRules = Get-Content "$scriptDir\input.xml"

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

function Add-RuleProperty
{
    param([String] $ruleName, $ruleValue)
    if(!($global:HashProps.$($ruleName)))
    {
        Add-Member -InputObject $global:HashProps -MemberType NoteProperty -Name $ruleName -Value $ruleValue
    }
}
function CreateRule 
{
    param($global:HashProps)
    $global:firewallRules += $global:HashProps
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

function Process-FwServiceTrigger
{
    $ObjReference = $FwServiceTrigger.ChildNodes
    foreach ($obj in $ObjReference) 
    {
        if($obj.FirstChild.LocalName -eq "ObjReference")
        {
            $targetID = $obj.Attributes.GetNamedItem("TargetId").value
            $ns = New-Object System.Xml.XmlNamespaceManager($sourceRules.NameTable);
            $ns.AddNamespace("ns", $sourceRules.DocumentElement.NamespaceURI)
            $FwProtocolGroup = $sourceRules.SchemaContainer.FwNetworkServiceGroup | Where-Object Id -eq "$targetID"
            $FwProtocolContainer = $FwProtocolGroup.ChildNodes
            $protocolContainer = $FwProtocolContainer.ChildNodes
        }
        else
        {
            $protocolContainer = $obj.FirstChild    
        }
        foreach ($protocolItem in $protocolContainer) 
        {
            $rawProtocol = $protocolItem.LocalName
            $Protocol = $rawProtocol.Substring(3,$rawProtocol.Length-3)
            foreach($protocolItem in $protocolItem.Attributes)
            {
                if($ObjReference.Length -gt 1)
                {
                    if($protocolItem.Name -eq "ProtocolNumber")
                    {
                        $ProtocolNumber = $protocolItem.Value
                        switch($Protocol)
                        {
                            'Ethernet'
                            {
                                $Protocol = $ProtocolNumber

                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any" 
                                Add-RuleProperty "Protocol" $Protocol
                                Add-RuleProperty "Program" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'Ip'
                            {
                                $Protocol = $ProtocolNumber

                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any" 
                                Add-RuleProperty "Protocol" $Protocol
                                Add-RuleProperty "Program" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                        }    
                    }
                    else
                    {
                        switch($protocolItem.Name)
                        {
                            'LocalPort'
                            {
                                $localPort = $protocolItem.Value
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" $localPort
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Protocol" $Protocol
                                Add-RuleProperty "Program" "Any"
                                Add-RuleProperty "Remote Address" "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'RemotePort'
                            {
                                $RemotePort = $protocolItem.Value
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" $RemotePort
                                Add-RuleProperty "Protocol" $Protocol
                                Add-RuleProperty "Program" "Any"
                                Add-RuleProperty "Remote Address" "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'IcmpType'
                            {
                                $ProtocolNumber = $protocolItem.Value
                                switch($Protocol)
                                {
                                    'Icmp'
                                    {
                                        $global:HashProps = New-Object PSObject
                                        Add-RuleProperty "DisplayName" $item.Name  
                                        Add-RuleProperty "Interface Type" $interfaceType
                                        Add-RuleProperty "Action" $Action
                                        Add-RuleProperty "Direction" $Direction
                                        Add-RuleProperty "Enabled" $Enabled  
                                        Add-RuleProperty "Profile" "Any" 
                                        $Protocol = $ProtocolNumber
                                        Add-RuleProperty "Local Port" "Any"
                                        Add-RuleProperty "Remote Port" "Any"
                                        Add-RuleProperty "Protocol" $Protocol
                                        Add-RuleProperty "Program" "Any"
                                        Add-RuleProperty "Remote Address" "Any"
                                        CreateRule $global:HashProps
                                        $global:FwRuleCreated = "true"
                                    }
                                }    
                            }
                        }
                    }    
                }
                #only 1 item to process
                else
                {
                    if($protocolItem.Name -eq "ProtocolNumber")
                    {
                        $ProtocolNumber = $protocolItem.Value
                        switch($Protocol)
                        {
                            'Ethernet'
                            {
                                $Protocol = $ProtocolNumber
                                Add-RuleProperty "Protocol" $Protocol
                            }
                            'Ip'
                            {
                                $Protocol = $ProtocolNumber
                                Add-RuleProperty "Protocol" $Protocol
                            }
                        }
                    }
                    else
                    {
                        switch($protocolItem.Name)
                        {
                            'LocalPort'
                            {
                                $localPort = $protocolItem.Value
                                Add-RuleProperty "Local Port" $localPort
                                Add-RuleProperty "Protocol" $Protocol
                            }
                            'RemotePort'
                            {
                                    $RemotePort = $protocolItem.Value
                                    Add-RuleProperty "Remote Port" $RemotePort
                                    Add-RuleProperty "Protocol" $Protocol
                            }
                            'IcmpType'
                            {
                                $ProtocolNumber = $protocolItem.Value
                                switch($Protocol)
                                {
                                    'Icmp'
                                    {
                                        $Protocol = $ProtocolNumber
                                        Add-RuleProperty "Protocol" $Protocol
                                    }
                                }    
                            }
                        }    
                    }
                }
            }
        }
    }       
}

function Process-FwHostTrigger
{
    try
    {
        if($FwHostTrigger.Count -gt 0 -and $FwHostTrigger[0].ChildNodes.Name[1] -eq "RemoteHostTrigger")
        {
            $ObjReference = $FwHostTrigger.ChildNodes[1]
            foreach ($obj in $ObjReference) 
            {
                $targetID = $obj.FirstChild.Attributes.GetNamedItem("TargetId").value
                $ns = New-Object System.Xml.XmlNamespaceManager($sourceRules.NameTable);
                $ns.AddNamespace("ns", $sourceRules.DocumentElement.NamespaceURI)
                $FwNetworkHostGroup = $sourceRules.SchemaContainer.FwNetworkHostGroup | Where-Object Id -eq "$targetID"
                $fwHostContainer = $FwNetworkHostGroup.ChildNodes
                $hostContainer = $FwHostContainer.ChildNodes
                foreach ($hostContainerItem in $hostContainer) 
                {
                    if($hostContainer.Length -gt 1)
                    {   
                        $rawProtocol = $hostContainerItem.FirstChild
                        switch($hostContainerItem.LocalName)
                        {
                            'LocalPort'
                            {
                                $localPort = $protocolItem.Value
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" $localPort
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                Add-RuleProperty "Remote Address" "Any"
                                $Protocol = "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'RemotePort'
                            {
                                $RemotePort = $protocolItem.Value
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Remote Port" $RemotePort
                                Add-RuleProperty "Program" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Address" "Any"
                                $Protocol = "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'IpAddress'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                $Protocol = "Any"
                                Add-RuleProperty "Remote Address" $hostContainerItem.FirstChild.Data
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'IpRange'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                $Protocol = "Any"
                                foreach($rangeItem in $hostContainerItem.Attributes)
                                {
                                    switch($rangeItem.Name)
                                    {
                                        'Start'
                                        {
                                            $ipRangeStart = $rangeItem.Value
                                        }
                                        'End'
                                        {
                                            $ipRangeEnd = $rangeItem.Value
                                        }
                                    }
                                }
                                Add-RuleProperty "Remote Address" $ipRangeStart-$ipRangeEnd
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'SubNet'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                $Protocol = "Any"
                                foreach($rangeItem in $hostContainerItem.Attributes)
                                {
                                    switch($rangeItem.Name)
                                    {
                                        'NetAddr'
                                        {
                                            $ipNetAddr = $rangeItem.Value
                                        }
                                        'NetMask'
                                        {
                                            $ipNetMask = $rangeItem.Value
                                        }
                                    }
                                }
                                Add-RuleProperty "Remote Address" $ipNetAddr/$ipNetMask
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'DnsDomain'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                $Protocol = "Any"
                                Add-RuleProperty "Remote Address" $hostContainerItem.FirstChild.Data
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'DnsHost'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any" 
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                $Protocol = "Any"
                                Add-RuleProperty "Remote Address" $hostContainerItem.FirstChild.Data
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'Ip'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                $Protocol = "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'Icmp'
                            {
                                $global:HashProps = New-Object PSObject
                                Add-RuleProperty "DisplayName" $item.Name  
                                Add-RuleProperty "Interface Type" $interfaceType
                                Add-RuleProperty "Action" $Action
                                Add-RuleProperty "Direction" $Direction
                                Add-RuleProperty "Enabled" $Enabled  
                                Add-RuleProperty "Profile" "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                                Add-RuleProperty "Program" "Any"
                                $Protocol = "ICMPv4"
                                Add-RuleProperty "Protocol" $Protocol
                                Add-RuleProperty "Remote Address" "Any"
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            Default
                            {
                                #nothing to see here
                            }

                        }    
                    }
                    else
                    {
                        $rawProtocol = $hostContainerItem.FirstChild
                        switch($hostContainerItem.LocalName)
                        {
                            'IpAddress'
                            {
                                $Protocol = "Any"
                                Add-RuleProperty "Remote Address" $hostContainerItem.FirstChild.Data
                            }
                            'IpRange'
                            {
                                $Protocol = "Any"
                                foreach($rangeItem in $hostContainerItem.Attributes)
                                {
                                    switch($rangeItem.Name)
                                    {
                                        'Start'
                                        {
                                            $ipRangeStart = $rangeItem.Value
                                        }
                                        'End'
                                        {
                                            $ipRangeEnd = $rangeItem.Value
                                        }
                                    }
                                }
                                Add-RuleProperty "Remote Address" $ipRangeStart-$ipRangeEnd
                            }
                            'SubNet'
                            {
                                $Protocol = "Any"
                                foreach($rangeItem in $hostContainerItem.Attributes)
                                {
                                    switch($rangeItem.Name)
                                    {
                                        'NetAddr'
                                        {
                                            $ipNetAddr = $rangeItem.Value
                                        }
                                        'NetMask'
                                        {
                                            $ipNetMask = $rangeItem.Value
                                        }
                                    }
                                }
                                Add-RuleProperty "Remote Address" $ipNetAddr/$ipNetMask
                            }
                            'DnsDomain'
                            {
                                $Protocol = "Any"
                                Add-RuleProperty "Remote Address" $hostContainerItem.FirstChild.Data
                                CreateRule $global:HashProps
                                $global:FwRuleCreated = "true"
                            }
                            'DnsHost'
                            {   
                                $Protocol = "Any"
                                Add-RuleProperty "Remote Address" $hostContainerItem.FirstChild.Data
                            }
                            'Ip'
                            {
                                $Protocol = "Any"
                                Add-RuleProperty "Local Port" "Any"
                                Add-RuleProperty "Remote Port" "Any"
                            }
                            'Icmp'
                            {
                                $Protocol = "ICMPv4"
                            }
                            'LocalPort'
                            {
                                $localPort = $protocolItem.Value
                                Add-RuleProperty "Local Port" $localPort
                                $Protocol = "Any"
                            }
                            'RemotePort'
                            {
                                $RemotePort = $protocolItem.Value
                                Add-RuleProperty "Remote Port" $RemotePort
                                $Protocol = "Any"
                            }
                            Default
                            {
                                #nothing to see here
                            }
                        }                              
                    }                        
                Add-RuleProperty "Protocol" $Protocol
                }
            }   
        }
    }
    catch
    {
        #nothing to see here
    }    
}

function Process-FwApplicationTrigger
{
    try
    {
        if($FwApplicationTrigger.Count -gt 0)
        {
            $ObjReference = $FwApplicationTrigger[0]
            foreach ($obj in $ObjReference) 
            {
                $ns = New-Object System.Xml.XmlNamespaceManager($sourceRules.NameTable);
                $ns.AddNamespace("ns", $sourceRules.DocumentElement.NamespaceURI)
                $SoApplicationContainer = $FwApplicationTrigger.ChildNodes
                $appContainer = $SoApplicationContainer.ChildNodes
                foreach ($appItem in $appContainer) 
                {
                    if($appItem.LocalName -eq "Executable")
                    {
                        $appAttributes = $appItem.Attributes
                        foreach($attributeItem in $appAttributes)
                        {
                            if($attributeItem.Name -eq "FileName")
                            {
                                if($appContainer.count -gt 1)
                                {
                                    $global:HashProps = New-Object PSObject
                                    Add-RuleProperty "DisplayName" $item.Name  
                                    Add-RuleProperty "Interface Type" $interfaceType
                                    Add-RuleProperty "Action" $Action
                                    Add-RuleProperty "Direction" $Direction
                                    Add-RuleProperty "Enabled" $Enabled  
                                    Add-RuleProperty "Profile" "Any"
                                    Add-RuleProperty "Program" $attributeItem.Value
                                    Add-RuleProperty "Protocol" "Any"
                                    Add-RuleProperty "Remote Port" "Any"
                                    Add-RuleProperty "Local Port" "Any"
                                    Add-RuleProperty "Remote Address" "Any"
                                    CreateRule $global:HashProps
                                    $global:FwRuleCreated = "true"
                                }
                                else
                                {
                                    Add-RuleProperty "Program" $attributeItem.Value
                                    Add-RuleProperty "Protocol" "Any"
                                    Add-RuleProperty "Remote Port" "Any"
                                    Add-RuleProperty "Local Port" "Any"
                                    Add-RuleProperty "Remote Address" "Any"
                                }
                            }    
                        }
                    }                
                }
            }
        }   
    }
    catch
    {
        #Write-Host "Protocol not present"
    }
}

function ProcessItem
{
    param($item)
    Write-Host "Capturing rule $i of $($item.ParentNode.ChildNodes.Count) - $($item.Name)" -ForegroundColor Cyan
    $global:FwRuleCreated = "false"
    if($item.ToString() -eq "FirewallRule")
    {
        try 
        {
            $global:HashProps = New-Object PSObject
            $itemNetworkInterfaceTrigger = $item.GetElementsByTagName("FwNetworkInterfaceTrigger")
            $itemNetworkInterfaceGroup = $itemNetworkInterfaceTrigger.GetElementsByTagName("ObjReference")
            $InterfaceType = GetFwNetworkInterfaceGroup($itemNetworkInterfaceGroup.Attributes.GetNamedItem("TargetId").value)
            $Enabled = $item.Attributes.GetNamedItem("Enable").value
            $Direction = $item.Attributes.GetNamedItem("RuleType").value
            $PacketProcess = $item.GetElementsByTagName("PacketProcess")
            $Action = $PacketProcess.Attributes[0].Value
        }
        catch 
        {
            Write-Host $_.Exception.Message -ForegroundColor Red       
        }
        if($interfaceType -eq "ALL")
        {
            $InterfaceType = "Any"
            Add-RuleProperty "Interface Type" "Any"
        }
        else
        {
            $InterfaceType = "Any"
            Add-RuleProperty "Interface Type" "Any"
        }
        if($Enabled = 1)
        {
            $Enabled = "True"
            Add-RuleProperty "Enabled" "True"
        }
        else
        {
            $Enabled ="False"
            Add-RuleProperty "Enabled" "False"   
        }
        if($Direction = "N")
        {
            $Direction = "Outbound"
            Add-RuleProperty "Direction" "Outbound"
        }
        else
        {
            $Direction = "Inbound"
            Add-RuleProperty "Direction" "Inbound"
        }
        if($Action -eq "PASS")
        {
            $Action = "Allow"
            Add-RuleProperty "Action" "Allow"
        }
        else
        {
            $Action = "Block"
            Add-RuleProperty "Action" "Block"    
        }
        Add-RuleProperty "Profile" "Any"
        Add-RuleProperty "DisplayName" $item.Name

        $FwServiceTrigger = $item.GetElementsByTagName("FwServiceTrigger")
        $FwHostTrigger = $item.GetElementsByTagName("FwHostTrigger")
        $FwApplicationTrigger = $item.GetElementsByTagName("FwApplicationTrigger")
        
        if($FwServiceTrigger.Count -gt 0)
        {
            Process-FwServiceTrigger
        }
        if($FwHostTrigger.Count -gt 0 -and $FwHostTrigger[0].ChildNodes.Name[1] -eq "RemoteHostTrigger")
        {
            Process-FwHostTrigger
        }
        if($FwApplicationTrigger.Count -gt 0)
        {
            Process-FwApplicationTrigger
        }
        if($global:FwRuleCreated -eq 'false')
        {
            Add-RuleProperty "Program" "Any"
            Add-RuleProperty "Local Port" "Any"
            Add-RuleProperty "Remote Port" "Any"
            Add-RuleProperty "Protocol" "Any"
            Add-RuleProperty "Remote Address" "Any"
            CreateRule $global:HashProps
        }
        Write-Host "Success." -ForegroundColor Green
        Write-Host    
    }
}

##################################################################################################################
# Begin Script
##################################################################################################################

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
StartScript
$i = 1
$firewallRules = @()

<# This section will export the MacOS firewall rules, reserved for future use
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
Write-Host "Reading SEP Enforced Windows FW rules and exporting..." -ForegroundColor White
Write-Host "*************************************************************************************" -ForegroundColor White
Write-Host

$i = 1
foreach($item in $sourceRules.SchemaContainer.FwFirewallPolicy.FirewallRuleSystem.EnforcedFirewallRuleArray.FirewallRule)
{
    ProcessItem $item
    $i = $i + 1
}

$global:firewallRules | ConvertTo-CSV -NoTypeInformation -Delimiter '~' | Set-Content $scriptDir\output.txt

closescript 0
