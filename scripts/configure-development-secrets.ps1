[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dotnetExecutable = Join-Path $repositoryRoot ".dotnet\dotnet.exe"
$apiProject = Join-Path $repositoryRoot "backend\src\EmergencySystem.Api\EmergencySystem.Api.csproj"

if (-not (Test-Path -LiteralPath $dotnetExecutable)) {
    $dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($null -eq $dotnetCommand) {
        throw "A .NET 10 SDK is required. Follow docs/ENVIRONMENT_SETUP.md."
    }

    $dotnetExecutable = $dotnetCommand.Source
}

$existingSecrets = & $dotnetExecutable user-secrets list --project $apiProject 2>$null
$hasSigningKey = (($existingSecrets -join "`n") -match "(?m)^Jwt:SigningKey\s*=")

if ($hasSigningKey -and -not $Force) {
    Write-Output "Development secrets already exist. Nothing was changed."
    Write-Output "Use -Force only when you intentionally want to rotate the local demo credentials."
    return
}

function New-RandomBytes {
    param([int]$Length)

    $bytes = New-Object byte[] $Length
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $random.GetBytes($bytes)
        return $bytes
    }
    finally {
        $random.Dispose()
    }
}

function New-DemoPassword {
    param([string]$Prefix)

    $suffix = [Convert]::ToBase64String((New-RandomBytes -Length 18))
    $suffix = $suffix.Replace("+", "a").Replace("/", "b").Replace("=", "")
    return "$Prefix!7aA-$suffix"
}

$jwtSigningKey = [Convert]::ToBase64String((New-RandomBytes -Length 64))
$patientPassword = New-DemoPassword -Prefix "Pt"
$doctorPassword = New-DemoPassword -Prefix "Dr"
$administratorPassword = New-DemoPassword -Prefix "Ad"

$secretValues = [ordered]@{
    "Jwt:SigningKey" = $jwtSigningKey
    "DemoSeed:Enabled" = "true"
    "DemoSeed:Patient:Password" = $patientPassword
    "DemoSeed:Doctor:Password" = $doctorPassword
    "DemoSeed:Administrator:Password" = $administratorPassword
}

foreach ($entry in $secretValues.GetEnumerator()) {
    & $dotnetExecutable user-secrets set $entry.Key $entry.Value --project $apiProject | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not store development secret '$($entry.Key)'."
    }
}

Write-Output "Local secrets were stored outside Git."
Write-Output ""
Write-Output "Synthetic demo credentials (save these locally; they are shown once):"
Write-Output "patient.demo@emergency.test        $patientPassword"
Write-Output "doctor.demo@emergency.test         $doctorPassword"
Write-Output "admin.demo@emergency.test          $administratorPassword"
Write-Output ""
Write-Output "Start the API once to create the demo users. Never use these credentials with real data."
