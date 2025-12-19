# Changelog

All notable changes to this project are documented in this file.
The format is based on Keep a Changelog and this project adheres to Semantic Versioning.



## [Unreleased]



## [1.3.4-beta] - 2025-12-19

- Ground runner: menghapus celah kecil antara `TileMapLayerA` dan `TileMapLayerB` dengan overlap 1px antar segmen
- Ground runner: menambahkan `segment_tile_count_min` dan `segment_tile_count_max` dengan default 64 tile per segmen A/B
- Ground runner: memastikan panjang segmen diatur ulang saat init sehingga wrapping tetap halus
- Coins: menambahkan kelompok export `Coins` dan subgroup `Pola / Zigzag` untuk pengaturan di Inspector
- Coins: menambahkan `coin_pattern_mode` dengan pilihan RandomCampur, LengkungNaikTurun, NaikTanggaFlatAtas, dan GarisDatar
- Coins: menambahkan pengaturan `coin_flat_top_min_len` dan `coin_flat_top_max_len` untuk mengontrol panjang coins flat di puncak
- Coins: memastikan grup coins memiliki panjang minimal 3 tile dan menghapus grup pendek serta coin tunggal di puncak
- Coins: menghapus pola coins yang menyeberangi jurang dan membersihkan coins di dekat tepi gap
- Coins: menyempurnakan pola naik–turun agar tidak ada coins turun tanpa awalan naik
- Naik versi proyek ke 1.3.4-beta


## [1.3.3-beta] - 2025-12-17

- Ground runner: menambahkan `min_height_tiles` untuk mengunci tinggi minimum permukaan tanah
- Ground runner: menambahkan `min_step_run_len` dan `max_step_run_len` untuk panjang plateau horizontal
- Ground runner: mencegah tiles up/down 1 kolom di awal, tengah, dan akhir segmen
- Ground runner: memastikan tidak ada gap baru saat run tinggi masih terkunci
- Ground runner: mengatur default `min_platform_len` untuk memaksa platform minimum beberapa tile
- Naik versi proyek ke 1.3.3-beta

## [1.3.2-beta] - 2025-12-17

- Menambahkan scene `LoadingScreen.tscn` dengan background hitam penuh dan label "Loading X%"
- Menambahkan animasi lari karakter pemain dan Anomaly di loading screen
- Mengatur pergerakan pemain dan Anomaly secara loop di bagian bawah layar
- Menambahkan progres loading berbasis waktu hingga 100% di `LoadingScreen.gd`
- Mengintegrasikan `LoadingScreen` dengan `TransitionManager` untuk transisi otomatis ke `MainMenu.tscn`
- Mengubah main scene project menjadi `scenes/LoadingScreen.tscn` untuk flow startup baru
- Naik versi proyek ke 1.3.2-beta

## [1.3.1-beta] - 2025-12-17

- Ground runner: memperbaiki agar `min_gap_len`/`max_gap_len` benar-benar membuat jurang
- Ground runner: mengisi sisa kolom segmen supaya tidak ada "ujung dunia" di akhir
- Ground runner: memastikan kombinasi grass/dirt tetap konsisten di platform dan jurang
- Ground title: tetap flat tanpa jurang melalui konfigurasi `GroundController.gd`
- Naik versi proyek ke 1.3.1-beta

## [1.3.0-beta] - 2025-12-16

- Dokumentasi flow teknis runtime dan rekomendasi fitur/flow di `GAME_CONCEPT_AND_PLAYER_IMPLEMENTATION.md`
- Penjelasan step-by-step MainMenu → Main → gameplay → game over
- Rekomendasi profil kesulitan, Super Easy mode, power-up magnet, dan biome
- Perbaikan bug: ground awal kini mengikuti konfigurasi `TileMapGenerator` (flat_start) di `GroundController.gd`
- Naik versi proyek ke 1.3.0-beta

## [1.2.6] - 2025-12-06

- Perbaikan freeze: memperbarui `world_center` di dalam loop spawn musuh kanan
- Menunda verifikasi scene di awal; menambahkan toggle `scene_verify_on_start`
- Menambahkan watchdog log FPS rendah dan durasi verifikasi scene
- Memperbaiki referensi `_gb_layer` ke `ground_b` di `game_manager.gd`
- Memperbaiki pemanggilan `process_frame` (signal) dan format angka watchdog
- Menambahkan `enemy_block_enabled` untuk menonaktifkan EnemyBlock default
- Naik versi proyek ke 1.2.6

## [1.2.5] - 2025-12-05



## [1.2.4] - 2025-12-05
