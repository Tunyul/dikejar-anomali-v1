# Anomaly Rush! — Dokumentasi Singkat

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
- `Attack`: `K`, klik kanan, atau tap kedua (hitbox serangan aktif untuk musuh).
- `Pause/Resume`: `Esc` (`ui_cancel`).
- `Debug Toggle`: `F3`.

## Fitur Utama

- ParallaxBackground auto-scroll (awan, gunung, langit) yang mulus dan wrap.
- Ground tak berujung dua segmen (A/B) dengan wrapping dan regenerasi dinamis.
- Generator tile/gap: platform, celah, dan opsi flat start untuk fase awal.
- Spawner koin berkelompok/stack dan musuh (blok/kone) pada kedua segmen.
- Pengejar "Anomaly" mengikuti tepi kiri kamera dan muncul bertahap.
- Sistem misi tabbed (daily/mission/week/month/challenge) dengan reward coin dan tombol claim.
- Sistem XP/level + pending level rewards yang bisa di-claim di Main Menu.
- Shop: currency coin/gems dari save, pembelian item/upgrades tersimpan ke `user://save.cfg`.
- Audio: BGM gameplay + BGM Game Over + ducking otomatis untuk SFX penting.

## Mekanika Pemain

- Pemain berhenti pada `entry_stop_x` (tetap di X), lingkungan yang bergerak mengikuti kecepatan target.
- Loncat dengan coyote time dan jump buffer; gravitasi multipliers untuk rasa lompatan yang responsif.
- Snap ke lantai via `RayCast2D`; deteksi celah dan permukaan padat.

## Struktur Proyek

- Scenes:
  - `scenes/Main.tscn` — adegan utama (GameManager, HUD, parallax, ground, anomaly, mobile controls).
  - `scenes/MainMenu.tscn` — menu utama (Play, Shop, Settings, PlayerHUD, Missions).
  - `scenes/LoadingScreen.tscn` — layar loading dengan animasi lari pemain dan Anomaly.
  - `scenes/player.tscn` — pemain (AnimatedSprite2D, CollisionShape2D, RayCast2D).
  - `scenes/Ground.tscn` — tanah runner (segmen A/B, kontainer `CoinsA/B`, `EnemiesA/B`).
  - `scenes/Coin.tscn` — koin animasi.
  - `scenes/EnemyBlock.tscn`, `scenes/EnemyCone.tscn` — musuh.
  - `scenes/Obstacle.tscn` — obstacle Area2D pemicu game over.
- Scripts:
  - `scripts/game_manager.gd` — fase ENTRY/PLAYING/GAME_OVER, skor/jarak/coin/XP, kontrol environment, save, power-up.
  - `scripts/player.gd` — state machine player, input, lompat, serangan, health, sinyal game over.
  - `scripts/infinite_ground.gd` — scroll, wrap A/B, generasi platform/celah, spawn koin/musuh/power-up/heart/diamond.
  - `scripts/parallax_auto_scroll.gd` — scroll parallax halus dengan wrapping.
  - `scripts/anomaly_chaser.gd` — posisi relatif kamera, follow Y pemain/ground, animasi.
  - `scripts/coin.gd`, `scripts/enemy_block.gd`, `scripts/obstacle.gd` — perilaku entitas.

## File & Pengaturan Penting

- `project.godot` — Godot 4.5, viewport `1024x576`, stretch `canvas_items`, renderer `mobile`, snap 2D ke pixel.
- Input Actions: `jump`, `attack`, `ui_cancel` telah terkonfigurasi.

## Menjalankan Proyek

- Prasyarat: Godot 4.5.
- Buka `project.godot` di editor Godot.
- `F5` menjalankan startup flow dari `scenes/LoadingScreen.tscn`.
- Jalankan `Main.tscn` untuk langsung masuk gameplay (tanpa flow startup).
- Optimasi: pengaturan rendering `mobile` cocok untuk perangkat bergerak, namun berjalan baik di desktop.

## Penyimpanan Progres

- File pengguna: `user://save.cfg` menyimpan progres utama (best/last score, total coins/gems, level/xp, missions, powerups, cosmetics, settings).

## Kontrak Runtime v2

- `meta.save_schema_version = 3`.
- Ownership domain:
  - `GameManager`: `progress`, `powerups`, `rewards`.
  - `MissionsManager`: `missions`.
- Kunci claim misi standar: `missions.reward_claimed` (legacy `missions.mission_reward_claimed` dimigrasikan saat load).
- API claim/purchase utama:
  - `GameManager.claim_season_reward`, `GameManager.claim_all_pending_rewards`.
  - `MissionsManager.claim_mission`, `MissionsManager.claim_daily_all_reward`, `MissionsManager.apply_daily_reset`.
  - `GameManager.apply_shop_purchase`, `GameManager.activate_skill`.
- Semua API claim/purchase memakai kontrak deterministik: sukses `ok=true`, gagal `ok=false` dengan `error` string.
