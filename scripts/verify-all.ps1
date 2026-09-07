[CmdletBinding()]
param(
    [switch]$SkipWebReleaseBuild
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dotnetExecutable = Join-Path $repositoryRoot ".dotnet\dotnet.exe"
$solution = Join-Path $repositoryRoot "backend\EmergencySystem.sln"

if (-not (Test-Path -LiteralPath $dotnetExecutable)) {
    $dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($null -eq $dotnetCommand) {
        throw "A .NET 10 SDK is required. Follow docs/ENVIRONMENT_SETUP.md."
    }

    $dotnetExecutable = $dotnetCommand.Source
}

function Assert-LastCommandSucceeded {
    param([string]$Name)

    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
}

Push-Location $repositoryRoot
try {
    & $dotnetExecutable test $solution --configuration Release
    Assert-LastCommandSucceeded "Backend tests"

    flutter pub get
    Assert-LastCommandSucceeded "Flutter dependency restore"

    flutter analyze
    Assert-LastCommandSucceeded "Flutter analysis"

    flutter test
    Assert-LastCommandSucceeded "Flutter tests"

    if (-not $SkipWebReleaseBuild) {
        flutter build web `
            --release `
            --dart-define "API_BASE_URL=http://localhost:5080"
        Assert-LastCommandSucceeded "Flutter Web release build"
    }
}
finally {
    Pop-Location
}
