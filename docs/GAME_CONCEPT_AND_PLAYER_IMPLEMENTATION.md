# Dikejar Anomali — Konsep & Implementasi Pemain

## Ringkasan Proyek
- Genre: runner 2D kasual-komedi; kabur dari “Anomali”, kumpulkan item, hindari rintangan, bertahan sejauh mungkin.
- Engine: Godot 4.5; viewport `1024x576`; renderer `mobile`; input `jump/attack/ui_cancel`.
- Main scene: `scenes/Main.tscn` dengan ParallaxBackground, Player, Ground (dua segmen A/B), Camera2D, AnomalyChaser, audio.

## Konsep & Tema
- Visual: kartun 2D flat, warna pastel; parallax berlapis (langit, gunung, bukit, awan).
- Mood: lucu, cepat, aman, ekspresif.
- Target: anak 6+, remaja ringan, penonton meme.
- Pilar desain:
  - Kejaran terasa: tekanan konstan dari “Anomaly” di kiri.
  - Kontrol responsif: satu tombol dengan coyote time dan jump buffer.
  - Keterbacaan rintangan: bentuk jelas, kontras tinggi, telegraph audio/visual.
  - Flow berkelanjutan: ground wrapping tanpa jeda; reward langsung (skor/koin).
  - Feedback menyenangkan: BGM/SFX ceria, animasi ekspresif.

## Core Gameplay Loop
- Tap “Mulai” → auto-run.
- Tap untuk lompat, hindari rintangan, kumpulkan koin.
- “Anomali” muncul dari belakang dengan efek khas.
- Tertangkap/jatuh → efek lucu, tampil skor; lanjut (rewarded ads — rencana).
- Ulangi untuk skor lebih tinggi, koleksi, kostum (rencana).

## Karakter & Musuh
- Protagonis: anak chibi lucu, kostumisasi (rencana) seperti helm panci/jet botol/sandal besar.
- Anomali (rencana varian): Tung-Tung, Crocodilo, Bomborino, Speakerino — warna cerah, suara unik.

## Visual & Audio
- Style: kartun flat dengan outline tebal; palet pastel (biru muda, kuning, oranye, hijau lembut).
- Background saat ini: pegunungan/awan; ekspansi (rencana): kota, hutan, malam neon.
- Audio: musik ceria ~120 BPM; SFX lompat/koleksi; suara Anomali khas.

## Progres & Monetisasi (Rencana)
- Skor: jarak tempuh; `best_score` tersimpan di `user://save.cfg`.
- Koleksi/Reward: sticker anomali, kostum; tantangan harian/statistik ringan.
- Monetisasi: rewarded ads anak-aman (G-rated), tanpa interstitial di tengah permainan.

## Platform
- Target: Android offline & ringan; potensi iOS setelah stabil.

---

## Implementasi Pemain (Godot 4.5)
- File utama: `scripts/player.gd` (class `Player` pada `CharacterBody2D`).
- Integrasi: `scripts/game_manager.gd` mengelola fase ENTRY/PLAYING/GAME_OVER, skor, jarak, coin, XP, dan sinkronisasi environment.

### Fitur Inti
- Auto-run in-place: pemain terkunci pada `entry_stop_x` (default 280), lingkungan yang bergerak.
- Lompat: `jump_velocity=-400`, `gravity=1200`, `fall_multiplier=1.5`, `max_fall_speed=2000`.
- Responsif: `coyote_time=0.1`, `jump_buffer_time=0.15`, dukungan air jump (`air_jumps`).
- Floor snap: snap dinamis via `RayCast2D` untuk mencegah jitter dan false gap.
- Deteksi rintangan depan: ray + shape probe sempit untuk mengurangi false block.
- Pushback: saat terhalang, pemain terdorong ke kiri dengan recovery bertahap.
- Game over: jika jatuh melewati `fall_death_y=1000` atau tertinggal di kiri layar.
- Animasi: `run` dan `jump` dengan penyesuaian scale/offset otomatis terhadap collision.
- Audio: memutar `Main/SFXJump` saat loncat jika tersedia.

### Parameter Utama (player.gd)
```
@export var run_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 1200.0
@export var fall_death_y: float = 1000.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.15
```

### Integrasi Lingkungan
- Sinkronisasi kecepatan: `lock_environment_speed_to_player=true` → parallax & ground mengikuti `run_speed`.
- Ground wrapping: dua segmen (`TileMapLayer`/`TileMapLayerB`) dikelola oleh `scripts/GroundController.gd`.
- Spawner: koin & musuh awal dipicu oleh `GroundController.gd` dan `TileMapGenerator.gd`.

### Struktur & Referensi
- Scenes relevan:
  - `scenes/Main.tscn` — root, kamera, parallax, pemain, ground, anomaly.
  - `scenes/player.tscn` — node pemain dengan `AnimatedSprite2D`, `CollisionShape2D`, `GroundRay`.
  - `scenes/Ground.tscn` — terrain runner dua segmen, kontainer `CoinsA/B`, `EnemiesA/B`.
- Scripts kunci:
  - `scripts/simple_game_manager.gd` — fase bermain/game over, skor dari jarak, kontrol environment, simpan progres.
  - `scripts/player.gd` — fisika lompat, snap, pushback, animasi, game over.
  - `scripts/GroundController.gd` — scroll, wrap/regenerasi segmen, spawn awal, debug tint.
  - `scripts/TileMapGenerator.gd` — generasi platform/celah, spawn entitas.
  - `scripts/parallax_auto_scroll.gd`, `scripts/anomaly_chaser.gd` — dukungan latar & pengejar.

### Penggunaan
- Buka `project.godot` di Godot 4.5 → jalankan `Main.tscn` (`F5`).
- Kontrol: `Space`/klik kiri/tap = lompat; `K`/klik kanan = aksi; `Esc` = pause; `F3` = debug.

### Catatan Implementasi
- Input action `jump/attack` dipastikan ada di `_ready()` bila belum ada di `project.godot`.
- Sprite scaling otomatis mengikuti ukuran collider untuk konsistensi visual.
- Mekanika lompat menggunakan grace/buffer untuk rasa kontrol yang halus pada perangkat sentuh.

---

## Roadmap Teknis Singkat

Status per: 1.3.18-beta (2026-01-09)

- Flow runtime lengkap (LoadingScreen → MainMenu → Main → Game Over → Retry/Menu) sudah aktif.
- Sistem skor, jarak, coin, health, heart pickup, dan XP dasar sudah terhubung ke save.
- Power-up magnet, double coins, shield, dan speed boost sudah berjalan di gameplay.
- UI utama (Main Menu, Settings overlay, Shop dasar, Game Over) sudah tersedia dan terhubung.

Roadmap lanjutan:

- Animasi lengkap pemain (run/jump/fall) dengan asset final.
- Pengembangan power lain (giant, ghost) dan integrasinya.
- Varian Anomali tambahan dan efek suara khas.
- UI koleksi/kostum dan integrasi penuh dengan Shop.
- Integrasi rewarded ads lanjutan dan optimasi Android.

## Catatan
- Dokumen ini menggabungkan `GAME_CONCEPT.md` (konsep/tema) dan `PLAYER_IMPLEMENTATION.md` (implementasi pemain) dengan penyesuaian agar selaras dengan kode aktual.

---

## Flow Teknis Runtime (Step by Step)

### 1. Main Menu → Gameplay

- Startup:
  - Engine membuka `project.godot` (Godot 4.5, viewport 1024x576, renderer `mobile`).
  - Scene awal: `scenes/MainMenu.tscn` dengan root `MainMenu` (`scripts/MainMenu.gd`).
- Main menu `_ready()`:
	- Connect tombol: `PlayButton`, `QuitButton`.
	- Baca `user://save.cfg` → tampilkan `best_score` dan `total_coins`.
  - Setup `Ground` (instance `scenes/Ground.tscn`) dalam **title mode**:
    - Panggil `set_title_mode(true)` → bersihkan koin/musuh, paksa ground flat.
    - Panggil `generate_random()` → generate segmen awal untuk tampilan menu.
    - Aktifkan movement ground dan batasi speed ke rentang nyaman.
  - Setup `ParallaxBackground` untuk auto-scroll di menu.
- Saat `PlayButton` ditekan:
  - Sembunyikan UI main menu dan nonaktifkan proses `MainMenu`.
  - Panggil `TransitionManager.play_transition_to_scene("res://scenes/Main.tscn")` untuk transisi ke gameplay.

### 2. Setup Scene Gameplay `Main.tscn`

- Root `Main` memakai `scripts/game_manager.gd` sebagai **Game Manager**.
- Node utama:
  - `Player` (`scripts/player.gd`) — karakter pemain.
  - `Ground` (`scenes/Ground.tscn`) — terrain runner dua segmen A/B.
  - `Camera2D` — kamera utama.
  - `AnomalyChaser` (`scripts/anomaly_chaser.gd`) — pengejar dari kiri layar.
  - `CanvasLayer` — HUD, PauseMenu, GameOverMenu.
  - `BGM`, `SFXJump` — audio.
  - `AdManager`, `MissionsManager` — sistem iklan & misi.
- `GameManager._ready()` melakukan:
	- Connect `player.game_over_signal` ke `on_player_game_over`.
	- Tambah input `toggle_debug` (F3) dan `verify_scenes` (F6) jika belum ada.
	- `_load_progress()` dari `user://save.cfg` untuk `best_score`, `last_score`, `total_coins`, dan setting audio.
  - `call_deferred("_start_play_phase")` untuk mulai fase bermain.
  - Opsi debug: jika `scene_verify_on_start` aktif dan build debug, jalankan `_verify_player_scenes()`.
  - Buat `DebugInfoLabel` di CanvasLayer jika debug diaktifkan.
  - Sembunyikan `PauseMenu` dan `GameOverMenu` pada awal permainan.

### 3. Persiapan Ground & Generator

- `GroundController._ready()` (pada instance `scenes/Ground.tscn`):
  - Hitung lebar segmen dari `TileMapLayer` (`_segment_width_px`).
  - Atur posisi `TileMapLayer` dan `TileMapLayerB` agar saling menyambung.
  - Aktifkan `flat_start_enabled` pada segmen A dan generate pertama `generate()`.
  - Matikan `flat_start_enabled` setelah generate, reset flag `_a_flat_removed` dan `_b_ready`.
- `TileMapGenerator._ready()` (pada `TileMapLayer`):
  - Konfigurasi noise dan parameter generasi koin/musuh.
  - Load scene musuh (`EnemyCone.tscn`, `EnemyBlock.tscn`) dan power-up magnet (`MagnetPowerup.tscn`).
  - Jika `auto_generate_on_ready` aktif, panggil `generate()`.

### 4. Masuk Fase Bermain (PLAYING)

- `_start_play_phase()` memanggil `set_playing_phase()` di `game_manager.gd`:
  - `phase = PLAYING`, `game_active = true`.
  - Reset `distance`, `score`, `coin_collected_a`, `coin_collected_b`.
  - Set batas kecepatan ground: `ground_a/ground_b.set_speed_limits(0, max_speed)`.
  - Aktifkan movement untuk `ParallaxBackground`, `Terrain/TerrainB`, dan `Ground`.
  - Set kecepatan awal ground ke `base_speed`.
  - Panggil `player.prepare_for_playing_phase()` dan `player.enable_environment_movement(true)`.
  - Jika konfigurasi mengunci X pemain, paksa posisi X ke `entry_stop_x`.
  - Putar BGM jika tidak muted.
  - Panggil `AnomalyChaser.start_appear()` dan tampilkan pengejar.
  - Sembunyikan `PauseMenu` dan `GameOverMenu`.

### 5. Loop Gameplay per Frame

- Di `_process(delta)` `game_manager.gd` selama `phase == PLAYING`:
  - Hitung `env_speed` dari `ground_a.get_speed()` atau `base_speed`.
  - Update jarak dan skor:
    - `distance += env_speed * delta`.
    - `score = int(distance * score_per_meter)`.
  - HUD koin menampilkan `coin_collected_a + coin_collected_b`.
  - `MissionsManager` (jika ada) menerima update jarak.
  - Hitung `target_speed = clamp(base_speed + distance * speed_gain_per_meter, base_speed, max_speed)` dan kirim ke `ground_a/ground_b.set_speed(target_speed)`.
  - Sesuaikan animasi run pemain dengan kecepatan lingkungan lewat `set_run_anim_factor`.
  - Kelola magnet power-up: kurangi `magnet_timer`, matikan `magnet_enabled` ketika habis (kecuali super easy mode).
  - Terapkan enemy ramp (parameter spawn musuh berubah setelah jarak tertentu).
  - Jalankan coin burst tiap beberapa ratus unit jarak.
  - Atur `player.enable_fall_death` berdasarkan `continue_grace_timer` (grace setelah continue).
  - Jika debug aktif, update `DebugInfoLabel` dan watchdog FPS.
- `GroundController._physics_process(delta)`:
  - Geser `TileMapLayer` dan `TileMapLayerB` berdasarkan kecepatan scroll.
  - Lakukan wrapping segmen ke depan/belakang.
  - Jika `regenerate_on_wrap` aktif, panggil `generate()` dan fungsi spawn awal coins/enemies pada segmen yang baru masuk layar.
- `TileMapGenerator._process(delta)`:
  - Menyelaraskan posisi kontainer `CoinsA/B` dan `EnemiesA/B` dengan gerak ground.
  - Saat kondisi terpenuhi dan FPS cukup, spawn koin/musuh secara infinite dengan object pool.
- `anomaly_chaser._process(delta)`:
  - Menjaga posisi X di sisi kiri kamera + offset.
  - Mengikuti posisi Y pemain/ground menggunakan RayCast dan parameter `hover_height_px`.

### 6. Game Over dan Restart / Continue

- Trigger game over:
  - Player terkena musuh (`enemy_hitbox.gd`) atau obstacle (`obstacle.gd`).
  - Player jatuh melewati `fall_death_y` atau tertinggal jauh di kiri layar.
  - `Player` memancarkan `game_over_signal(cause)` ke `game_manager.on_player_game_over`.
- `on_player_game_over`:
  - Set `phase = GAME_OVER`, `game_active = false`.
  - Nonaktifkan movement pada parallax, terrain, dan ground; set kecepatan ground ke 0.
  - Set `parallax.set_speed(0)` jika fungsi tersedia.
  - Hitung `last_score`, `last_coins`, update `total_coins` dan `best_score`.
  - Simpan progres ke `user://save.cfg`.
  - Stop BGM dan sembunyikan Anomaly.
  - Tampilkan teks "GAME OVER" + skor dan jarak di debug label (opsional).
  - Tampilkan `GameOverMenu` pada CanvasLayer.
- `GameOverMenu` memberikan dua opsi:
  - **Retry**: memanggil `Main.restart_game()` → `set_playing_phase()` ulang (run baru).
  - **Continue (Bonus)**: memanggil `Main.try_rewarded_continue()` → diproses oleh `AdManager` dan memberi `continue_grace_timer` agar pemain bisa lanjut dengan perlindungan sementara.

---

## Rekomendasi Pengembangan Fitur & Flow

### 1. Profil Kesulitan (Difficulty Profile)

- Bungkus parameter berikut ke dalam satu profil kesulitan:
	- Kecepatan: `base_speed`, `max_speed`, `speed_gain_per_meter`.
	- Musuh: `enemy_spawn_enabled`, `enemy_spacing_tiles_min/max`, `enemy_groups_min/max`, `enemy_min_platform_tiles`, dsb.
	- Koin: densitas spawn, `coin_wave_enabled`, `coin_circle_enabled`, jarak aman terhadap musuh.
- Implementasi:
	- Tambah fungsi `apply_difficulty_profile(profile: Dictionary)` di `game_manager.gd` dan `TileMapGenerator.gd`.
	- Pilih profil berdasarkan jarak tempuh atau progres pemain.

### 2. Power-Up Magnet yang Terlihat Jelas

- Gunakan variabel yang sudah ada (`magnet_enabled`, `magnet_timer`, `powerup_magnet_duration_sec`).
- Tambah elemen HUD:
  - Icon magnet di `CanvasLayer` yang menyala saat `magnet_enabled` true.
  - Efek visual di player (glow atau partikel) selama durasi magnet.
- Di kode, pastikan spawn `MagnetPowerup.tscn` menggunakan sistem spawn generator yang sudah ada.

### 3. Flow Continue (Rewarded Ads)

- Perkuat alur `try_rewarded_continue()`:
  - Pisahkan tanggung jawab:
    - `AdManager` mengatur load & show iklan + callback hasil.
    - `GameManager` mengatur efek gameplay: reset posisi player, isi kembali grace timer, mungkin beri shield.
  - Gunakan `continue_grace_timer` untuk membuat periode kebal singkat setelah continue.
- Tambahkan penjelasan singkat di GameOverMenu tentang apa yang didapat pemain jika memilih Continue.

### 4. Tutorial & Onboarding

- Manfaatkan `tutorial_enabled` dan `tutorial_shown`:
  - Run pertama: tampilkan overlay "Tap untuk lompat" dan "Hindari musuh/obstacle".
  - Matikan spawn musuh di beberapa segmen awal dengan mengubah parameter generator.
- Simpan `tutorial_shown` di `save.cfg` agar tutorial hanya tampil sekali, kecuali di-reset.

### 5. Biome / Dunia Berbeda

- Gunakan kemampuan `TileMapGenerator` dan `Ground.tscn` untuk beberapa tema visual:
  - Misal: Spring, City, Night.
- Untuk setiap biome:
  - Tileset berbeda.
  - Parameter gap/musuh/koin sedikit diubah.
  - BGM dan warna background disesuaikan.
- Pilih biome berdasarkan jarak atau progres pemain.

### 6. Tool Internal & QA

- Sempurnakan `_verify_player_scenes()` menjadi tool QA:
  - Cek semua scene `.tscn` yang mengandung `Player`.
  - Pastikan selalu ada `AnimatedSprite2D` + `CollisionShape2D` dengan ukuran minimal.
  - Tambah check untuk enemy/obstacle standar (hitbox, layer/mask benar).
- Jalankan tool ini sebelum build untuk mencegah scene rusak.
