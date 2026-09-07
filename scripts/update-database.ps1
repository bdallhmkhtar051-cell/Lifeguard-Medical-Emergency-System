[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dotnetExecutable = Join-Path $repositoryRoot ".dotnet\dotnet.exe"
$apiProject = Join-Path $repositoryRoot "backend\src\EmergencySystem.Api\EmergencySystem.Api.csproj"
$infrastructureProject = Join-Path $repositoryRoot "backend\src\EmergencySystem.Infrastructure\EmergencySystem.Infrastructure.csproj"
$backendDirectory = Join-Path $repositoryRoot "backend"
$toolManifest = Join-Path $backendDirectory ".config\dotnet-tools.json"

if (-not (Test-Path -LiteralPath $dotnetExecutable)) {
    $dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($null -eq $dotnetCommand) {
        throw "A .NET 10 SDK is required. Follow docs/ENVIRONMENT_SETUP.md."
    }

    $dotnetExecutable = $dotnetCommand.Source
}

Push-Location $backendDirectory
try {
    & $dotnetExecutable tool restore --tool-manifest $toolManifest
    if ($LASTEXITCODE -ne 0) {
        throw "The repository-pinned EF Core tool could not be restored."
    }

    & $dotnetExecutable tool run dotnet-ef database update `
        --project $infrastructureProject `
        --startup-project $apiProject

    if ($LASTEXITCODE -ne 0) {
        throw "The database update exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
