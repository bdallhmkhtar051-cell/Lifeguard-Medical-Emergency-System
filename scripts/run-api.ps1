[CmdletBinding()]
param(
    [ValidateSet("http", "https")]
    [string]$LaunchProfile = "http"
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

Push-Location $repositoryRoot
try {
    & $dotnetExecutable run --project $apiProject --launch-profile $LaunchProfile
    if ($LASTEXITCODE -ne 0) {
        throw "The API exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
