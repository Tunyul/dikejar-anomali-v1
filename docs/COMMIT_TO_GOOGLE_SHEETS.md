# Commit to Google Sheets

Dokumen ini menjelaskan cara membuat setiap commit otomatis sinkron ke Google Sheets.

## Ringkas

- Hook yang dipakai ada di `.githooks/post-commit`.
- Script pengirim webhook utama ada di `scripts/tools/sync_latest_commit_to_sheet.ps1`.
- Webhook dibaca dari environment variable `GOOGLE_SHEETS_WEBHOOK_URL`.
- Hook hanya mengirim metadata commit terbaru dan tidak mengubah `CHANGELOG.md`.

## Setup Sekali Saja

Jalankan:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/install_git_hooks.ps1
```

Lalu set webhook untuk sesi aktif:

```powershell
$env:GOOGLE_SHEETS_WEBHOOK_URL = "https://script.google.com/macros/s/your-webhook-id/exec"
```

Jika ingin permanen di Windows:

```powershell
setx GOOGLE_SHEETS_WEBHOOK_URL "https://script.google.com/macros/s/your-webhook-id/exec"
```

## Payload yang Dikirim

Script mengirim JSON dengan field utama berikut:

- `task`
- `message`
- `status`
- `jenis`
- `date_override`
- `branch`
- `author`
- `commit_hash`
- `commit_short_hash`

Field tambahan aman dikirim karena Apps Script bisa mengabaikan field yang tidak dipakai.

## Aturan Commit

Gunakan Conventional Commit:

```text
feat(ui-shop): add sticky cart summary
fix(auth): prevent duplicate login callback
docs(readme): clarify local setup
```

Status bisa dikontrol lewat marker opsional di pesan commit:

- `[DONE]` -> `Completed`
- `[WIP]` -> `In Progress`
- `[PENDING]` -> `Pending`

Jika tidak ada marker, status default adalah `Completed`.

## Prompt untuk AI Web Developer

Gunakan instruksi ini ke AI developer:

```text
Di project ini, setiap selesai membuat commit, commit terbaru harus otomatis sinkron ke Google Sheets melalui webhook.

Aturan kerja:
1. Gunakan Conventional Commit, misalnya feat(scope): summary.
2. Jangan mengubah CHANGELOG.md dari post-commit hook.
3. Pastikan git hook memakai .githooks/post-commit.
4. Jika hook belum aktif, jalankan: powershell -ExecutionPolicy Bypass -File scripts/tools/install_git_hooks.ps1
5. Webhook harus dibaca dari environment variable GOOGLE_SHEETS_WEBHOOK_URL, jangan di-hardcode.
6. Payload minimal yang dikirim: task, message, status, jenis, date_override, branch, commit_short_hash.
7. Marker [DONE], [WIP], dan [PENDING] di commit message harus dipetakan ke status sheet.
8. Jika webhook belum diset, commit tetap boleh lanjut tanpa gagal.
```

## Cek Manual

Untuk melihat payload tanpa mengirim request:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/sync_latest_commit_to_sheet.ps1 -DryRun
```
