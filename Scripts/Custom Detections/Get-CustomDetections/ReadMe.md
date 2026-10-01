# Get-CustomDetections

`Get-CustomDetections.ps1` exports Microsoft Defender XDR custom detection rules from the DoD Defender XDR portal since the Microsoft Graph beta API, specifically the get detection-rule method isn't available. It saves each complete rule as JSON and writes its query to a separate KQL file.

The self-contained script supports Windows PowerShell 5.1 and PowerShell 7. It requires no PowerShell modules, browser drivers, or supporting source files.

## Requirements

- Microsoft Edge
- Access to the target Microsoft Defender XDR tenant
- Windows PowerShell 5.1 or PowerShell 7

## Run the exporter

Run the script with the Microsoft Entra tenant ID:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>'
```

Complete sign-in in the Edge window when prompted. Edge closes automatically when the export finishes.

To export specific rules, provide their exact names as a comma-delimited value:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -DetectionNames 'Rule One,Rule Two'
```

You can also provide the names as a PowerShell string array:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -DetectionNames 'Rule One','Rule Two'
```

Rule-name matching is case-insensitive and exact. Space-delimited input isn't supported because rule names can contain spaces. If any requested name isn't found, the script reports the missing name and doesn't report the export as complete.

## Select an Edge profile

Modern Edge versions block remote debugging against the primary Edge user-data directory. To use an existing Edge sign-in, the script copies the selected profile into an isolated profile.

Close all Edge windows, then run the interactive profile selector:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -SelectEdgeProfile
```

The selector displays each profile's friendly name and directory. For an unattended run, specify the directory directly:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -SelectEdgeProfile -EdgeProfileDirectory 'Profile 2'
```

The source Edge profile isn't modified or deleted.

## Understand profile storage and security

By default, the isolated Edge profile is stored at:

```text
%LOCALAPPDATA%\Get-CustomDetections\EdgeProfile
```

This directory is outside the project and can contain authentication cookies, tokens, local storage, session storage, browsing data, and other profile artifacts. Treat the directory as sensitive. Authentication headers, cookies, and passwords aren't written to the export files.

The isolated profile remains on disk after a normal run so its sign-in session can be reused when the same profile is selected again. Use one of these cleanup options:

- `-ResetProfile` deletes the isolated profile before the run. The run then creates or imports a new profile.
- `-RemoveCachedProfile` deletes the isolated profile after the run, including when the export fails. The next run requires profile selection or interactive sign-in.

To remove cached authentication artifacts after an export, run:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -SelectEdgeProfile -RemoveCachedProfile
```

## Parameters

| Parameter | Required | Default | Description |
|---|---:|---|---|
| `-TenantId` | Yes | None | Microsoft Entra tenant ID used to build the Defender portal URL. The value must be a GUID. |
| `-DetectionNames` | No | All rules | Exact rule names to export. Accepts a comma-delimited string or PowerShell string array. `-CustomDetectionNames` is an alias. |
| `-OutputPath` | No | `exports\<timestamp>` | Export destination. A relative path is resolved from the current PowerShell location. |
| `-ProfilePath` | No | `%LOCALAPPDATA%\Get-CustomDetections\EdgeProfile` | Isolated Edge user-data directory. This location can contain cached authentication artifacts. |
| `-SelectEdgeProfile` | No | Disabled | Copies an existing Edge profile into the isolated profile. If `-EdgeProfileDirectory` is omitted, the script prompts for a profile. |
| `-EdgeProfileDirectory` | No | Interactive selection | Edge profile directory to import, such as `Default` or `Profile 2`. Use with `-SelectEdgeProfile`. |
| `-LoginTimeoutSeconds` | No | `300` | Seconds to wait for authentication and the Custom detections page to load. Valid range: 30–1,800. |
| `-CaptureSeconds` | No | `20` | Seconds to wait for the portal's rule-list request after the page loads. Valid range: 5–120. |
| `-RemoveCachedProfile` | No | Disabled | Deletes the isolated profile after the run, including after a failure. |
| `-ResetProfile` | No | Disabled | Deletes the isolated profile before the run. When used with `-SelectEdgeProfile`, the selected source profile is imported again. |

To choose a different export directory, run:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -OutputPath C:\SecureExports\CustomDetections
```

To allow more time for interactive authentication, run:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -LoginTimeoutSeconds 600
```

To refresh the isolated profile from a source profile, close all Edge windows and run:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -SelectEdgeProfile -EdgeProfileDirectory 'Profile 2' -ResetProfile
```

## Review the export

Each run creates:

- `manifest.json`: Export metadata, completion status, requested names, errors, and file indexes.
- `rules\*.json`: One complete JSON document for each exported custom detection rule.
- `rules\*.kql`: Query text for each rule with the portal's original line endings.
- `captures\rule-details.json`: Combined full rule responses.
- `captures\rules-unified.json`: Rule-list response used to identify available rules.
- Other `captures\*.json` files: Relevant portal response bodies retained for troubleshooting.

No browser profile, cache, cookies, or authentication headers are written beneath the project directory. Treat the exports as security-sensitive because rule queries and configuration can reveal details about the environment.

## Current limitation

The exporter uses the Defender portal's internal requests because the supported Microsoft Graph API isn't available in the DoD environment. These portal endpoints aren't a public API and can change. If the response schema changes, the script retains relevant response bodies in `captures` and fails explicitly instead of reporting a successful export.
