# MDE Windows 10/11 USB Storage Device Control
Policies can be written in xml and applied via GPO or Intune. 

- MDE USB storage device control:<br>
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-removable-storage-access-control?view=o365-worldwide

- MDE USB storage device control reporting:<br>
  https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-report?view=o365-worldwide

### XML Samples for USB device control
These sample files are for a granular removable storage device control policy:

- Only this user
- Only this machine
- Only this device

The scenario is to only allow specic users, with specific USB storage drives, to be used only on specific machines. The xml policy can leverage on premise active directory groups for the authorized users and computers. The most efficient way to handle the assignment of users and devices is to add them to an active directory group and define the group in the xml policy. The sections below will detail the critical parts of the xml and how to configure them.

### Check Prerequisites
Device control is dependent on a Defender AV minimum platform version. The floor is platform **4.18.2103.3**. As long as you have this version or later, preferably the most up to date. Check for the platform version using the Get-MpComputerStatus powershell cmdlet:

<br>![image](https://user-images.githubusercontent.com/33558203/188165129-d6831311-c7a7-4d10-93b0-b9773e8622ec.png)<br>

If you don't have this version deploy [KB4052623](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/manage-updates-baselines-microsoft-defender-antivirus?view=o365-worldwide) or run Windows update. Device control also requires an E3 or E5 license to enable it. The license check for E3 is done via Intune, and if deploying via GPO the E5 check is to ensure the device is onboarded into Defender for Endpoint. 

### Identifying Removable Devices
The "[DescriptorIdList]([url](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-removable-storage-access-control?view=o365-worldwide#removable-storage-group))" property defines the attributes that can be used to identify a USB removable storage device. Before embarking on your removable storage device journey it is reccomended to have the drives that you want to explicitly allow and a test machine that you're able to plug them into.

The first value to obtain is the "DeviceInstancePath" value from the Windows device manager. Plug the device into a test machine, open the device manager, expand disk drives, and locate the device. Click the details tab and select the "Device instance path" property.

<br>![image](https://user-images.githubusercontent.com/33558203/187995544-9cfc7773-e63f-42af-a14f-94ebf6e4bee5.png)<br>

Copy this value as it will be used to derive the BusId, DeviceId, and the SerialNumberId attribute values. This is value from the device manager:

**USBSTOR\DISK&VEN_KINGSTON&PROD_DATATRAVELER_2.0&REV_PMAP\C860008861D7EF41CA13157C&0**

<br>![image](https://user-images.githubusercontent.com/33558203/187998604-b1027c3c-ba2d-47f9-8cc8-233e3a63cfae.png)<br>

Extract the BusId, DeviceId, and the SerialnumberId from this value:

```xml
PrimaryId - RemovableMediaDevices
InstancePathId - USBSTOR\DISK&VEN_KINGSTON&PROD_DATATRAVELER_2.0&REV_PMAP\C860008861D7EF41CA13157C&0
DeviceId - USBSTOR\DISK&VEN_KINGSTON&PROD_DATATRAVELER_2.0&REV_PMAP<br>
HardwareId - 
FriendlyNameId - 
BusId - USBSTOR
SerialNumberId - C860008861D7EF41CA13157C&0
VID_PID - 
```

PrimaryId can be one of four values:

- RemovableMediaDevices
- CdRomDevices
- WpdDevices
- PrinterDevices
  
The HardwareId, FriendlyNameId, and VID_PID can be extracted from the device manager, here is the map:

| Device Manager | Device Control |
| :-:            | :-:            |
| Hardware Ids   | HardwareId     |
| Friendly name  | FriendlyNameId |
| Parent         | VID_PID        |

The VDI_PID must be extracted from the "Parent" value in device manager:

<br>![image](https://user-images.githubusercontent.com/33558203/188000472-a10daed0-1e6c-48aa-acce-edbd9de20122.png)<br>

The VID_PID extracted here would be "**VID_0930&PID_6545**"

Now that we have all possible values extracted you can choose which of these you want to use as a matching identifier for the device. Here are all of the values for this Kingston device:

```xml
PrimaryId - RemovableMediaDevices
InstancePathId - USBSTOR\DISK&VEN_KINGSTON&PROD_DATATRAVELER_2.0&REV_PMAP\C860008861D7EF41CA13157C&0
DeviceId - USBSTOR\DISK&VEN_KINGSTON&PROD_DATATRAVELER_2.0&REV_PMAP
HardwareId - USBSTOR\DiskKingstonDataTraveler_2.0PMAP
FriendlyNameId - Kingston DataTraveler 2.0 USB Device
BusId - USBSTOR
SerialNumberId - C860008861D7EF41CA13157C&0
VID_PID - "VID_0930&PID_6545"
```

Notice the pretty red above? The & character needs to be escaped in xml like so:
 
```xml
PrimaryId - RemovableMediaDevices
InstancePathId - USBSTOR\DISK&amp;VEN_KINGSTON&amp;PROD_DATATRAVELER_2.0&amp;REV_PMAP\C860008861D7EF41CA13157C&amp;0
DeviceId - USBSTOR\DISK&amp;VEN_KINGSTON&amp;PROD_DATATRAVELER_2.0&amp;REV_PMAP
HardwareId - USBSTOR\DiskKingstonDataTraveler_2.0PMAP
FriendlyNameId - Kingston DataTraveler 2.0 USB Device
BusId - USBSTOR
SerialNumberId - C860008861D7EF41CA13157C&amp;0
VID_PID - "VID_0930&amp;PID_6545"
```
So there you have it in the above table, these are all of the possible values you can use as a matching identifier in your device control policy. There is one last thing. The very last integer value in the InstancePathId value is the USB slot number, which can change when a device is plugged and unplugged. Therefore a wildcard should be used to accomdate for the potentially variable slot number:

```xml
InstancePathId - USBSTOR\DISK&amp;VEN_KINGSTON&amp;PROD_DATATRAVELER_2.0&amp;REV_PMAP\C860008861D7EF41CA13157C&amp;*
```

## Groups XML
The groups xml consists of two groups, broken down below.

### Group 1

The first group blocks any removable storage, CD/DVD, or WPD device. Note the match type of "MatchAny," you will want to use this if you are blocking multiple device type categories. You can also block printers by adding that type here if required. The available properties for the removable storage groups are [here](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-removable-storage-access-control?view=o365-worldwide#removable-storage-group).

```xml
<!--Group 1: Block Any removable storage, CD/DVD, or WPD device -->
	<Group Id="{9b28fae8-72f7-4267-a1a5-685f747a7146}">
	  <!-- ./Vendor/MSFT/Defender/Configuration/DeviceControl/PolicyGroups/%7b9b28fae8-72f7-4267-a1a5-685f747a7146%7d/GroupData -->
		<MatchType>MatchAny</MatchType>
		<DescriptorIdList>
			<PrimaryId>RemovableMediaDevices</PrimaryId>
			<PrimaryId>CdRomDevices</PrimaryId>
			<PrimaryId>WpdDevices</PrimaryId>
		</DescriptorIdList>
	</Group>
```
### Group 2

The second group allows approved USB devices based on device property. This is where you will place the attribute values of the approved devices that you gathered above. You can use any property available in the [xml schema](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-removable-storage-access-control?view=o365-worldwide#removable-storage-group) to identify the device. Note the match type of "MatchAny," you'll want to use this if you have multiple approved USB devices. In this example we ran through a couple of USB drives we had, including an Iron Key device.

```xml
<!-- Group 2: Allow Approved USBs based on device properties -->
	<Group Id="{65fa649a-a111-4912-9294-fb6337a25038}">
		<MatchType>MatchAny</MatchType>
		<DescriptorIdList>
            <!--This is your allow hardware list, add entries for allowed devices here based on the DescriptorIdList property schema-->
	          <InstancePathId>USBSTOR\DISK&amp;VEN_KINGSTON&amp;PROD_DATATRAVELER_2.0&amp;REV_PMAP\C860008861D7EF41CA13157C&amp;*</InstancePathId>
            <InstancePathId>SCSI\DISK&amp;VEN_G-TECH&amp;PROD_ARMORATD\6&amp;2054B149&amp;0&amp;*</InstancePathId>
            <InstancePathId>USBSTOR\DISK&amp;VEN_IMATION&amp;PROD_IRONKEY_PUBLIC&amp;REV_0303\17166275&amp;*</InstancePathId>
            <InstancePathId>USBSTOR\DISK&amp;VEN_IMATION&amp;PROD_IRONKEY_SECURE&amp;REV_0303\17166275&amp;*</InstancePathId>
            <InstancePathId>USBSTOR\DISK&amp;VEN_STT&amp;PROD_EXPRESS_RC8&amp;REV_0\92134223000000000006&amp;*</InstancePathId>
            <InstancePathId>USBSTOR\DISK&amp;VEN_SANDISK&amp;PROD_CRUZER_GLIDE&amp;REV_1.26\200542560211B4208B1B&amp;*</InstancePathId>
		</DescriptorIdList>
	</Group>
```
Both of these groups should be enclosed in a <Groups></Groups> tag. Save the DeviceControlGroups.xml file to a test machine to do some quick testing.

## Policy XML
The policy XML consists of two policy rules as well, broken down below.

### Policy 1

This first policy rule allows and audits write access to approved USBs. This is where you will put the Sids of the active directory groups for the allowed users and computers. Two things to note, the options tag and the AccessMask tag. These are defined in the [access control](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-removable-storage-access-control?view=o365-worldwide#access-control-policy) section of the XML schema. The Access mask is a bitmask value where you will AND the number for the settings you want. For example the Access mask of **63** below is:

Disk level Access<br>
	1: Read<br>
	2: Write<br>
	4: Execute<br>

File system level access<br>
	8: File system read<br>
	16: File system write<br>
	32: File system execute<br>
---------------------------<br>
        63

For the second entry id we're not auditing read actions as this becomes very noisy, hence we are using the bitmask of **54** for the AccessMask value.

```xml
<!-- Policy 1: Allow/Audit write and execute access to allowed USBs -->
    <PolicyRule Id="{36ae1037-a639-4cff-946b-b36c53089a4c}">
        <!-- ./Vendor/MSFT/Defender/Configuration/DeviceControl/PolicyRules/%7b36ae1037-a639-4cff-946b-b36c53089a4c%7d/RuleData -->
        <Name>Audit write and execute access to approved USBs</Name>
        <IncludedIdList>
            <GroupId>{65fa649a-a111-4912-9294-fb6337a25038}</GroupId>
        </IncludedIdList>
        <ExcludedIdList></ExcludedIdList>
        <Entry Id="{a0bcff88-b8e4-4f48-92be-16c36adac930}">
            <Type>Allow</Type>
            <Options>0</Options>
            <AccessMask>63</AccessMask>
            <Sid>S-1-5-21-4160335514-3859470241-1414062150-3603</Sid><!-- AD user group objectSid attribute value, place users with an ETP in this -->
            <ComputerSid>S-1-5-21-4160335514-3859470241-1414062150-360</ComputerSid><!-- AD computer group objectSid attribute value, place authorized users computers in this -->
        </Entry>
        <Entry Id="{4a17df0b-d89d-430b-9cbe-8e0721192281}">
            <Type>AuditAllowed</Type>
            <Options>2</Options>
            <AccessMask>54</AccessMask>
        </Entry>
    </PolicyRule>
```

### Policy 2

The second policy rule blocks read, write, and execute access and also audits allow access on approved USBs. A few things to note here:

- The IncludedIdList property, this GUID for the GroupId must match the group "Block Any removable storage, CD/DVD, or WPD device" in the groups xml
- The ExcludedIdList property, thid GUID for the GroupId must match the allow group "Allow Approved USBs based on device properties" in the groupd xml
- This is your deny policy, and define the level with the AccessMask property. This policy is set to 7 which is deny read, write, execute
- Define auditing for your deny events, the option of "**3**" is show toast notification and send event, AccessMask for this is also 7 which is read, write, execute
- The Name property in this policy is **the string that shows up in your toast notification on your endpoints**, customize this accordingly

```xml
<!--Policy 2: Block read, write, and execute access, and audit but allow approved USBs-->
        <PolicyRule Id="{c544a991-5786-4402-949e-a032cb790d0e}">
        <!-- ./Vendor/MSFT/Defender/Configuration/DeviceControl/PolicyRules/%7bc544a991-5786-4402-949e-a032cb790d0e%7d/RuleData -->
        <Name>"USB removable storage devices"</Name> <!-- This is the string that shows up in your toast notification -->
        <IncludedIdList>
            <GroupId>{9b28fae8-72f7-4267-a1a5-685f747a7146}</GroupId><!-- This must match the "Group 1: Block Any removable storage and CD/DVD" in the group xml -->
        </IncludedIdList>
        <ExcludedIdList>
            <GroupId>{65fa649a-a111-4912-9294-fb6337a25038}</GroupId><!-- This must match the "Group 2: Allow Approved USBs based on device properties" in the group xml -->
        </ExcludedIdList>
        <Entry Id="{75ff3d3a-e1dd-4fa0-8cdb-72e32a8c5462}">
            <Type>Deny</Type>
            <Options>0</Options>
            <AccessMask>7</AccessMask> <!-- BitMask value of 1: Read, 2: Write, 4: Execute -->
        </Entry>
        <Entry Id="{07e22eac-8b01-4778-a567-a8fa6ce18a0c}">
            <Type>AuditDenied</Type>
            <Options>3</Options>
            <AccessMask>7</AccessMask> <!-- BitMask value of 1: Read, 2: Write, 4: Execute -->
        </Entry>
    </PolicyRule>
```

### Group Policy Application
To enable device control in group policy configure the following settings with either the local group policy editor, or in a domain based group policy. More coming soon.


### PowerBI Template
Stay tuned.  😈
