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
- Integrasi: `scripts/simple_game_manager.gd` mengelola fase bermain/game over serta sinkronisasi environment.

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
- Animasi lengkap pemain (run/jump/fall) dengan asset final.
- Power-up: Bubble Shield, Speed Boost, Sticker Magnet.
- Varian Anomali tambahan dan efek suara khas.
- UI: menu utama, game over, kostum & koleksi.
- Integrasi rewarded ads dan optimasi Android.

## Catatan
- Dokumen ini menggabungkan `GAME_CONCEPT.md` (konsep/tema) dan `PLAYER_IMPLEMENTATION.md` (implementasi pemain) dengan penyesuaian agar selaras dengan kode aktual.

