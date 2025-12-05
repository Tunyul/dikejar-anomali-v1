param(
  [string]$Version,
  [string]$SinceTag,
  [string]$Output = "CHANGELOG.md"
)

function GetLatestTag {
  $tags = git tag --sort=-v:refname
  if ($LASTEXITCODE -ne 0) { return $null }
  $list = $tags -split "`n" | Where-Object { $_ -ne "" }
  if ($list.Length -gt 0) { return $list[0] } else { return $null }
}

function GetCommitObjects($range) {
  $format = "%H%x1f%s%x1f%b%x1e"
  $raw = git log $range --pretty=format:$format 2>$null
  if ($null -eq $raw -or $raw.Trim() -eq '') { return @() }
  $entries = $raw -split "\x1e" | Where-Object { $_ -ne "" }
  $objs = @()
  foreach ($e in $entries) {
    $parts = $e -split "\x1f"
    $hash = $parts[0]
    $subject = $parts[1]
    $body = $parts[2]
    $m = [regex]::Match($subject, '^(?<type>feat|fix|perf|docs|style|refactor|test|chore|revert)(?:\((?<scope>[^)]+)\))?(?<breaking>!)?: (?<msg>.+)$')
    $type = ''
    $scope = ''
    $msg = $subject
    if ($m.Success) {
      $type = $m.Groups['type'].Value
      $scope = $m.Groups['scope'].Value
      $msg = $m.Groups['msg'].Value
    }
    $breaking = ($m.Success -and $m.Groups['breaking'].Value -ne '') -or ($body -match 'BREAKING CHANGE')
    $objs += [pscustomobject]@{
      Hash = $hash.Substring(0,7)
      Type = $type
      Scope = $scope
      Message = $msg.Trim()
      Breaking = [bool]$breaking
    }
  }
  return $objs
}

function GroupByType($commits) {
  $map = @{
    'feat' = @()
    'fix' = @()
    'perf' = @()
    'docs' = @()
    'refactor' = @()
    'test' = @()
    'chore' = @()
    'revert' = @()
    'style' = @()
    'breaking' = @()
    'others' = @()
  }
  foreach ($c in $commits) {
    if ($c.Breaking) { $map['breaking'] += $c; continue }
    if ($map.ContainsKey($c.Type) -and $c.Type -ne '') { $map[$c.Type] += $c } else { $map['others'] += $c }
  }
  return $map
}

function RenderSection($title, $group) {
  $lines = @("## [$title]")
  if ($title -match '^\d+\.\d+\.\d+$') {
    $date = (Get-Date).ToString('yyyy-MM-dd')
    $lines[0] = "## [$title] - $date"
  }
  if ($group['breaking'].Count -gt 0) {
    $lines += "### Breaking Changes"
    foreach ($c in $group['breaking']) {
      $scope = ""
      if ($c.Scope -ne '') { $scope = "($($c.Scope))" }
      $lines += "- $($c.Message) $scope `[$($c.Hash)`]"
    }
  }
  function RenderList($label, $key) {
    if ($group[$key].Count -gt 0) {
      $lines += "### $label"
      foreach ($c in $group[$key]) {
        $scope = ""
        if ($c.Scope -ne '') { $scope = "($($c.Scope))" }
        $lines += "- $($c.Message) $scope `[$($c.Hash)`]"
      }
    }
  }
  RenderList -label "Features" -key 'feat'
  RenderList -label "Fixes" -key 'fix'
  RenderList -label "Performance" -key 'perf'
  RenderList -label "Refactor" -key 'refactor'
  RenderList -label "Docs" -key 'docs'
  RenderList -label "Tests" -key 'test'
  RenderList -label "Chore" -key 'chore'
  RenderList -label "Revert" -key 'revert'
  RenderList -label "Style" -key 'style'
  if ($group['others'].Count -gt 0) {
    $lines += "### Others"
    foreach ($c in $group['others']) {
      $lines += "- $($c.Message) `[$($c.Hash)`]"
    }
  }
  return ($lines -join "`r`n")
}

$lastTag = $SinceTag
if (-not $lastTag) { $lastTag = GetLatestTag }

$range = $null
if ($lastTag) { $range = "$lastTag..HEAD" } else { $range = "" }

$commits = GetCommitObjects $range
$group = GroupByType $commits

$header = @(
  "# Changelog",
  "",
  "All notable changes to this project are documented in this file.",
  "The format is based on Keep a Changelog and this project adheres to Semantic Versioning."
) -join "`r`n"

$unreleased = RenderSection "Unreleased" $group

$past = ""
if (Test-Path $Output) {
  $existing = Get-Content -Raw -Path $Output
  $matches = [regex]::Matches($existing, '## \[\d+\.\d+\.\d+\][\s\S]*?(?=^## \[|\z)', 'Multiline')
  if ($matches.Count -gt 0) {
    $past = ($matches | ForEach-Object { $_.Value.Trim() }) -join "`r`n`r`n"
  }
}

if ($Version) {
  $release = RenderSection $Version $group
  if ($past -ne "") {
    $content = @($header, "", $unreleased, "", $release, "", $past) -join "`r`n`r`n"
  } else {
    $content = @($header, "", $unreleased, "", $release) -join "`r`n`r`n"
  }
} else {
  if ($past -ne "") {
    $content = @($header, "", $unreleased, "", $past) -join "`r`n`r`n"
  } else {
    $content = @($header, "", $unreleased) -join "`r`n`r`n"
  }
}

Set-Content -Path $Output -Value $content -Encoding UTF8
