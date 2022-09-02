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

<br>![image](https://user-images.githubusercontent.com/33558203/188161306-f3565659-4c3b-404c-98c1-413875b84daf.png)<br>

If you don't have this version deploy [KB4052623](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/manage-updates-baselines-microsoft-defender-antivirus?view=o365-worldwide) or run Windows update. Device control also requires an E3 or E5 license to enable it. The license check for E3 is done via Intune, and if deploying via GPO the E5 check is to ensure the device is onboarded into Defender for Endpoint. 

### Identifying Removable Devices
The "[DescriptorIdList]([url](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/device-control-removable-storage-access-control?view=o365-worldwide#removable-storage-group))" property defines the attributes that can be used to identify a USB removable storage device. Before embarking on your removable storage device journey it is reccomended to have the drives that you want to explicitly allow and a test machine that you're able to plug them into.

The first value to obtain is the "DeviceInstancePath" value from the Windows device manager. Plug the device into a test machine, open the device manager, expand disk drives, and locate the device. Click the details tab and select the "Device instance path" property.

<br>![image](https://user-images.githubusercontent.com/33558203/187995544-9cfc7773-e63f-42af-a14f-94ebf6e4bee5.png)<br>

Copy this value as it will be used to derive the BusId, DeviceId, and the SerialNumberId attribute values. This is value from the device manager:

**USBSTOR\DISK&VEN_KINGSTON&PROD_DATATRAVELER_2.0&REV_PMAP\C860008861D7EF41CA13157C&0**

<br>![image](https://user-images.githubusercontent.com/33558203/187998604-b1027c3c-ba2d-47f9-8cc8-233e3a63cfae.png)<br>

PrimaryId can be one of four values:

- RemovableMediaDevices
- CdRomDevices
- WpdDevices
- PrinterDevices

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

### Groups XML
Coming soon.

### Policy XML
Coming soon.

### Group Policy Application

### PowerBI Template
Stay tuned.  😈
