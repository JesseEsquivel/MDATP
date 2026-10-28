$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$path = Join-Path $PSScriptRoot 'Get-CustomDetections.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) {
    throw ($parseErrors | Out-String)
}
$assignment = $ast.Find({
    param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left.Extent.Text -eq '$cdpClientSource'
}, $true)
Add-Type -TypeDefinition $assignment.Right.Expression.Value
foreach ($statement in $ast.EndBlock.Statements) {
    if ($statement -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
        . ([scriptblock]::Create($statement.Extent.Text))
    }
}

$script:assertions = 0
function Assert {
    param([bool]$Condition, [string]$Message)
    $script:assertions++
    if (-not $Condition) { throw $Message }
}
function Assert-Throws {
    param([scriptblock]$Action, [string]$MessagePattern)
    $caught = $null
    try { & $Action | Out-Null }
    catch { $caught = $_ }
    Assert ($null -ne $caught) 'Expected an error.'
    Assert ($caught.Exception.Message -match $MessagePattern) 'Unexpected error.'
}

$upn = 'user@example.invalid'
$url = 'https://login.microsoftonline.us/00000000-0000-0000-0000-000000000000/oauth2/v2.0/authorize?client_id=synthetic-client&redirect_uri=https%3A%2F%2Fsecurity.apps.mil%2Fcallback&state=a%2Bb%26c%3D&nonce=synthetic-nonce&code_challenge=a-b_c&scope=openid%20profile&LOGIN_HINT=wrong%40example.invalid&domain_hint=old&sid=old-session&prompt=none'
$rewritten = Get-TargetUserAuthorizationUrl -Url $url -UserPrincipalName $upn
Assert ($rewritten -match 'prompt=login') 'Interactive login was not requested.'
Assert ($rewritten -match 'login_hint=user%40example.invalid') 'The intended account was not requested.'
Assert ($rewritten -notmatch 'wrong|domain_hint=|sid=|prompt=none') 'Previous account hints remain.'
foreach ($pair in @(
    'client_id=synthetic-client',
    'redirect_uri=https%3A%2F%2Fsecurity.apps.mil%2Fcallback',
    'state=a%2Bb%26c%3D',
    'nonce=synthetic-nonce',
    'code_challenge=a-b_c',
    'scope=openid%20profile'
)) {
    Assert ($rewritten.Contains($pair)) "An original authorization parameter changed: $pair"
}
foreach ($candidate in @(
    'http://login.microsoftonline.us/common/oauth2/authorize',
    'https://login.microsoftonline.us.evil.invalid/common/oauth2/authorize',
    'https://evil.invalid/common/oauth2/authorize',
    'https://login.microsoftonline.us:8443/common/oauth2/authorize',
    'https://login.microsoftonline.us/common/oauth2/token',
    'https://security.apps.mil/v2/custom_detection',
    'not a URL'
)) {
    Assert ($null -eq (Get-TargetUserAuthorizationUrl -Url $candidate -UserPrincipalName $upn)) 'An unrelated URL was rewritten.'
}
$v1 = Get-TargetUserAuthorizationUrl -Url 'https://login.microsoftonline.com/common/oauth2/authorize?state=synthetic' -UserPrincipalName $upn
Assert ($v1 -match 'prompt=login') 'The version one authorization path was not handled.'

$script:calls = New-Object System.Collections.Generic.List[object]
function Invoke-CdpCommand {
    param($Client, $Method, $Parameters = @{}, $TimeoutMilliseconds)
    $script:calls.Add([pscustomobject]@{ Method = $Method; Parameters = $Parameters })
}
$client = New-Object CustomDetections.CdpClient
$state = @{ FrameId = 'main'; UserPrincipalName = $upn; AuthorizationRequests = 0; InterceptionEnabled = $true }
$event = [pscustomobject]@{
    method = 'Fetch.requestPaused'
    params = [pscustomobject]@{
        requestId = 'request-1'
        frameId = 'main'
        resourceType = 'Document'
        request = [pscustomobject]@{ url = $url; method = 'GET' }
    }
}
Complete-TargetUserRequest -Client $client -Event $event -AuthenticationState $state
Assert ($state.AuthorizationRequests -eq 1) 'The targeted request was not counted.'
Assert ($script:calls.Count -eq 1) 'The paused request was not continued once.'
Assert ($script:calls[0].Parameters.url -eq $rewritten) 'The rewritten URL was not passed to CDP.'
Assert ($script:calls[0].Method -eq 'Fetch.continueRequest') 'Incorrect CDP action.'
$script:calls.Clear()
$event.params.frameId = 'iframe'
Complete-TargetUserRequest -Client $client -Event $event -AuthenticationState $state
Assert (-not $script:calls[0].Parameters.ContainsKey('url')) 'An iframe login request was changed.'
Assert ($state.AuthorizationRequests -eq 1) 'An iframe was counted as an interactive sign in.'
$script:calls.Clear()
$event.params.frameId = 'main'
$event.params.request.method = 'POST'
Assert-Throws { Complete-TargetUserRequest -Client $client -Event $event -AuthenticationState $state } 'unsupported authorization request method'
Assert ($script:calls.Count -eq 0) 'An unsupported request was continued.'
$event.params.request.method = 'GET'

$script:events = @(
    $event,
    [pscustomobject]@{
        method = 'Network.requestWillBeSent'
        params = [pscustomobject]@{
            requestId = 'rules'
            request = [pscustomobject]@{ url = 'https://security.apps.mil/apiproxy/hunting/huntingService/rules/unified' }
        }
    }
)
function Get-CdpEvents { param($Client) return $script:events }
$requests = @{}
$responses = @{}
Add-NetworkEvents -Client $client -Requests $requests -Responses $responses -AuthenticationState $state
Assert ($requests.ContainsKey('rules')) 'Network capture stopped working with account targeting.'
Assert ($state.AuthorizationRequests -eq 2) 'The network event loop did not resume authentication.'
Assert-Throws { Add-NetworkEvents -Client $client -Requests $requests -Responses $responses } 'no account selection context'
$script:calls.Clear()
$state.InterceptionEnabled = $false
Add-NetworkEvents -Client $client -Requests $requests -Responses $responses -AuthenticationState $state
Assert ($script:calls.Count -eq 0) 'A resumed authentication request was continued again after Fetch.disable.'
Assert ($state.AuthorizationRequests -eq 2) 'A queued event was counted after interception stopped.'

$script:answer = 'wrong@example.invalid'
function Read-Host { param($Prompt) return $script:answer }
Assert-Throws { Confirm-TargetUser -UserPrincipalName $upn } 'did not match'
$script:answer = 'CANCEL'
Assert-Throws { Confirm-TargetUser -UserPrincipalName $upn } 'did not match'
$script:answer = '  USER@example.invalid  '
Confirm-TargetUser -UserPrincipalName $upn

$script:events = @(
    [pscustomobject]@{
        method = 'Network.requestWillBeSent'
        params = [pscustomobject]@{
            requestId = 'legacy'
            request = [pscustomobject]@{ url = 'https://security.apps.mil/example' }
        }
    }
)
Add-NetworkEvents -Client $client -Requests $requests -Responses $responses
Assert ($requests.ContainsKey('legacy')) 'Legacy capture without account targeting regressed.'

Assert-Throws { & $path -TenantId '00000000-0000-0000-0000-000000000000' -UserPrincipalName $upn -SelectEdgeProfile } 'omit SelectEdgeProfile'
Assert-Throws { & $path -TenantId '00000000-0000-0000-0000-000000000000' -UserPrincipalName $upn -ResetProfile } 'omit SelectEdgeProfile'
Assert-Throws { & $path -TenantId '00000000-0000-0000-0000-000000000000' -UserPrincipalName $upn -ProfilePath $PSScriptRoot } 'must be a new directory'
Assert-Throws { & $path -TenantId '00000000-0000-0000-0000-000000000000' -UserPrincipalName 'not-an-account' } 'pattern'

$script:includeOwnEdge = $true
function Get-Process {
    param([int]$Id, [string]$Name)
    if ($PSBoundParameters.ContainsKey('Id')) {
        return [pscustomobject]@{ Id = $Id; SessionId = 10 }
    }
    [pscustomobject]@{ Id = 101; SessionId = 20 }
    if ($script:includeOwnEdge) {
        [pscustomobject]@{ Id = 102; SessionId = 10 }
    }
}
Assert-Throws {
    Copy-EdgeProfile -SourceRoot $PSScriptRoot -DestinationRoot 'unused' -ProfileDirectory '.'
} 'process IDs in this session: 102$'
$script:includeOwnEdge = $false
$script:profileCopied = $false
function New-Item { param($ItemType, $Path, [switch]$Force) }
function Copy-Item { param($LiteralPath, $Destination, [switch]$Force) }
function robocopy.exe {
    $script:profileCopied = $true
    $global:LASTEXITCODE = 0
}
Copy-EdgeProfile -SourceRoot $PSScriptRoot -DestinationRoot 'unused' -ProfileDirectory '.'
Assert $script:profileCopied 'Another Windows session incorrectly blocked the profile import.'

$client.Dispose()
"Passed $script:assertions assertions. No browser or cloud session was opened."
