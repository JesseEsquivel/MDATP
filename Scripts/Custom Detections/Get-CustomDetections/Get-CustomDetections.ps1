<#
##################################################################################################################
#
# Microsoft Frontier Security Engineering
# Export custom detection rules from Microsoft Defender XDR portal
#
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

.SYNOPSIS
Exports Microsoft Defender XDR custom detection rules from the DoD portal.

.DESCRIPTION
Launches Microsoft Edge, uses the authenticated Defender portal session to
retrieve custom detection rules, and writes each complete rule configuration
and query to JSON and kql files. The script is self-contained and supports Windows
PowerShell 5.1.

.PARAMETER TenantId
Specifies the Microsoft Entra tenant ID used to open the Defender portal.
This parameter is required.

.PARAMETER DetectionNames
Specifies which custom detection rules to export by exact name. Provide either
a comma-delimited string or a PowerShell string array. Matching is
case-insensitive. Space-delimited input is not supported because rule names can
contain spaces. If omitted, all custom detection rules are exported.

.PARAMETER OutputPath
Specifies the export directory. The default is a timestamped directory beneath
the script's exports directory.

.PARAMETER ProfilePath
Specifies the isolated Edge user-data directory used by the exporter. The
default is %LOCALAPPDATA%\Get-CustomDetections\EdgeProfile.

.PARAMETER SelectEdgeProfile
Imports the Edge profile selected by EdgeProfileDirectory into the isolated
exporter profile. Close all Edge windows before the first import or a profile
reset. The source Edge profile is not modified.

.PARAMETER EdgeProfileDirectory
Specifies the Edge profile directory to import, such as Default or Profile 2.
If SelectEdgeProfile is specified and this parameter is omitted, the
script displays the available Edge profile names and prompts for a selection.

.PARAMETER LoginTimeoutSeconds
Specifies how long the script waits for authentication and the Custom
detections page to load. The default is 300 seconds.

.PARAMETER CaptureSeconds
Specifies how long the script waits for the portal's custom detection rule-list
request after the page loads. The default is 20 seconds.

.PARAMETER RemoveCachedProfile
Deletes the isolated Edge profile after the script completes, including when
the export fails. This removes cached authentication artifacts and requires
sign-in on the next run.

.PARAMETER ResetProfile
Deletes and recreates the isolated exporter profile. When combined with
SelectEdgeProfile, the selected source profile is imported again.

.EXAMPLE
.\Get-CustomDetections.ps1 -TenantId '00000000-0000-0000-0000-000000000000'

Exports every custom detection rule from the specified tenant.

.EXAMPLE
.\Get-CustomDetections.ps1 -TenantId '00000000-0000-0000-0000-000000000000' -DetectionNames 'Rule One,Rule Two'

Exports only Rule One and Rule Two using a comma-delimited value.

.EXAMPLE
.\Get-CustomDetections.ps1 -TenantId '00000000-0000-0000-0000-000000000000' -DetectionNames 'Rule One','Rule Two' -SelectEdgeProfile -EdgeProfileDirectory 'Profile 2'

Exports two selected rules after importing Profile 2 into the isolated Edge
profile.

.EXAMPLE
.\Get-CustomDetections.ps1 -TenantId '00000000-0000-0000-0000-000000000000' -SelectEdgeProfile -RemoveCachedProfile

Exports the rules, closes Edge, and removes the isolated profile and its
authentication artifacts.

.NOTES
The Defender portal's internal endpoints are not a public API contract and can
change. Exported rule queries and configuration should be treated as
security-sensitive.
#>

#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Guid]$TenantId,

    [Alias('CustomDetectionNames')]
    [string[]]$DetectionNames,

    [string]$OutputPath,

    [string]$ProfilePath,

    [switch]$SelectEdgeProfile,

    [ValidatePattern('^(Default|Profile \d+)$')]
    [string]$EdgeProfileDirectory,

    [ValidateRange(30, 1800)]
    [int]$LoginTimeoutSeconds = 300,

    [ValidateRange(5, 120)]
    [int]$CaptureSeconds = 20,

    [switch]$RemoveCachedProfile,

    [switch]$ResetProfile
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot ('exports\{0:yyyyMMdd-HHmmss}' -f (Get-Date))
}
if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
    $ProfilePath = Join-Path $env:LOCALAPPDATA 'Get-CustomDetections\EdgeProfile'
}
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$ProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)
$portalUrl = 'https://security.apps.mil/v2/custom_detection?tid={0}' -f
    [Uri]::EscapeDataString($TenantId.ToString('D'))

$cdpClientSource = @'
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Net.WebSockets;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace CustomDetections
{
    public sealed class CdpClient : IDisposable
    {
        private readonly ClientWebSocket socket = new ClientWebSocket();
        private readonly ConcurrentDictionary<int, TaskCompletionSource<string>> pending =
            new ConcurrentDictionary<int, TaskCompletionSource<string>>();
        private readonly ConcurrentQueue<string> events = new ConcurrentQueue<string>();
        private readonly CancellationTokenSource cancellation = new CancellationTokenSource();
        private int nextId;
        private Task receiveTask;

        public void Connect(string webSocketUrl, int timeoutMilliseconds)
        {
            Task connectTask = socket.ConnectAsync(new Uri(webSocketUrl), cancellation.Token);
            if (!connectTask.Wait(timeoutMilliseconds))
            {
                throw new TimeoutException("Timed out connecting to the Edge DevTools endpoint.");
            }

            receiveTask = Task.Run((Func<Task>)ReceiveLoop);
        }

        public string Call(string method, string parametersJson, int timeoutMilliseconds)
        {
            if (socket.State != WebSocketState.Open)
            {
                throw new InvalidOperationException("The Edge DevTools connection is not open.");
            }

            int id = Interlocked.Increment(ref nextId);
            var completion = new TaskCompletionSource<string>();
            if (!pending.TryAdd(id, completion))
            {
                throw new InvalidOperationException("Unable to register the DevTools command.");
            }

            string parameters = String.IsNullOrWhiteSpace(parametersJson) ? "{}" : parametersJson;
            string payload = "{\"id\":" + id +
                ",\"method\":\"" + EscapeJsonString(method) +
                "\",\"params\":" + parameters + "}";

            byte[] bytes = Encoding.UTF8.GetBytes(payload);
            Task sendTask = socket.SendAsync(
                new ArraySegment<byte>(bytes),
                WebSocketMessageType.Text,
                true,
                cancellation.Token);

            if (!sendTask.Wait(timeoutMilliseconds))
            {
                TaskCompletionSource<string> ignored;
                pending.TryRemove(id, out ignored);
                throw new TimeoutException("Timed out sending DevTools command: " + method);
            }

            if (!completion.Task.Wait(timeoutMilliseconds))
            {
                TaskCompletionSource<string> ignored;
                pending.TryRemove(id, out ignored);
                throw new TimeoutException("Timed out waiting for DevTools command: " + method);
            }

            return completion.Task.Result;
        }

        public bool TryTakeEvent(out string message)
        {
            return events.TryDequeue(out message);
        }

        private async Task ReceiveLoop()
        {
            byte[] buffer = new byte[65536];

            try
            {
                while (!cancellation.IsCancellationRequested && socket.State == WebSocketState.Open)
                {
                    using (var stream = new MemoryStream())
                    {
                        WebSocketReceiveResult result;
                        do
                        {
                            result = await socket.ReceiveAsync(
                                new ArraySegment<byte>(buffer),
                                cancellation.Token).ConfigureAwait(false);

                            if (result.MessageType == WebSocketMessageType.Close)
                            {
                                return;
                            }

                            stream.Write(buffer, 0, result.Count);
                        }
                        while (!result.EndOfMessage);

                        string message = Encoding.UTF8.GetString(stream.ToArray());
                        Match responseId = Regex.Match(
                            message,
                            "^\\s*\\{\\s*\"id\"\\s*:\\s*(\\d+)");

                        if (responseId.Success)
                        {
                            int id = Convert.ToInt32(responseId.Groups[1].Value);
                            TaskCompletionSource<string> completion;
                            if (pending.TryRemove(id, out completion))
                            {
                                completion.TrySetResult(message);
                            }
                        }
                        else
                        {
                            events.Enqueue(message);
                        }
                    }
                }
            }
            catch (OperationCanceledException)
            {
            }
            catch (Exception exception)
            {
                events.Enqueue(
                    "{\"method\":\"CustomDetections.ConnectionError\"," +
                    "\"params\":{\"message\":\"" +
                    EscapeJsonString(exception.Message) + "\"}}");
            }
        }

        private static string EscapeJsonString(string value)
        {
            if (String.IsNullOrEmpty(value))
            {
                return String.Empty;
            }

            var builder = new StringBuilder(value.Length);
            foreach (char character in value)
            {
                switch (character)
                {
                    case '\\': builder.Append("\\\\"); break;
                    case '"': builder.Append("\\\""); break;
                    case '\b': builder.Append("\\b"); break;
                    case '\f': builder.Append("\\f"); break;
                    case '\n': builder.Append("\\n"); break;
                    case '\r': builder.Append("\\r"); break;
                    case '\t': builder.Append("\\t"); break;
                    default:
                        if (character < 32)
                        {
                            builder.Append("\\u");
                            builder.Append(((int)character).ToString("x4"));
                        }
                        else
                        {
                            builder.Append(character);
                        }
                        break;
                }
            }

            return builder.ToString();
        }

        public void Dispose()
        {
            cancellation.Cancel();

            if (socket.State == WebSocketState.Open)
            {
                try
                {
                    socket.CloseAsync(
                        WebSocketCloseStatus.NormalClosure,
                        "Exporter completed",
                        CancellationToken.None).Wait(1000);
                }
                catch
                {
                    socket.Abort();
                }
            }

            socket.Dispose();
            cancellation.Dispose();
        }
    }
}
'@

Add-Type -TypeDefinition $cdpClientSource

function ConvertTo-SafeFileName {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [int]$MaximumLength = 100
    )

    $invalidCharacters = [IO.Path]::GetInvalidFileNameChars()
    $escapedCharacters = [Regex]::Escape((-join $invalidCharacters))
    $safeName = [Regex]::Replace($Name, "[$escapedCharacters]", '_')
    $safeName = [Regex]::Replace($safeName, '\s+', ' ').Trim().TrimEnd('.')

    if ([string]::IsNullOrWhiteSpace($safeName)) {
        $safeName = 'unnamed-rule'
    }
    if ($safeName.Length -gt $MaximumLength) {
        $safeName = $safeName.Substring(0, $MaximumLength).Trim()
    }

    return $safeName
}

function Get-CaseInsensitiveProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    foreach ($candidate in $Name) {
        $property = $InputObject.PSObject.Properties |
            Where-Object { $_.Name -ieq $candidate } |
            Select-Object -First 1
        if ($null -ne $property -and $null -ne $property.Value) {
            return $property.Value
        }
    }

    return $null
}

function Test-CustomDetectionRule {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    if ($null -eq $InputObject -or $InputObject -is [string] -or
        $InputObject -is [ValueType] -or $InputObject -is [System.Collections.IDictionary]) {
        return $false
    }

    $name = Get-CaseInsensitiveProperty -InputObject $InputObject -Name @(
        'displayName', 'ruleName', 'name', 'title'
    )
    $query = Get-CaseInsensitiveProperty -InputObject $InputObject -Name @(
        'query', 'queryText', 'detectionQuery', 'queryCondition', 'kql'
    )
    if ([string]::IsNullOrWhiteSpace([string]$query)) {
        $huntingQuery = Get-CaseInsensitiveProperty -InputObject $InputObject -Name @('huntingQuery')
        if ($null -ne $huntingQuery) {
            $query = Get-CaseInsensitiveProperty -InputObject $huntingQuery -Name @('queryText', 'query')
        }
    }
    $identifier = Get-CaseInsensitiveProperty -InputObject $InputObject -Name @(
        'id', 'ruleId', 'detectionRuleId', 'customDetectionId'
    )
    $schedule = Get-CaseInsensitiveProperty -InputObject $InputObject -Name @(
        'frequency', 'frequencyInMinutes', 'schedulingType', 'schedule', 'period', 'lookback'
    )
    $resourceType = Get-CaseInsensitiveProperty -InputObject $InputObject -Name @('usxResourceType')

    return (
        -not [string]::IsNullOrWhiteSpace([string]$name) -and
        -not [string]::IsNullOrWhiteSpace([string]$query) -and
        ($null -ne $identifier -or $null -ne $schedule) -and
        ([string]::IsNullOrWhiteSpace([string]$resourceType) -or
            [string]$resourceType -eq 'DefenderCustomDetectionRule')
    )
}

function Find-CustomDetectionRule {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    $results = New-Object System.Collections.Generic.List[object]
    $visited = New-Object 'System.Collections.Generic.HashSet[int]'

    function Visit-Value {
        param([object]$Value)

        if ($null -eq $Value -or $Value -is [string] -or $Value -is [ValueType]) {
            return
        }

        $identity = [Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($Value)
        if (-not $visited.Add($identity)) {
            return
        }
        if (Test-CustomDetectionRule -InputObject $Value) {
            $results.Add($Value)
        }

        if ($Value -is [System.Collections.IDictionary]) {
            foreach ($item in $Value.Values) {
                Visit-Value -Value $item
            }
            return
        }
        if ($Value -is [System.Collections.IEnumerable]) {
            foreach ($item in $Value) {
                Visit-Value -Value $item
            }
            return
        }

        foreach ($property in $Value.PSObject.Properties) {
            if ($property.MemberType -in @('NoteProperty', 'Property')) {
                Visit-Value -Value $property.Value
            }
        }
    }

    Visit-Value -Value $InputObject
    return $results.ToArray()
}

function Get-StableRuleKey {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Rule
    )

    $identifier = Get-CaseInsensitiveProperty -InputObject $Rule -Name @(
        'id', 'ruleId', 'detectionRuleId', 'customDetectionId'
    )
    if (-not [string]::IsNullOrWhiteSpace([string]$identifier)) {
        return "id:$identifier"
    }

    $json = $Rule | ConvertTo-Json -Depth 100 -Compress
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        return 'sha256:' + (($sha256.ComputeHash($bytes) | ForEach-Object {
            $_.ToString('x2')
        }) -join '')
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-RuleDisplayName {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Rule
    )

    $name = Get-CaseInsensitiveProperty -InputObject $Rule -Name @(
        'displayName', 'ruleName', 'name', 'title'
    )
    if ([string]::IsNullOrWhiteSpace([string]$name)) {
        return 'unnamed-rule'
    }

    return [string]$name
}

function Get-RuleQueryText {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Rule
    )

    $query = Get-CaseInsensitiveProperty -InputObject $Rule -Name @(
        'query', 'queryText', 'detectionQuery', 'queryCondition', 'kql'
    )
    if ([string]::IsNullOrWhiteSpace([string]$query)) {
        $huntingQuery = Get-CaseInsensitiveProperty -InputObject $Rule -Name @('huntingQuery')
        if ($null -ne $huntingQuery) {
            $query = Get-CaseInsensitiveProperty -InputObject $huntingQuery -Name @(
                'queryText', 'query'
            )
        }
    }

    return [string]$query
}

function Resolve-EdgeExecutable {
    $candidatePaths = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
    )

    $edgePath = $candidatePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($edgePath)) {
        throw 'Microsoft Edge was not found. Install Edge or update Resolve-EdgeExecutable with its path.'
    }

    return $edgePath
}

function Invoke-CdpCommand {
    param(
        [Parameter(Mandatory = $true)]
        [CustomDetections.CdpClient]$Client,

        [Parameter(Mandatory = $true)]
        [string]$Method,

        [hashtable]$Parameters = @{},

        [int]$TimeoutMilliseconds = 30000
    )

    $parametersJson = $Parameters | ConvertTo-Json -Depth 20 -Compress
    $response = $Client.Call($Method, $parametersJson, $TimeoutMilliseconds) | ConvertFrom-Json
    $errorProperty = $response.PSObject.Properties['error']
    if ($null -ne $errorProperty) {
        throw "DevTools command '$Method' failed: $($errorProperty.Value.message)"
    }

    return $response.PSObject.Properties['result'].Value
}

function Get-AvailableTcpPort {
    $listener = New-Object Net.Sockets.TcpListener ([Net.IPAddress]::Loopback), 0
    try {
        $listener.Start()
        return ([Net.IPEndPoint]$listener.LocalEndpoint).Port
    }
    finally {
        $listener.Stop()
    }
}

function Get-EdgeProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserDataPath
    )

    $profiles = New-Object System.Collections.Generic.List[object]
    $localStatePath = Join-Path $UserDataPath 'Local State'

    if (Test-Path -LiteralPath $localStatePath) {
        try {
            $localState = Get-Content -LiteralPath $localStatePath -Raw | ConvertFrom-Json
            $infoCache = $localState.profile.info_cache
            if ($null -ne $infoCache) {
                foreach ($property in $infoCache.PSObject.Properties) {
                    $directory = [string]$property.Name
                    if ($directory -eq 'Default' -or $directory -match '^Profile \d+$') {
                        $displayName = [string]$property.Value.name
                        if ([string]::IsNullOrWhiteSpace($displayName)) {
                            $displayName = $directory
                        }

                        $profiles.Add([pscustomobject]@{
                            Directory = $directory
                            Name = $displayName
                        })
                    }
                }
            }
        }
        catch {
            Write-Verbose "Could not read Edge profile names from Local State: $($_.Exception.Message)"
        }
    }

    foreach ($directory in @(Get-ChildItem -LiteralPath $UserDataPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Default' -or $_.Name -match '^Profile \d+$' })) {
        if (-not ($profiles | Where-Object { $_.Directory -eq $directory.Name })) {
            $profiles.Add([pscustomobject]@{
                Directory = $directory.Name
                Name = $directory.Name
            })
        }
    }

    return @($profiles | Sort-Object @{
        Expression = {
            if ($_.Directory -eq 'Default') {
                0
            }
            else {
                [int]($_.Directory -replace '^Profile ', '') + 1
            }
        }
    })
}

function Select-EdgeProfileDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserDataPath
    )

    $profiles = @(Get-EdgeProfile -UserDataPath $UserDataPath)
    if ($profiles.Count -eq 0) {
        throw "No Edge profiles were found beneath '$UserDataPath'."
    }

    Write-Host 'Available Microsoft Edge profiles:' -ForegroundColor Cyan
    for ($index = 0; $index -lt $profiles.Count; $index++) {
        Write-Host ('  [{0}] {1} ({2})' -f
            ($index + 1),
            $profiles[$index].Name,
            $profiles[$index].Directory)
    }

    while ($true) {
        $selection = Read-Host "Select an Edge profile [1-$($profiles.Count)]"
        $selectionNumber = 0
        if ([int]::TryParse($selection, [ref]$selectionNumber) -and
            $selectionNumber -ge 1 -and
            $selectionNumber -le $profiles.Count) {
            return [string]$profiles[$selectionNumber - 1].Directory
        }

        Write-Warning "Enter a number from 1 through $($profiles.Count)."
    }
}

function Copy-EdgeProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $true)]
        [string]$ProfileDirectory
    )

    $sourceProfilePath = Join-Path $SourceRoot $ProfileDirectory
    if (-not (Test-Path -LiteralPath $sourceProfilePath)) {
        throw "The Edge profile directory '$sourceProfilePath' does not exist."
    }

    $runningEdge = @(Get-Process -Name msedge -ErrorAction SilentlyContinue)
    if ($runningEdge.Count -gt 0) {
        $processIds = ($runningEdge | Select-Object -ExpandProperty Id) -join ', '
        throw "Close all Microsoft Edge windows before importing a profile. Running Edge process IDs: $processIds"
    }

    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $SourceRoot 'Local State') -Destination $DestinationRoot -Force

    $destinationProfilePath = Join-Path $DestinationRoot $ProfileDirectory
    New-Item -ItemType Directory -Path $destinationProfilePath -Force | Out-Null

    $excludedDirectories = @(
        'Cache',
        'Code Cache',
        'GPUCache',
        'GrShaderCache',
        'DawnCache',
        'ShaderCache',
        'Service Worker\CacheStorage'
    )
    $arguments = @(
        $sourceProfilePath,
        $destinationProfilePath,
        '/E',
        '/R:1',
        '/W:1',
        '/NFL',
        '/NDL',
        '/NJH',
        '/NJS',
        '/NP',
        '/XF',
        'LOCK'
    )
    if ($excludedDirectories.Count -gt 0) {
        $arguments += '/XD'
        $arguments += $excludedDirectories | ForEach-Object { Join-Path $sourceProfilePath $_ }
    }

    & robocopy.exe @arguments | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "Failed to import Edge profile '$ProfileDirectory'. Robocopy exit code: $LASTEXITCODE"
    }
}

function Get-CdpEvents {
    param(
        [Parameter(Mandatory = $true)]
        [CustomDetections.CdpClient]$Client
    )

    $message = $null
    while ($Client.TryTakeEvent([ref]$message)) {
        $event = $message | ConvertFrom-Json
        if ($event.method -eq 'CustomDetections.ConnectionError') {
            throw "The Edge DevTools connection failed: $($event.params.message)"
        }

        Write-Output $event
        $message = $null
    }
}

function Add-NetworkEvents {
    param(
        [Parameter(Mandatory = $true)]
        [CustomDetections.CdpClient]$Client,

        [Parameter(Mandatory = $true)]
        [hashtable]$Requests,

        [Parameter(Mandatory = $true)]
        [hashtable]$Responses
    )

    foreach ($event in @(Get-CdpEvents -Client $Client)) {
        if ($event.method -eq 'Network.requestWillBeSent') {
            $Requests[[string]$event.params.requestId] = $event.params.request
            continue
        }

        if ($event.method -eq 'Network.requestWillBeSentExtraInfo') {
            $Requests["headers:$([string]$event.params.requestId)"] = $event.params.headers
            continue
        }

        if ($event.method -eq 'Network.responseReceived') {
            $response = $event.params.response
            $contentType = Get-CaseInsensitiveProperty -InputObject $response.headers -Name @('content-type')
            $isJson = ([string]$response.mimeType -match 'json') -or
                ([string]$contentType -match 'json')
            $isCandidateUrl = [string]$response.url -match '(?i)(custom.?detection|huntingService/rules)'
            $isFetch = [string]$event.params.type -in @('Fetch', 'XHR')

            if ($isJson -and $isFetch -and $isCandidateUrl) {
                $Responses[[string]$event.params.requestId] = $response
            }
        }
    }
}

function Get-PageState {
    param(
        [Parameter(Mandatory = $true)]
        [CustomDetections.CdpClient]$Client
    )

    $expression = @'
JSON.stringify({
  url: location.href,
  title: document.title,
  readyState: document.readyState,
  bodyText: document.body ? document.body.innerText.substring(0, 2000) : ""
})
'@
    $result = Invoke-CdpCommand -Client $Client -Method 'Runtime.evaluate' -Parameters @{
        expression = $expression
        returnByValue = $true
    }

    return $result.result.value | ConvertFrom-Json
}

function Get-PortalCustomDetections {
    param(
        [Parameter(Mandatory = $true)]
        [CustomDetections.CdpClient]$Client,

        [Parameter(Mandatory = $true)]
        [string]$ListUrl,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,

        [string[]]$DetectionNames = @()
    )

    $listUrlBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($ListUrl))
    $headersJson = $Headers | ConvertTo-Json -Compress
    $headersBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($headersJson))
    $detectionNameValues = @($DetectionNames | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_)
    })
    $detectionNamesJson = if ($detectionNameValues.Count -eq 0) {
        '[]'
    }
    else {
        ConvertTo-Json -InputObject $detectionNameValues -Compress
    }
    $detectionNamesBase64 = [Convert]::ToBase64String(
        [Text.Encoding]::UTF8.GetBytes($detectionNamesJson)
    )
    $expression = @'
(async () => {
  const tenantId = new URL(location.href).searchParams.get("tid");
  if (!tenantId) throw new Error("The portal URL does not contain a tenant ID.");

  const listUrl = new TextDecoder().decode(
    Uint8Array.from(atob("__LIST_URL_BASE64__"), character => character.charCodeAt(0))
  );
  const headers = JSON.parse(new TextDecoder().decode(
    Uint8Array.from(atob("__HEADERS_BASE64__"), character => character.charCodeAt(0))
  ));
  const requestOptions = { credentials: "include", headers };
  const listResponse = await fetch(listUrl, requestOptions);
  if (!listResponse.ok) {
    throw new Error(`Rule list request failed: HTTP ${listResponse.status}`);
  }

  const list = await listResponse.json();
  if (!Array.isArray(list)) {
    throw new Error("The rule list response was not an array.");
  }

  const rawRequestedNames = JSON.parse(new TextDecoder().decode(
    Uint8Array.from(atob("__DETECTION_NAMES_BASE64__"), character => character.charCodeAt(0))
  ));
  let requestedNames = rawRequestedNames.flatMap(value => {
    const text = String(value || "").trim();
    return text.includes(",") ? text.split(",").map(name => name.trim()).filter(Boolean) : [text];
  }).filter(Boolean);

  requestedNames = Array.from(new Map(
    requestedNames.map(name => [name.toLocaleLowerCase(), name])
  ).values());
  const requestedKeys = new Set(requestedNames.map(name => name.toLocaleLowerCase()));
  const selected = requestedNames.length === 0
    ? list
    : list.filter(rule => requestedKeys.has(
        String(rule.Name ?? rule.name ?? "").toLocaleLowerCase()
      ));
  const matchedKeys = new Set(selected.map(rule =>
    String(rule.Name ?? rule.name ?? "").toLocaleLowerCase()
  ));
  const notFound = requestedNames.filter(name => !matchedKeys.has(name.toLocaleLowerCase()));

  const rules = new Array(selected.length);
  const errors = [];
  let nextIndex = 0;

  async function worker() {
    while (true) {
      const index = nextIndex++;
      if (index >= selected.length) return;

      const summary = selected[index];
      const id = summary.Id ?? summary.id;
      if (id === undefined || id === null) {
        errors.push({ index, name: summary.Name ?? summary.name, error: "Rule ID is missing." });
        continue;
      }

      const detailsUrl = "/apiproxy/hunting/huntingService/rules/" +
        encodeURIComponent(id) +
        "?includeLastRun=true&includeQuery=true&tenantIds=" +
        encodeURIComponent(tenantId) +
        "&isUnifiedRulesListEnabled=true";

      try {
        const response = await fetch(detailsUrl, requestOptions);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        rules[index] = await response.json();
      } catch (error) {
        errors.push({ id, name: summary.Name ?? summary.name, error: String(error.message || error) });
      }
    }
  }

  await Promise.all(Array.from({ length: Math.min(4, Math.max(1, selected.length)) }, worker));
  return JSON.stringify({
    requestedNames,
    notFound,
    summaries: selected,
    rules: rules.filter(Boolean),
    errors
  });
})()
'@
    $expression = $expression.Replace('__LIST_URL_BASE64__', $listUrlBase64).
        Replace('__HEADERS_BASE64__', $headersBase64).
        Replace('__DETECTION_NAMES_BASE64__', $detectionNamesBase64)

    $result = Invoke-CdpCommand -Client $Client -Method 'Runtime.evaluate' -Parameters @{
        expression = $expression
        awaitPromise = $true
        returnByValue = $true
    } -TimeoutMilliseconds 600000

    $exceptionProperty = $result.PSObject.Properties['exceptionDetails']
    if ($null -ne $exceptionProperty) {
        throw "Portal API export failed: $($exceptionProperty.Value.text)"
    }

    $value = $result.result.value
    if ([string]::IsNullOrWhiteSpace([string]$value)) {
        throw 'Portal API export returned no data.'
    }

    return $value | ConvertFrom-Json
}

function Get-ResponseBody {
    param(
        [Parameter(Mandatory = $true)]
        [CustomDetections.CdpClient]$Client,

        [Parameter(Mandatory = $true)]
        [string]$RequestId
    )

    try {
        $result = Invoke-CdpCommand -Client $Client -Method 'Network.getResponseBody' -Parameters @{
            requestId = $RequestId
        } -TimeoutMilliseconds 10000

        if ($result.base64Encoded) {
            return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($result.body))
        }

        return [string]$result.body
    }
    catch {
        Write-Verbose "Could not read response body for request $RequestId`: $($_.Exception.Message)"
        return $null
    }
}

$edgeProcess = $null
$client = $null
$requests = @{}
$responses = @{}

try {
    $browserUserDataPath = $ProfilePath
    if ($ResetProfile -and (Test-Path -LiteralPath $browserUserDataPath)) {
        Remove-Item -LiteralPath $browserUserDataPath -Recurse -Force
    }

    if ($SelectEdgeProfile) {
        $sourceUserDataPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
        if ([string]::IsNullOrWhiteSpace($EdgeProfileDirectory)) {
            $EdgeProfileDirectory = Select-EdgeProfileDirectory -UserDataPath $sourceUserDataPath
        }
        $importedProfilePath = Join-Path $browserUserDataPath $EdgeProfileDirectory
        if (-not (Test-Path -LiteralPath $importedProfilePath)) {
            Write-Host "Importing Edge profile '$EdgeProfileDirectory' into the isolated exporter profile..." -ForegroundColor Cyan
            Copy-EdgeProfile -SourceRoot $sourceUserDataPath `
                -DestinationRoot $browserUserDataPath `
                -ProfileDirectory $EdgeProfileDirectory
        }
    }
    else {
        New-Item -ItemType Directory -Path $browserUserDataPath -Force | Out-Null
    }

    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    $capturePath = Join-Path $OutputPath 'captures'
    $rulePath = Join-Path $OutputPath 'rules'
    New-Item -ItemType Directory -Path $capturePath -Force | Out-Null
    New-Item -ItemType Directory -Path $rulePath -Force | Out-Null

    $edgePath = Resolve-EdgeExecutable
    $port = Get-AvailableTcpPort
    $edgeArguments = @(
        "--remote-debugging-port=$port",
        "--user-data-dir=`"$browserUserDataPath`"",
        '--no-first-run',
        '--disable-features=msEdgeFirstRunExperience',
        'about:blank'
    )
    if ($SelectEdgeProfile) {
        $edgeArguments = @("--profile-directory=`"$EdgeProfileDirectory`"") + $edgeArguments
    }
    $edgeProcess = Start-Process -FilePath $edgePath -ArgumentList $edgeArguments -PassThru

    $devToolsDeadline = (Get-Date).AddSeconds(30)
    $targets = $null
    while ($null -eq $targets) {
        if ((Get-Date) -gt $devToolsDeadline) {
            throw "Timed out waiting for the Edge DevTools endpoint on port $port."
        }
        try {
            $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/list"
        }
        catch {
            Start-Sleep -Milliseconds 200
        }
    }

    $target = $targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
    if ($null -eq $target) {
        throw 'Edge did not expose a page target through DevTools.'
    }

    $client = New-Object CustomDetections.CdpClient
    $client.Connect([string]$target.webSocketDebuggerUrl, 30000)
    Invoke-CdpCommand -Client $client -Method 'Page.enable' | Out-Null
    Invoke-CdpCommand -Client $client -Method 'Runtime.enable' | Out-Null
    Invoke-CdpCommand -Client $client -Method 'Network.enable' -Parameters @{
        maxTotalBufferSize = 100000000
        maxResourceBufferSize = 10000000
        maxPostDataSize = 1000000
    } | Out-Null

    Invoke-CdpCommand -Client $client -Method 'Page.navigate' -Parameters @{
        url = $portalUrl
    } | Out-Null

    Write-Host 'Microsoft Edge is open. Complete sign-in if prompted.' -ForegroundColor Cyan
    Write-Host 'The exporter will continue when the custom detections page has loaded.' -ForegroundColor Cyan

    $loginDeadline = (Get-Date).AddSeconds($LoginTimeoutSeconds)
    $pageReady = $false
    while ((Get-Date) -lt $loginDeadline) {
        Add-NetworkEvents -Client $client -Requests $requests -Responses $responses
        $pageState = Get-PageState -Client $client

        if ($pageState.url -match '^https://security\.apps\.mil/v2/custom_detection' -and
            $pageState.readyState -eq 'complete') {
            $pageReady = $true
            break
        }

        Start-Sleep -Seconds 1
    }

    if (-not $pageReady) {
        throw "Timed out after $LoginTimeoutSeconds seconds waiting for the custom detections page."
    }

    Write-Host "Waiting up to $CaptureSeconds seconds for the portal rule-list request..." -ForegroundColor Cyan
    $captureDeadline = (Get-Date).AddSeconds($CaptureSeconds)
    while ((Get-Date) -lt $captureDeadline) {
        Add-NetworkEvents -Client $client -Requests $requests -Responses $responses
        $listRequestSeen = $requests.GetEnumerator() | Where-Object {
            -not ([string]$_.Key).StartsWith('headers:') -and
            [string]$_.Value.url -match '/huntingService/rules/unified'
        } | Select-Object -First 1
        if ($null -ne $listRequestSeen) {
            break
        }
        Start-Sleep -Milliseconds 500
    }

    Add-NetworkEvents -Client $client -Requests $requests -Responses $responses
    Write-Host 'Downloading full details for the selected custom detection rules...' -ForegroundColor Cyan
    $listRequestEntry = $requests.GetEnumerator() |
        Where-Object {
            -not ([string]$_.Key).StartsWith('headers:') -and
            [string]$_.Value.url -match '/huntingService/rules/unified'
        } |
        Select-Object -First 1
    if ($null -eq $listRequestEntry) {
        throw 'The portal did not issue the expected unified rule-list request.'
    }

    $requestId = [string]$listRequestEntry.Key
    $requestHeaders = $requests["headers:$requestId"]
    if ($null -eq $requestHeaders) {
        $requestHeaders = $listRequestEntry.Value.headers
    }

    $replayHeaders = @{}
    foreach ($property in $requestHeaders.PSObject.Properties) {
        if ($property.Name -match '^[A-Za-z0-9-]+$' -and
            $property.Name -notmatch '(?i)^(host|content-length|cookie|origin|referer|user-agent|accept-encoding|connection|sec-.*)$') {
            $replayHeaders[$property.Name] = [string]$property.Value
        }
    }

    $portalExport = Get-PortalCustomDetections `
        -Client $client `
        -ListUrl ([string]$listRequestEntry.Value.url) `
        -Headers $replayHeaders `
        -DetectionNames $DetectionNames

    $rulesByKey = @{}
    $captureIndex = New-Object System.Collections.Generic.List[object]
    $captureNumber = 0

    $summaryCaptureFile = Join-Path $capturePath 'rules-unified.json'
    @($portalExport.summaries) | ConvertTo-Json -Depth 100 |
        Set-Content -LiteralPath $summaryCaptureFile -Encoding UTF8
    $captureIndex.Add([pscustomobject]@{
        file = 'captures\rules-unified.json'
        method = 'GET'
        url = '/apiproxy/hunting/huntingService/rules/unified'
        status = 200
        ruleCandidates = @($portalExport.summaries).Count
    })

    $detailsCaptureFile = Join-Path $capturePath 'rule-details.json'
    @($portalExport.rules) | ConvertTo-Json -Depth 100 |
        Set-Content -LiteralPath $detailsCaptureFile -Encoding UTF8
    $captureIndex.Add([pscustomobject]@{
        file = 'captures\rule-details.json'
        method = 'GET'
        url = '/apiproxy/hunting/huntingService/rules/{id}?includeQuery=true'
        status = 200
        ruleCandidates = @($portalExport.rules).Count
    })

    foreach ($rule in @($portalExport.rules)) {
        if (Test-CustomDetectionRule -InputObject $rule) {
            $rulesByKey[(Get-StableRuleKey -Rule $rule)] = $rule
        }
    }

    foreach ($requestId in @($responses.Keys)) {
        $body = Get-ResponseBody -Client $client -RequestId $requestId
        if ([string]::IsNullOrWhiteSpace($body)) {
            continue
        }

        $parsedBody = $null
        try {
            $parsedBody = $body | ConvertFrom-Json
        }
        catch {
            continue
        }

        $captureNumber++
        $captureFile = 'response-{0:D4}.json' -f $captureNumber
        $captureFilePath = Join-Path $capturePath $captureFile
        $parsedBody | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $captureFilePath -Encoding UTF8

        $request = $requests[$requestId]
        $response = $responses[$requestId]
        $foundRules = @(Find-CustomDetectionRule -InputObject $parsedBody)
        foreach ($rule in $foundRules) {
            $rulesByKey[(Get-StableRuleKey -Rule $rule)] = $rule
        }

        $captureIndex.Add([pscustomobject]@{
            file = "captures\$captureFile"
            method = if ($null -ne $request) { [string]$request.method } else { $null }
            url = [string]$response.url
            status = [int]$response.status
            ruleCandidates = $foundRules.Count
        })
    }

    $ruleIndex = New-Object System.Collections.Generic.List[object]
    $usedFileNames = @{}
    foreach ($entry in $rulesByKey.GetEnumerator() | Sort-Object Key) {
        $rule = $entry.Value
        $displayName = Get-RuleDisplayName -Rule $rule
        $baseName = ConvertTo-SafeFileName -Name $displayName
        $fileStem = $baseName
        $fileName = "$fileStem.json"
        $suffix = 2

        while ($usedFileNames.ContainsKey($fileName.ToLowerInvariant())) {
            $fileStem = "$baseName-$suffix"
            $fileName = "$fileStem.json"
            $suffix++
        }
        $usedFileNames[$fileName.ToLowerInvariant()] = $true

        $rule | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $rulePath $fileName) -Encoding UTF8
        $queryFileName = "$fileStem.kql"
        $queryText = Get-RuleQueryText -Rule $rule
        [IO.File]::WriteAllText(
            (Join-Path $rulePath $queryFileName),
            $queryText,
            (New-Object Text.UTF8Encoding($false))
        )
        $ruleIndex.Add([pscustomobject]@{
            name = $displayName
            key = $entry.Key
            file = "rules\$fileName"
            queryFile = "rules\$queryFileName"
        })
    }

    $manifest = [pscustomobject]@{
        exportedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        tenantId = $TenantId.ToString('D')
        portalUrl = $portalUrl
        ruleCount = $ruleIndex.Count
        captureCount = $captureIndex.Count
        complete = (
            @($portalExport.errors).Count -eq 0 -and
            @($portalExport.notFound).Count -eq 0
        )
        requestedDetectionNames = @($portalExport.requestedNames)
        unmatchedDetectionNames = @($portalExport.notFound)
        errors = @($portalExport.errors)
        rules = $ruleIndex.ToArray()
        captures = $captureIndex.ToArray()
    }
    $manifest | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $OutputPath 'manifest.json') -Encoding UTF8

    if (@($portalExport.notFound).Count -gt 0) {
        throw "The following requested detection name(s) were not found: $(@($portalExport.notFound) -join ', ')"
    }
    if ($ruleIndex.Count -eq 0) {
        throw "No custom detection rules were recognized. Raw JSON captures were saved to '$capturePath' for schema analysis."
    }
    if (@($portalExport.errors).Count -gt 0) {
        throw "Exported $($ruleIndex.Count) rule(s), but $(@($portalExport.errors).Count) rule detail request(s) failed. See manifest.json."
    }

    Write-Host "Exported $($ruleIndex.Count) custom detection rule(s) to '$OutputPath'." -ForegroundColor Green
}
finally {
    if ($null -ne $client) {
        try {
            Invoke-CdpCommand -Client $client -Method 'Browser.close' -TimeoutMilliseconds 5000 | Out-Null
        }
        catch {
            Write-Verbose "Edge did not accept Browser.close: $($_.Exception.Message)"
        }
    }

    if ($null -ne $client) {
        $client.Dispose()
    }

    if ($null -eq $client -and
        $null -ne $edgeProcess -and -not $edgeProcess.HasExited) {
        Stop-Process -Id $edgeProcess.Id
    }

    if ($RemoveCachedProfile -and (Test-Path -LiteralPath $ProfilePath)) {
        $profileRemovalDeadline = (Get-Date).AddSeconds(15)
        do {
            try {
                Remove-Item -LiteralPath $ProfilePath -Recurse -Force
                break
            }
            catch {
                if ((Get-Date) -ge $profileRemovalDeadline) {
                    throw "Could not remove the cached Edge profile '$ProfilePath': $($_.Exception.Message)"
                }
                Start-Sleep -Milliseconds 500
            }
        }
        while (Test-Path -LiteralPath $ProfilePath)

        Write-Host "Removed cached Edge profile '$ProfilePath'." -ForegroundColor Green
    }
}
