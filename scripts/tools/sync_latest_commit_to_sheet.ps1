param(
    [switch]$DryRun,
    [string]$WebhookUrl
)

$ErrorActionPreference = "Stop"

function Invoke-GitCommand {
    param(
        [string[]]$Arguments
    )

    $output = & git @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }

    return ($output -join "`n").Trim()
}

function Clean-CommitText {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $cleaned = [regex]::Replace($Text, "\[(DONE|COMPLETED|WIP|PENDING)\]\s*", "", "IgnoreCase")
    return [regex]::Replace($cleaned, "\s+", " ").Trim()
}

function Humanize-Token {
    param(
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    $normalized = [regex]::Replace($Value, "[-_/]+", " ").Trim()
    $parts = $normalized -split "\s+" | Where-Object { $_ }
    $humanized = foreach ($part in $parts) {
        if ($part.Length -eq 1) {
            $part.ToUpper()
        }
        else {
            $part.Substring(0, 1).ToUpper() + $part.Substring(1).ToLower()
        }
    }

    return ($humanized -join " ")
}

function Get-CommitStatus {
    param(
        [string]$Subject,
        [string]$Body
    )

    $fullText = "$Subject`n$Body".ToUpperInvariant()
    if ($fullText.Contains("[PENDING]")) {
        return "Pending"
    }
    if ($fullText.Contains("[WIP]")) {
        return "In Progress"
    }
    if ($fullText.Contains("[DONE]") -or $fullText.Contains("[COMPLETED]")) {
        return "Completed"
    }

    return "Completed"
}

function Get-CommitCategory {
    param(
        [string]$CommitType,
        [string]$Text
    )

    switch ($CommitType) {
        "feat" { return "Coding" }
        "fix" { return "Coding" }
        "refactor" { return "Coding" }
        "perf" { return "Coding" }
        "docs" { return "Documentation" }
        "test" { return "Testing" }
        "style" { return "UI/UX" }
        "chore" { return "Maintenance" }
    }

    $lowerText = $Text.ToLowerInvariant()
    if ($lowerText.Contains("test") -or $lowerText.Contains("qa") -or $lowerText.Contains("verify")) {
        return "Testing"
    }
    if ($lowerText.Contains("docs") -or $lowerText.Contains("document") -or $lowerText.Contains("readme")) {
        return "Documentation"
    }
    if ($lowerText.Contains("ui") -or $lowerText.Contains("ux") -or $lowerText.Contains("layout") -or $lowerText.Contains("style") -or $lowerText.Contains("design")) {
        return "UI/UX"
    }

    return "Coding"
}

$prettyFormat = "%H%n%h%n%an%n%ae%n%aI%n%s%n%b"
$rawCommit = Invoke-GitCommand -Arguments @("log", "-1", "--pretty=format:$prettyFormat")
$parts = $rawCommit -split "`r?`n"

if ($parts.Count -lt 6) {
    throw "Unexpected git log output while reading the latest commit."
}

$commitHash = $parts[0]
$commitShortHash = $parts[1]
$authorName = $parts[2]
$authorEmail = $parts[3]
$committedAtIso = $parts[4]
$subject = $parts[5]
$body = if ($parts.Count -gt 6) { ($parts[6..($parts.Count - 1)] -join "`n").Trim() } else { "" }
$branch = Invoke-GitCommand -Arguments @("rev-parse", "--abbrev-ref", "HEAD")

$cleanSubject = Clean-CommitText -Text $subject
$cleanBody = Clean-CommitText -Text $body
$conventional = [regex]::Match(
    $cleanSubject,
    "^(feat|fix|docs|style|refactor|perf|test|chore)(?:\(([^)]+)\))?(!)?:\s*(.+)$",
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

$commitType = ""
$commitScope = ""
$commitSummary = $cleanSubject

if ($conventional.Success) {
    $commitType = $conventional.Groups[1].Value.ToLowerInvariant()
    $commitScope = $conventional.Groups[2].Value
    $commitSummary = $conventional.Groups[4].Value
}

$task = if (-not [string]::IsNullOrWhiteSpace($commitScope)) {
    Humanize-Token -Value $commitScope
}
elseif (-not [string]::IsNullOrWhiteSpace($commitType)) {
    Humanize-Token -Value $commitType
}
else {
    if ($commitSummary.Length -gt 72) {
        $commitSummary.Substring(0, 72)
    }
    else {
        $commitSummary
    }
}

$message = if ([string]::IsNullOrWhiteSpace($cleanBody)) {
    $cleanSubject
}
else {
    "$cleanSubject | $cleanBody"
}

$dateDisplay = [DateTimeOffset]::Parse($committedAtIso).ToString("dd MMM yyyy")
$payload = [ordered]@{
    task              = $task
    message           = $message
    status            = Get-CommitStatus -Subject $subject -Body $body
    jenis             = Get-CommitCategory -CommitType $commitType -Text $message
    date_override     = $dateDisplay
    branch            = $branch
    author            = $authorName
    author_email      = $authorEmail
    commit_hash       = $commitHash
    commit_short_hash = $commitShortHash
    commit_iso_date   = $committedAtIso
    commit_type       = $commitType
    commit_scope      = $commitScope
    commit_summary    = $commitSummary
}

if ($DryRun) {
    $payload | ConvertTo-Json -Depth 5
    exit 0
}

$resolvedWebhookUrl = if ($WebhookUrl) {
    $WebhookUrl
}
elseif ($env:GOOGLE_SHEETS_WEBHOOK_URL) {
    $env:GOOGLE_SHEETS_WEBHOOK_URL
}
elseif ($env:GOOGLE_SHEET_WEBHOOK_URL) {
    $env:GOOGLE_SHEET_WEBHOOK_URL
}
else {
    ""
}

if ([string]::IsNullOrWhiteSpace($resolvedWebhookUrl)) {
    Write-Warning "Skipped Google Sheets sync because GOOGLE_SHEETS_WEBHOOK_URL is not set."
    exit 0
}

$jsonBody = $payload | ConvertTo-Json -Compress -Depth 5
Invoke-RestMethod `
    -Uri $resolvedWebhookUrl `
    -Method Post `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody)) `
    -ContentType "application/json; charset=utf-8" | Out-Null
