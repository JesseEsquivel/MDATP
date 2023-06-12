# Non-Persistent VDI On-Boarding
This is a script used in MDT to enable first boot intelligence updates, set minimal WDAV settings, and onboard the VDI system into the MDATP tenant.  Simply call the powershell script during your VDI "master" imaging process.  Hopefully you are using MDT ; )

# Security Intelligence Packages for Non-Persistent VDI
Be mindful of the file path when setting up your file share that will house the updates.  It MUST contain the "x64" directory and the MPAM-FE.exe must be in that directory or clients will fail to update.  The other script you can use to run as a job to fetch the packages at an interval.

# VDI Machines Not Reporting Telemetry?
Ensure that you are not disabling the DiagTrack service as part of your VDI optimizations.  We were disabling this as part of the Windows 10 1803+ VDI optimization script.  This breaks telemetry, make sure DiagTrack is set to Automatic (Delayed Start) and is running. **Note DiagTrack Dependency was renmoved in RS5 and is no longer needed.
