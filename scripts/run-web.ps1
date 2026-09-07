[CmdletBinding()]
param(
    [string]$ApiBaseUrl = "http://localhost:5080",
    [ValidateRange(1024, 65535)]
    [int]$WebPort = 5000
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot

Push-Location $repositoryRoot
try {
    flutter run `
        -d chrome `
        --web-port $WebPort `
        --dart-define "API_BASE_URL=$ApiBaseUrl"

    if ($LASTEXITCODE -ne 0) {
        throw "Flutter exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
