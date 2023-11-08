# This script tests the runHuntingQuery method for the Graph security API

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$token = Get-Content "$scriptDir\Latest-token.txt"
$url = "https://dod-graph.microsoft.us/v1.0/security/runHuntingQuery?whatin"

# Set the webrequest headers
$headers = @{
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
    'Authorization' = "Bearer $token"
}

$body = @{
    'Query' = 'DeviceProcessEvents | take 3'
} | ConvertTo-Json

# Send the request and get the results.
try
{
    $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body $body -ErrorAction Stop -Verbose
    $response.Content
}
catch
{
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $responseBody = $reader.ReadToEnd()
    Write-host -ForegroundColor Yellow $_.Exception.Message
    Write-Host -ForegroundColor Red "API call failed with the following error: $responseBody"
