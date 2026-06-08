$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    throw "This command must be run inside the repository."
}

Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    Write-Host "Git hooks path set to .githooks" -ForegroundColor Green

    if (-not $env:GOOGLE_SHEETS_WEBHOOK_URL -and -not $env:GOOGLE_SHEET_WEBHOOK_URL) {
        Write-Warning "Set GOOGLE_SHEETS_WEBHOOK_URL before expecting post-commit sync to Google Sheets."
    }
}
finally {
    Pop-Location
}
