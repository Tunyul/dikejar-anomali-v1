## Ringkasan Temuan
- Stack: Godot 4.5, GDScript. Entri utama `project.godot` → `run/main_scene=\"res://scenes/Main.tscn\"`.
- Direktori kunci: `scripts/`, `scenes/`, `assets/`, `.godot/` (metadata).
- Tidak ada konfigurasi Node/JS/Python/Go; tidak ada `package.json`, `pyproject.toml`, `.env`.
- Testing belum ada (tidak ada folder/skrip test).
- Code smells utama:
  - Logging berlimpah dengan `print(...)` di `scripts/player.gd` (mis. `scripts/player.gd:90, 114, 126, 154, 212–214, 249, 264, 271, 294, 310, 327, 340, 344, 387, 443, 481, 488, 494, 497`) dan `scripts/terrain_scroll.gd:44, 80`.
  - Kode di-comment yang tersisa: `scripts/player.gd:321, 358, 382–383`.
  - Pengulangan kuat pada setup collision di `scripts/terrain_generator.gd`.
  - File besar: `scripts/player.gd` (±544 baris), `scripts/terrain_generator.gd` (±492 baris).
- Keamanan: tidak ditemukan secrets/kredensial/hardcoded token; aman.

## Tujuan Bersih-Kode
- Kurangi noise log, tanpa mengubah perilaku gameplay.
- Hapus commented-out code yang tidak relevan.
- Refactor pengulangan collision agar lebih DRY dan mudah dirawat.
- Rapikan struktur fungsi di file panjang untuk keterbacaan.
- Siapkan lint/format dan kerangka testing ringan.

## Rencana Implementasi
1) Logging Terkendali
- Ganti `print(...)` dengan util logging yang hanya aktif di build debug:
  - Opsi A: bungkus langsung `if OS.is_debug_build(): print(...)`.
  - Opsi B: tambah util `scripts/utils/logger.gd` dengan `Logger.debug(args)` yang gate ke `OS.is_debug_build()`.
- Target awal:
  - `scripts/player.gd` di titik info/status: `scripts/player.gd:90, 114, 126, 154, 212–214, 249, 264, 271, 294, 310, 327, 340, 344, 387, 443, 481, 488, 494, 497`.
  - `scripts/terrain_scroll.gd:44, 80`.
- Pertahankan log `WARNING` penting, tetapi tetap dibatasi debug.

2) Bersihkan Commented-Out Code
- Hapus baris yang di-comment dan tidak dipakai: `scripts/player.gd:321, 358, 382–383`.
- Jika ada alternatif yang ingin dipertahankan, pindahkan ke dokumentasi internal (komentar singkat di fungsi aktif) dan pastikan satu implementasi yang konsisten.

3) Refactor Collision Setup (DRY)
- Di `scripts/terrain_generator.gd`, ekstrak helper seperti `func setup_collision_for_source(tile_set, source_id, one_way:=false) -> void`.
- Gantikan blok pengulangan yang mendefinisikan shapes/masks per atlas/source dengan loop yang memanggil helper.
- Hasil: lebih sedikit duplikasi, lebih mudah modifikasi satu tempat.

4) Restruktur File Panjang (Ringan)
- `scripts/player.gd`: kelompokkan logika ke fungsi helper terpisah tanpa memecah file terlebih dulu:
  - Contoh: `apply_gravity()`, `handle_jump_input()`, `update_state_machine()`, `apply_environment_movement(enable)`.
- Evaluasi setelah pemisahan fungsi: jika masih terlalu panjang, fase berikutnya pecah ke script komponen (mis. `player_movement.gd`, `player_state.gd`) dan injeksi via `@onready`.

5) Format & Lint
- Terapkan formatter/linter GDScript komunitas:
  - `gdformat` dan `gdlint` (paket `gdtoolkit`).
- Tambahkan aturan dasar: panjang baris, penamaan snake_case, penghapusan import/variabel tak terpakai.
- Opsional: pre-commit hook untuk menjalankan `gdformat`/`gdlint` pada file `.gd`.

6) Testing Minimal (Regresi)
- Tambahkan plugin GUT (`addons/gut`) untuk Godot 4.
- Buat test unit untuk fungsi non-UI:
  - Generator terrain: validasi konfigurasi `TileSet`, bentuk collision, dan determinisme `rng_seed`.
  - Utility kecil (mis. kalkulasi jarak/kecepatan jika ada).
- Jalankan headless: `godot --headless --run res://addons/gut/gut_cmdln.gd` (setelah GUT diintegrasi).

7) Verifikasi & Performa
- Jalankan scene utama dan pastikan:
  - Tidak ada spam log di build non-debug.
  - Perilaku player/terrain sama (cek transisi state di `scripts/player.gd:443`).
  - Frame time stabil; parallax/terrain tetap sinkron.

## Output yang Diharapkan
- Log terkendali (hanya debug) dan kode bebas commented-out yang tak relevan.
- `terrain_generator.gd` lebih ringkas dengan helper collision.
- `player.gd` lebih mudah dibaca lewat fungsi terstruktur.
- Formatter/linter siap pakai dan baseline tests berjalan.

## Risiko & Mitigasi
- Risiko menghapus log penting → gate via debug, bukan hapus total.
- Perubahan collision bisa memengaruhi gameplay → lakukan bertahap, verifikasi di level/scene terkait.
- Integrasi GUT menambah folder `addons` → dijaga terpisah, tidak memengaruhi runtime kecuali saat test.

## Fase & Urutan
- Fase 1: Logging gate + bersih commented-out code.
- Fase 2: Refactor collision helper.
- Fase 3: Restruktur fungsi `player.gd`.
- Fase 4: Format/lint (`gdformat`/`gdlint`).
- Fase 5: Tambah GUT tests + headless run.

Konfirmasi rencana ini, lalu saya lanjut implementasi bertahap sesuai urutan di atas dengan verifikasi setelah setiap fase.