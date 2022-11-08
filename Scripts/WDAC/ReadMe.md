# Microsoft Defender Application Control
Here are a few things acquired while testing and developing MDAC for non-persistent VDI!

# Java
Some customers still use the Java ActiveX control add-in in Internet Explorer.  When you create an MDAC CI policy, sites that use the control stop working.  It was my experience that you need to whitelist the control, and the binaries to allow the sites to function.  Whitelisting the Java ActiveX control requires a couple of things.  I will step through them here.  First the Java controls must be whitelisted via COM object registration by adding the following section to the MDAC xml policy that is generated:

```xml
<Settings>
    <Setting Provider="IE" Key="{08B0E5C0-4FCB-11CF-AAA5-00401C608501}" ValueName="EnterpriseDefinedClsId">
      <Value>
        <Boolean>true</Boolean>
      </Value>
    </Setting>
    <Setting Provider="IE" Key="{761497BB-D6F0-462C-B6EB-D4DAF1D92D43}" ValueName="EnterpriseDefinedClsId">
      <Value>
        <Boolean>true</Boolean>
      </Value>
    </Setting>
    <Setting Provider="IE" Key="{DBC80044-A445-435B-BC74-9C25C1C588A9}" ValueName="EnterpriseDefinedClsId">
      <Value>
        <Boolean>true</Boolean>
      </Value>
    </Setting>
    <Setting Provider="IE" Key="{A500A600-5B69-4011-AC50-5ACB97D04B72}" ValueName="EnterpriseDefinedClsId">
      <Value>
        <Boolean>true</Boolean>
      </Value>
    </Setting>
    <Setting Provider="IE" Key="{8ad9c840-044e-11d1-b3e9-00805f499d93}" ValueName="EnterpriseDefinedClsId">
      <Value>
        <Boolean>true</Boolean>
      </Value>
    </Setting>
    <Setting Provider="IE" Key="{00000000-0000-0000-0000-000000000000}" ValueName="EnterpriseDefinedClsId">
      <Value>
        <Boolean>true</Boolean>
      </Value>
    </Setting>
</Settings>
```
The GUIDs above in the policy can be obtained by re-producing the failure on a machine and checking the event viewer, specifically the Applications and Services/Microsoft/Windows/AppLocker/MSI and Script log.  Once you’ve gathered all of the GUIDs being blocked by the failure re-pro you can add them to the xml policy like above.

Whitelisting the COM object registration of the Java ActiveX control is not enough to allow the Java control to function, you must also whitelist the actual Java binaries.  Creating a new code integrity (CI) policy with Java already installed (like we have been doing) does not work, you must whitelist them by file path.  Whitelisting by file path is only available in Windows 10 1903 and above.  1903 also brings new functionality of using base and supplemental CI policies.  I created a base policy as before and added the COM object registration section to it.  I then created a supplemental policy for file path based rules that contains the following:
```xml
<FileRules>
    <Allow ID="ID_ALLOW_A_1" FriendlyName="C:\Program Files (x86)\Java\* FileRule" MinimumFileVersion="0.0.0.0" FilePath="C:\Program Files (x86)\Java\*" />
</FileRules>
```
MDAC CI policies are also applied differently in Windows 10 1903, the policy must be renamed to the PolicyID of the policy, this is contained within the source XML of each policy; and it must be placed in the following directory:
```
C:\Windows\System32\CodeIntegrity\CiPolicies\Active
```
Once I had the COM object registration and the Java binaries whitelisted, the website in question loaded the java content and rendered the page.

# Your mileage may vary.

Deploy multiple CI policies:<br />
https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/deploy-multiple-windows-defender-application-control-policies

COM Object Registration:<br />
https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/allow-com-object-registration-in-windows-defender-application-control-policy

Windows 10 1903+ File based Path Rules:<br />
https://docs.microsoft.com/en-us/windows/whats-new/whats-new-windows-10-version-1903
