# Panduan Kontribusi

## Komit: Conventional Commits

- Gunakan format: `tipe(scope): deskripsi`
- Tipe utama: `feat`, `fix`, `perf`, `docs`, `style`, `refactor`, `test`, `chore`, `revert`
- Breaking change: tambahkan `!` setelah tipe atau tulis baris `BREAKING CHANGE: ...`

### Contoh

- `feat(player): tambah double-jump`
- `fix(camera): perbaiki jitter saat sprint`
- `perf(pathfinding): optimasi A* untuk peta besar`
- `docs: update README dengan cara build`
- `refactor(input): pisahkan handler keyboard dan gamepad`
- `revert: kembalikan perubahan AI karena bug`

## Rilis & Changelog

- Setiap perubahan dicatat di `CHANGELOG.md` mengikuti Keep a Changelog dan SemVer.
- Workflow rilis versi:
  1. Tulis commit menggunakan Conventional Commits.
  2. Bump versi:
     - Patch: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -Type patch`
     - Minor: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -Type minor`
     - Major: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bump-version.ps1 -Type major`
     - Opsi otomatis git commit+tag: tambahkan `-DoGit`.
  3. Skrip di atas akan memperbarui `VERSION`, menyinkronkan `project.godot` (`config/version`), dan menghasilkan entri rilis di `CHANGELOG.md`.
  4. Jika tidak memakai `bump-version`, Anda dapat membuat catatan dari commit manual:
     - `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/generate-changelog.ps1`
     - Untuk rilis: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/generate-changelog.ps1 -Version <versi>`

## Versi

- Ikuti Semantic Versioning: `MAJOR.MINOR.PATCH`
- Naikkan `MAJOR` untuk breaking change, `MINOR` untuk fitur kompatibel, `PATCH` untuk perbaikan bug.

## Penanda Tag

- Saat rilis, gunakan tag `v<MAJOR.MINOR.PATCH>`, contoh: `v0.1.1`.
- Jika menjalankan `bump-version` dengan `-DoGit`, tag dan commit akan dibuat otomatis.
