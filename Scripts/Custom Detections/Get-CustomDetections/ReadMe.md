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

### Sign in as a specific account

When Edge selects an unintended account, use `-UserPrincipalName` to request
interactive Microsoft sign in for the account you need. The username is supplied
at runtime; no real user, tenant, or organization identifiers are built into the
examples.

From the script folder in PowerShell 7, replace both placeholders and run:

```powershell
pwsh -NoProfile -File .\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -UserPrincipalName 'user@example.invalid' -LoginTimeoutSeconds 600 -CaptureSeconds 60 -Verbose
```

Replace `user@example.invalid` with your own full sign in email. The leading
`pwsh -NoProfile -File` creates a fresh PowerShell process, avoiding conflicts
with C# helper types already loaded by earlier versions of the exporter.

1. Complete sign in and any required MFA in the Edge window opened by the script.
2. Open the account menu inside the Defender webpage, not the Edge toolbar.
3. When PowerShell prompts, enter the email actually displayed in that menu.
   Enter `CANCEL` if the account is incorrect.

This mode uses a new isolated profile for each run. Do not combine it with
`-SelectEdgeProfile`, `-EdgeProfileDirectory`, or `-ResetProfile`. If you supply
`-ProfilePath`, the directory must not already exist. InPrivate mode is not used.

For recognized main frame Microsoft authorization requests, the script sets
`prompt=login` and `login_hint` while retaining the existing client, redirect,
tenant, state, nonce, scopes, and PKCE parameters. It does not change Windows
accounts, shared host policies, or other users' Edge processes. The original
portal and Microsoft authority endpoints remain unchanged.

The username is a sign in hint, not an authorization override. Account
confirmation is manual, not automatic verification of the authenticated
principal. Organization policies still apply. If no supported interactive
authorization request is observed before the timeout, or the confirmed email
does not match, the script stops without exporting rules.

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

Close Edge windows in your own Windows session, then run the interactive profile selector:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -SelectEdgeProfile
```

The selector displays each profile's friendly name and directory. For an unattended run, specify the directory directly:

```powershell
.\Get-CustomDetections.ps1 -TenantId '<tenant-guid>' -SelectEdgeProfile -EdgeProfileDirectory 'Profile 2'
```

The source Edge profile isn't modified or deleted.
On a shared Windows host, Edge processes in other Windows sessions do not block
this import check. Concurrent use of the same source profile is not supported;
file copy failures are still reported.

## Understand profile storage and security

By default, the isolated Edge profile is stored at:

```text
%LOCALAPPDATA%\Get-CustomDetections\EdgeProfile
```

This directory is outside the project and can contain authentication cookies, tokens, local storage, session storage, browsing data, and other profile artifacts. Treat the directory as sensitive. Authentication headers, cookies, and passwords aren't written to the export files.

With `-UserPrincipalName`, the default directory is a unique
`%LOCALAPPDATA%\Get-CustomDetections\TargetUser-<random-id>` folder. It remains on
disk unless `-RemoveCachedProfile` is supplied. This can leave multiple sensitive
profile folders after multiple runs; use the cleanup switch when retention is
not required.

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
| `-UserPrincipalName` | No | Disabled | Requests interactive sign in for this email using a new isolated profile and requires manual confirmation of the account shown in Defender before export. |
| `-DetectionNames` | No | All rules | Exact rule names to export. Accepts a comma-delimited string or PowerShell string array. `-CustomDetectionNames` is an alias. |
| `-OutputPath` | No | `exports\<timestamp>` | Export destination. A relative path is resolved from the current PowerShell location. |
| `-ProfilePath` | No | `%LOCALAPPDATA%\Get-CustomDetections\EdgeProfile` | Isolated Edge profile directory. With `-UserPrincipalName`, defaults to a unique folder and must not already exist. This location can contain cached authentication artifacts. |
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

To refresh the isolated profile from a source profile, close Edge windows in your own Windows session and run:

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

The unified list can contain entries that the Defender rule detail endpoint
cannot retrieve, including Sentinel analytics rules. This change does not add
Sentinel export support or suppress HTTP 404 responses. Successful rule files
are retained, failures are recorded in `manifest.json`, and the overall export
is still reported as incomplete. A 404 alone does not establish a rule's source.

## Local regression checks

Run the synthetic checks in a fresh PowerShell 7 process:

```powershell
pwsh -NoProfile -File .\Test-TargetUser.ps1
```

These checks do not open Edge or contact Microsoft services. They cover
authorization URL handling, parameter preservation, unrelated host rejection,
main frame scoping, manual account confirmation, existing capture behavior,
invalid parameter combinations, and the Windows session scoped import check.
They do not replace testing against the target portal and organization policies.
