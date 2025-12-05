param(
  [ValidateSet('major','minor','patch')][string]$Type = 'patch',
  [switch]$DoGit
)

$ErrorActionPreference = 'Stop'

function ParseVersion($s) {
  $m = [regex]::Match($s.Trim(), '^(?:v)?(?<maj>\d+)\.(?<min>\d+)\.(?<pat>\d+)')
  if (-not $m.Success) { throw "Versi tidak valid: $s" }
  return [pscustomobject]@{ Major = [int]$m.Groups['maj'].Value; Minor = [int]$m.Groups['min'].Value; Patch = [int]$m.Groups['pat'].Value }
}

function ToString($v) { return "$($v.Major).$($v.Minor).$($v.Patch)" }

function Bump($v, $type) {
  switch ($type) {
    'major' { return [pscustomobject]@{ Major = $v.Major + 1; Minor = 0; Patch = 0 } }
    'minor' { return [pscustomobject]@{ Major = $v.Major; Minor = $v.Minor + 1; Patch = 0 } }
    'patch' { return [pscustomobject]@{ Major = $v.Major; Minor = $v.Minor; Patch = $v.Patch + 1 } }
  }
}

function ReadCurrentVersion() {
  $versionPath = Join-Path (Get-Location) 'VERSION'
  if (Test-Path $versionPath) {
    $raw = Get-Content -Raw -Path $versionPath
    return ParseVersion $raw
  }
  $tags = git tag --sort=-v:refname 2>$null
  if ($LASTEXITCODE -eq 0 -and $tags) {
    $first = ($tags -split "`n" | Where-Object { $_ -ne '' } | Select-Object -First 1)
    return ParseVersion $first
  }
  return ParseVersion '0.1.0'
}

function WriteVersion($v) {
  $s = ToString $v
  Set-Content -Path (Join-Path (Get-Location) 'VERSION') -Value $s -Encoding UTF8
  return $s
}

function UpdateProjectGodot($versionString) {
  $proj = Join-Path (Get-Location) 'project.godot'
  if (-not (Test-Path $proj)) { return }
  $lines = Get-Content -Path $proj
  $appMatch = Select-String -InputObject $lines -Pattern '^\[application\]' | Select-Object -First 1
  if (-not $appMatch) { return }
  $start = $appMatch.LineNumber - 1
  $nextSection = Select-String -InputObject $lines -Pattern '^\[' | Where-Object { $_.LineNumber -gt $appMatch.LineNumber } | Select-Object -First 1
  if ($nextSection) { $end = $nextSection.LineNumber - 2 } else { $end = $lines.Length - 1 }
  $found = $false
  for ($i = $start; $i -le $end; $i++) {
    if ($lines[$i] -match '^config/version=') { $lines[$i] = ('config/version="' + $versionString + '"'); $found = $true; break }
  }
  if (-not $found) {
    $nameIndex = -1
    for ($i = $start; $i -le $end; $i++) { if ($lines[$i] -match '^config/name=') { $nameIndex = $i; break } }
    if ($nameIndex -ge 0) { $insertAt = $nameIndex + 1 } else { $insertAt = $start + 1 }
    $pre = @()
    if ($insertAt -gt 0) { $pre = $lines[0..($insertAt-1)] }
    $post = @()
    if ($insertAt -lt ($lines.Length)) { $post = $lines[$insertAt..($lines.Length-1)] }
    $lines = $pre + @('config/version="' + $versionString + '"') + $post
  }
  Set-Content -Path $proj -Value ($lines -join "`r`n") -Encoding UTF8
}

function GenerateChangelog($versionString) {
  $script = Join-Path $PSScriptRoot 'generate-changelog.ps1'
  if (Test-Path $script) {
    & $script -Version $versionString
  }
}

$current = ReadCurrentVersion
$next = Bump $current $Type
$nextStr = WriteVersion $next
UpdateProjectGodot $nextStr
GenerateChangelog $nextStr

if ($DoGit) {
  git add VERSION CHANGELOG.md project.godot 2>$null
  git commit -m "release: v$nextStr" 2>$null
  git tag "v$nextStr" 2>$null
  git push --follow-tags 2>$null
}

Write-Output "Version bumped to $nextStr"
