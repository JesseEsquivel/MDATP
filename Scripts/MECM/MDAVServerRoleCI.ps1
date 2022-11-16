#Windows Server Defender Antivirus Features detection script
#Script created by Clive Northey (MCS) Clive.Northey@microsoft.com
#Date Created 9/28/2022

#Get Operating System Name details
$server2016 = (Get-WMIObject win32_operatingsystem).Caption
$server2016 = $server2016 -match 'Server 2016'
$server2019 = (Get-WMIObject win32_operatingsystem).Caption
$server2019 = $server2019 -match 'Server 2019'

if ($server2019)
{
     $defenderFeature = Get-windowsfeature | Where-Object {$_.Name -eq "Windows-Defender"}
     if ($defenderFeature.Installed -eq $true)
     #Defender Features installed
     {
        return $true
     }
     else
     #Defender Features not installed
     {
        return $false
     }
}
elseif ($server2016)
{
    $defenderFeature = Get-windowsfeature | Where-Object {$_.Name -eq "Windows-DefenderFeatures"}
    $defender = Get-windowsfeature | Where-Object {$_.Name -eq "Windows-Defender"}
    $defenderGUI = Get-WindowsFeature | Where-Object {$_.Name -eq "Windows-Defender-GUI"}
    if ($defenderFeature.Installed -eq $true -and $defender.Installed -eq $true -and
    $defenderGUI.Installed -eq $true)

    #Defender Features installed
    {
        return $true
    }
    else
    #Defender Features not installed
    {
        return $false
    }
}
