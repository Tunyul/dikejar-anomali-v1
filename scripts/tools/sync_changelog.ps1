# Konfigurasi
$ChangelogPath = "CHANGELOG.md"
$WebhookUrl = "https://script.google.com/macros/s/AKfycbzR89AWgAfoMi7Va1D_IW1oM7A8c2Lq9T4vrV-3W9UKFLOnvvYOoJGHxw6rft7tR3nN5w/exec"

# Force UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Baca Content
$Content = Get-Content -Path $ChangelogPath -Raw -Encoding UTF8
$Lines = $Content -split "`n"

$CurrentDate = $null
$CurrentVersion = $null
$CurrentMessages = @()

$AllData = @()

foreach ($Line in $Lines) {
    $Line = $Line.Trim()

    # Deteksi Header Tanggal: ## [1.3.57-beta] - 2026-03-09
    if ($Line -match "## \[(.*?)\] - (\d{4}-\d{2}-\d{2})") {
        # Simpan data sebelumnya jika ada
        if ($CurrentDate -ne $null) {
            $AllData += @{
                Date = $CurrentDate
                Version = $CurrentVersion
                Messages = $CurrentMessages
            }
        }

        # Mulai data baru
        $CurrentVersion = $matches[1]
        $DateStr = $matches[2]
        $CurrentDate = [DateTime]::ParseExact($DateStr, "yyyy-MM-dd", $null).ToString("dd MMM yyyy")
        $CurrentMessages = @()
        continue
    }

    # Deteksi Item List
    if ($Line.StartsWith("- ") -and $CurrentDate) {
        $Msg = $Line.Substring(2).Trim()
        $Msg = $Msg.Replace("**", "").Replace("*", "").Replace("`", "")
        $CurrentMessages += $Msg
    }
}

# Simpan data terakhir
if ($CurrentDate -ne $null) {
    $AllData += @{
        Date = $CurrentDate
        Version = $CurrentVersion
        Messages = $CurrentMessages
    }
}

# Balik Urutan (Agar yang lama dikirim duluan)
[array]::Reverse($AllData)

$Total = $AllData.Count
Write-Host "Found $Total entries. Starting sync..." -ForegroundColor Cyan

$i = 0
foreach ($Entry in $AllData) {
    $i++

    # Gabungkan Pesan
    $MainTask = "Update " + $Entry.Version
    if ($Entry.Messages.Count -gt 0) {
        $FirstMsg = $Entry.Messages[0]
        if ($FirstMsg.Length -gt 50) {
            $MainTask = $FirstMsg.Substring(0, 47) + "..."
        } else {
            $MainTask = $FirstMsg
        }
    }

    $DetailMsg = ""
    foreach ($M in $Entry.Messages) {
        $DetailMsg += "- $M`n"
    }

    $Payload = @{
        task = $MainTask
        message = $DetailMsg
        status = "Completed"
        jenis = "Coding"
        date_override = $Entry.Date
    } | ConvertTo-Json -Compress

    try {
        $Response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($Payload)) -ContentType "application/json; charset=utf-8"
        Write-Host "[$i/$Total] Sent: $($Entry.Date)" -ForegroundColor Green
    }
    catch {
        Write-Host "[$i/$Total] Failed" -ForegroundColor Red
    }

    Start-Sleep -Milliseconds 1000
}

Write-Host "Done!" -ForegroundColor Yellow
