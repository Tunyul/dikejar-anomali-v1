# Changelog

All notable changes to this project are documented in this file.
The format is based on Keep a Changelog and this project adheres to Semantic Versioning.



## [Unreleased]


## [1.3.11-beta] - 2025-12-28

- UI Settings: menu Settings tidak lagi muncul otomatis; hanya dibuka lewat tombol Settings di Main Menu dengan mode overlay
- UI Settings: menambahkan penutupan menu dengan tap di area luar panel sehingga overlay bisa ditutup cepat tanpa tombol
- UI Settings: mengganti tombol teks "Back" menjadi tombol ikon X di kanan atas panel menggunakan aset `tombol_x_96.png`
- UI Settings: mengatur warna teks semua label dan opsi (BGM/SFX) menjadi hitam agar kontras dengan panel
- UI: menerapkan font bebas lisensi (Nunito untuk teks UI, Fredoka Bold untuk judul) pada Main Menu, Settings, Shop, dan Daily Missions
- UI HUD: mengubah warna teks Level, XP, koin, dan skor di PlayerHUD menjadi hitam untuk keterbacaan yang lebih baik
- Naik versi proyek ke 1.3.11-beta

## [1.3.10-beta] - 2025-12-25

- Gameplay/UI: memperbarui flow game over agar tombol "Lanjut (Mulai dari Awal)" dan "Kembali ke Menu Utama" selalu melewati loading screen dengan animasi pemain dikejar Anomaly sebelum masuk scene berikutnya
- Gameplay: restart dari game over kini me-reload `Main.tscn` melalui `LoadingScreen.tscn` sehingga dunia benar-benar diinstans ulang, bukan sekadar reset variabel di scene yang sama
- Pause menu: opsi "Menu" sekarang kembali ke `MainMenu.tscn` lewat loading screen yang sama sehingga seluruh jalur balik ke menu memakai flow transisi konsisten
- Naik versi proyek ke 1.3.10-beta


## [1.3.9-beta] - 2025-12-25

- Hearts: menambahkan scene `HeartPickup.tscn` sebagai pickup nyawa di ground runner
- Hearts: menambahkan animasi melayang sinusoidal untuk heart agar lebih terlihat dan hidup
- Hearts: menambahkan pengaturan skala, jarak minimum antar heart, dan tinggi offset berbasis tile
- Hearts: memperbaiki posisi spawn heart agar konsisten antara editor dan in-game (tidak lagi muncul jauh di atas layar)
- Random: mengembalikan `fixed_seed` generator ground ke 0 agar pola heart kembali acak
- Naik versi proyek ke 1.3.9-beta


## [1.3.8-beta] - 2025-12-25

- UI: menambahkan `HealthBar.tscn` dan menampilkannya di HUD `Main.tscn` sebagai bar nyawa pemain
- Gameplay: mengganti logika hit musuh/obstacle agar mengurangi health dulu sebelum game over
- Gameplay: saat terkena enemy atau obstacle, pemain terpental (knockback) ke arah berlawanan dan mental sedikit ke atas
- Gameplay: menambahkan periode invincibility singkat setelah terkena hit dengan efek sprite berkedip
- Stabilitas: memperbaiki peringatan strict typing pada fungsi health HUD di `game_manager.gd`
- Naik versi proyek ke 1.3.8-beta


## [1.3.7-beta] - 2025-12-24

- Gameplay: menambahkan sistem serangan player (tombol `attack`/KEY_K) dengan state khusus dan hitbox serangan terpisah
- Enemies: saat terkena serangan player, EnemyBlock/EnemyCone sekarang mental dengan knockback, jatuh ke bawah layar, lalu dihapus
- Enemies: setiap enemy yang mati karena serangan pemain menjatuhkan 5–8 koin dengan posisi spawn melingkar di sekitar tubuh musuh
- Coins: koin dari enemy selalu bertindak seperti magnet (tanpa perlu power-up), bergerak cepat mengejar player tetapi tetap terlihat bergerak sebelum diambil
- Coins: menyamakan skala koin drop enemy dengan koin lain dan memperbaiki posisi spawn agar tidak muncul di atas layar
- Stabilitas: memperbaiki beberapa peringatan strict typing (Variant) dan menggunakan `call_deferred` untuk spawn koin dari callback fisika agar bebas error engine
- Naik versi proyek ke 1.3.7-beta


## [1.3.6-beta] - 2025-12-23

- Mobile: menambahkan kembali scene `MobileControls.tscn` dengan tombol `Jump` dan `Attack` standar berbasis `TouchScreenButton`
- Mobile: menghubungkan `JumpButton` dan `AttackButton` ke player melalui `game_manager.gd` sehingga aksi lompat/serang selalu diteruskan
- Input: menambahkan handler `InputEventScreenTouch` di `game_manager.gd` agar tap di layar Android langsung dicek ke area tombol
- Input: mengganti deteksi area tombol dari bentuk lingkaran ke ukuran penuh sprite tombol sehingga bagian atas dan bawah tombol sama‑sama responsif
- Debug: membersihkan eksperimen node `JumpArea` dan script pendukung yang tidak dipakai lagi agar struktur scene lebih sederhana
- Naik versi proyek ke 1.3.6-beta


## [1.3.5-beta] - 2025-12-21

- Input: memperbaiki tombol lompat dan serang agar selalu responsif di awal game dan setelah restart (mobile dan keyboard)
- Input: menyederhanakan routing input di game manager sehingga aksi lompat/serang tidak lagi diblokir oleh fase game yang salah
- UI: menghapus overlay tutorial dan semua referensinya agar tidak lagi menghalangi tampilan serta input pemain
- Gameplay: menambahkan hitung mundur sebelum gameplay dimulai pada start dan restart, dengan label countdown di tengah layar
- Gameplay: memastikan environment dan player baru mulai bergerak penuh setelah entry animasi dan countdown selesai
- Naik versi proyek ke 1.3.5-beta


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
