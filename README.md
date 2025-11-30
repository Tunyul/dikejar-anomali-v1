# Dikejar Anomali — Dokumentasi Singkat

Lihat dokumen gabungan konsep & implementasi pemain: `GAME_CONCEPT_AND_PLAYER_IMPLEMENTATION.md`.

## Ringkasan
- Genre: endless runner 2D dengan latar parallax dan tanah tak berujung.
- Loop: lingkungan bergerak, pemain terkunci horizontal; kumpulkan koin, hindari musuh/obstacle; dikejar "Anomaly" dari kiri layar.
- Progres: skor bertambah dari jarak tempuh; kecepatan lingkungan meningkat seiring waktu; simpan `best_score` ke `user://save.cfg`.

## Tujuan & Game Over
- Bertahan selama mungkin sambil mengumpulkan koin untuk menambah skor.
- Game over saat menabrak obstacle/musuh, jatuh ke celah, atau tertangkap pengejar.

## Kontrol
- `Jump`: `Space`, klik kiri, atau tap layar.
- `Attack`: `K`, klik kanan, atau tap kedua (flag aksi; logika serangan belum aktif penuh).
- `Pause/Resume`: `Esc` (`ui_cancel`).
- `Debug Toggle`: `F3`.

## Fitur Utama
- ParallaxBackground auto-scroll (awan, gunung, langit) yang mulus dan wrap.
- Ground tak berujung dua segmen (A/B) dengan wrapping dan regenerasi dinamis.
- Generator tile/gap: platform, celah, dan opsi flat start untuk fase awal.
- Spawner koin berkelompok/stack dan musuh (blok/kone) pada kedua segmen.
- Pengejar "Anomaly" mengikuti tepi kiri kamera dan muncul bertahap.
- Audio: `BGM` saat bermain dan `SFXJump` saat loncat.

## Mekanika Pemain
- Pemain berhenti pada `entry_stop_x` (tetap di X), lingkungan yang bergerak mengikuti kecepatan target.
- Loncat dengan coyote time dan jump buffer; gravitasi multipliers untuk rasa lompatan yang responsif.
- Snap ke lantai via `RayCast2D`; deteksi celah dan permukaan padat.

## Struktur Proyek
- Scenes:
  - `scenes/Main.tscn` — adegan utama.
  - `scenes/player.tscn` — pemain (AnimatedSprite2D, CollisionShape2D, RayCast2D).
  - `scenes/Ground.tscn` — tanah runner (segmen A/B, kontainer `CoinsA/B`, `EnemiesA/B`).
  - `scenes/Coin.tscn` — koin animasi.
  - `scenes/EnemyBlock.tscn`, `scenes/EnemyCone.tscn` — musuh.
  - `scenes/Obstacle.tscn` — obstacle Area2D pemicu game over.
- Scripts:
  - `scripts/simple_game_manager.gd` — fase bermain/game over, skor/jarak, kontrol lingkungan, simpan progres.
  - `scripts/player.gd` — input, loncat, sinkronisasi speed lingkungan, sinyal game over.
  - `scripts/GroundController.gd` — scroll, wrap A/B, regenerasi, spawn awal koin/musuh.
  - `scripts/TileMapGenerator.gd` — generasi platform/celah, kolider, spawn koin/musuh.
  - `scripts/parallax_auto_scroll.gd` — scroll parallax halus dengan wrapping.
  - `scripts/anomaly_chaser.gd` — posisi relatif kamera, follow Y pemain/ground, animasi.
  - `scripts/coin.gd`, `scripts/enemy_block.gd`, `scripts/obstacle.gd` — perilaku entitas.

## File & Pengaturan Penting
- `project.godot` — Godot 4.5, viewport `1024x576`, stretch `canvas_items`, renderer `mobile`, snap 2D ke pixel.
- Input Actions: `jump`, `attack`, `ui_cancel` telah terkonfigurasi.

## Menjalankan Proyek
- Prasyarat: Godot 4.5.
- Buka `project.godot` di editor Godot.
- Jalankan `Main.tscn` atau `F5` untuk bermain.
- Optimasi: pengaturan rendering `mobile` cocok untuk perangkat bergerak, namun berjalan baik di desktop.

## Penyimpanan Progres
- File pengguna: `user://save.cfg` menyimpan `best_score`, `last_score`, `last_coins`, dan `total_coins`.
