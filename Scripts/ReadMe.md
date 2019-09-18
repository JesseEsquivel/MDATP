# MDATP
Microsoft Defender Advanced Threat Protection

# Tricky items
A collection of scripts and items used for non-persistent VDI onboarding, security intelligence updates, etc.

# Non-Persistnet VDI On-Boarding
This is a script used in MDT to enable first boot intelligence updates, set minimal WDAV settings, and onboard the VDI system into the MDATP tenant.  Simply call the powershell script during your imaging process.  Hopefully you are using MDT ; )

# Security Intelligence Packages for Non-Persistent VDI
Be mindful of the file path when setting up your file share that will house the updates.  It MUST contain the "x64" directory and the MPAM-FE.exe must be in that directory or clients will fail to update.  The other script you can use to run as a job to fetch the packages at an interval.

