# Changelog

All notable changes to this project are documented in this file.
The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## [Unreleased]

## [1.3.37-beta] - 2026-02-20

- Docs: Menambahkan `DEPLOYMENT_GUIDE_ID.md` sebagai panduan rilis dan persiapan QA/Beta.
- Gameplay: Memendekkan `flat_start_length_tiles` menjadi 24 agar fase awal run tidak terlalu panjang.
- Gameplay: Menambahkan reset ground ke posisi flat-start saat run dimulai ulang, termasuk flow continue setelah Game Over + rewarded ad.
- Gameplay: Menjaga nilai run saat lanjut (score/coins/gems) agar tidak ter-reset ke nol ketika masuk fase play lagi.
- Missions UI: Memperbaiki responsif panel misi di berbagai ukuran layar agar tidak melebar full-screen.
- Missions: Tombol reset daily sekarang hanya tampil setelah semua misi daily selesai.
- Missions: Tombol reset daily langsung memicu rewarded ad dan mereset misi harian seketika tanpa menunggu timer.
- Shop: Menambahkan item baru `Daily Coins Claim` (100-500 coins/hari).
- Shop: Klaim pertama per hari gratis; klaim berikutnya di hari yang sama wajib rewarded ad.
- Shop: Menambahkan animasi coin fly dan SFX claim untuk klaim daily coins.
- Shop: Memperbaiki input tap agar tombol claim/buy item shop kembali responsif.

## [1.3.36-beta] - 2026-02-20

- Feature: Integrasi penuh AdMob (Banner, Interstitial, Rewarded) menggunakan plugin Poing Studios.
- Fix: Mengatasi crash pada perangkat Android tertentu dengan menurunkan versi library `play-services-ads` ke 23.0.0.
- Fix: Menyesuaikan ukuran Banner menjadi standar `AdSize.BANNER` (320x50) agar posisi otomatis di tengah (center) dan tidak menutupi tombol.
- Fix: Menambahkan dummy banner pada editor/PC untuk visualisasi area iklan.
- Fix: Mengatasi error `JavascriptEngine` dengan penyesuaian versi library dan konfigurasi Gradle.
- Docs: Menambahkan panduan penggunaan AdMob (`ADMOB_USAGE.md`) termasuk contoh implementasi Game Over dan Reward Ganda.

## [1.3.35-beta] - 2026-02-20

- Fix: Mengatasi indentasi error pada `AdManager.gd` agar sesuai standar GDScript (spasi vs tab).
- Fix: Standardisasi nama aplikasi menjadi "Anomaly Rush!" pada `PRIVACY_POLICY.md` dan `export_presets.cfg`.
- Fix: Mengatasi masalah overlay Menu Misi Harian yang tertutup judul dengan memindahkan ke `CanvasLayer` (layer 200).
- Fix: Mengatasi masalah overlay Menu Settings dengan menyamakan struktur `CanvasLayer` (layer 200).
- Refactor: Menyeragamkan logika overlay menu (Misi & Settings) untuk maintenance yang lebih mudah.

## [1.3.34-beta] - 2026-02-18

- Fix: Mobile - Mengatasi error `can_process: Condition "!is_inside_tree()" is true` dengan menambahkan pengecekan `is_instance_valid()` dan `is_inside_tree()` pada GameManager dan Parallax.
- Fix: Mobile - Mengatasi ground yang masih terputus/gap di awal dengan meningkatkan `flat_start_length_tiles` ke 150 dan `_seg_overlap_px` ke 4.0.
- Improve: Mobile - Meningkatkan stabilitas saat scene transition.

## [1.3.33-beta] - 2026-02-18

- Fix: Mobile - Mengatasi gap/jurang pada ground dan start yang tidak flat dengan memperpanjang `flat_start_length_tiles` (100) dan menambah overlap segmen.
- Fix: Mobile - Mengatasi area hitam pada background parallax di layar lebar (aspect ratio tinggi) dengan duplikasi sprite otomatis hingga width minimum 4096px.
- Fix: Mobile - Mengubah renderer default mobile ke `gl_compatibility` (OpenGL ES 3.0) untuk mencegah crash `VK_ERROR_SURFACE_LOST_KHR` pada beberapa device.
- Naik versi proyek ke 1.3.33-beta

## [1.3.32-beta] - 2026-02-18

- Fix: Memperbaiki ukuran ikon heart yang terlalu besar (sekarang scale 0.2).
- Fix: Memperbaiki spawn heart berlebih saat health berkurang (tambahkan cooldown 2 detik dan limit spawn).
- Fix: Mencegah heart spawn saat health pemain penuh.
- Fix: Memperbaiki masalah spawn heart per-tile dengan memastikan persistensi jarak antar segmen.
- Feature: Menambahkan mekanisme emergency spawn heart saat health rendah (< max) dan tidak ada heart di depan.
- Debug: Menambahkan logging detail untuk jumlah spawn heart dan estimasi jarak dalam pixel.
- Naik versi proyek ke 1.3.32-beta

## [1.3.31-beta] - 2026-02-15

- Android: Aktivasi `show_as_launcher_app` agar ikon muncul di app drawer/launcher Android.
- Android: Menambahkan kelengkapan resolusi ikon launcher (48x48, 72x72, 96x96, 144x144, 192x192).
- Android: Perbaikan tombol Jump & Attack yang hilang pada build Android.
- Android: Implementasi fallback layout (96x96) jika tekstur tombol gagal dimuat tepat waktu.
- Android: Penambahan validasi ukuran viewport untuk inisialisasi layout mobile yang lebih stabil.
- Android: Pemaksaan visibilitas node `MobileControls` saat inisialisasi state playing.
- Fix: Migrasi sistem pengecekan aset dari `FileAccess` ke `ResourceLoader.exists()` untuk kompatibilitas penuh dengan sistem file Android (APK/PCK).
- Fix: Normalisasi nama file aset (menghapus spasi dan menggantinya dengan underscore) untuk mencegah error loading pada sistem operasi berbasis Linux/Android.
- Fix: Pemetaan ulang (re-mapping) SFX Koin dan Misi di `TransitionManager.gd` agar sesuai dengan nama file aset fisik.
- Android: Memperbarui `export_presets.cfg` dengan launcher icon resmi (`icon_apk.png`) dan filter inklusi aset yang lebih ketat untuk menjamin kelengkapan data saat compile.
- Naik versi proyek ke 1.3.31-beta

## [1.3.30-beta] - 2026-02-14

- Shop: Memperbaiki ketidaksesuaian ikon pada item Shop (Heart, Magnet, dan Multiplier).
- Shop: Mengganti ikon koin pada item "Upgrade Nyawa Maks" menjadi ikon hati yang sesuai.
- Shop: Memperbarui ikon Magnet menjadi versi dengan indikator timer untuk merepresentasikan durasi.
- Shop: Mengganti ikon koin pada item "Upgrade Multiplier Double Coins" menjadi ikon multiplier yang spesifik.
- Naik versi proyek ke 1.3.30-beta

## [1.3.29-beta] - 2026-02-13

- Parallax: Memperbaiki sistem parallax agar bergerak otonom menggunakan `scroll_base_offset` untuk menghindari konflik dengan Camera2D.
- Parallax: Menambahkan sinkronisasi pergerakan parallax dengan countdown; parallax hanya mulai bergerak setelah fase bermain aktif.
- Parallax: Memastikan parallax berhenti saat fase Game Over untuk konsistensi visual.
- Parallax: Menambahkan logging debug untuk memantau status inisialisasi dan kecepatan parallax secara real-time.
- Fix: Memperbaiki error indentasi pada script `player.gd`.
- Refactor: Menghapus logika kontrol parallax yang tersebar di `game_manager.gd` dan `player.gd` untuk sentralisasi pada script parallax otonom.
- Fix: Memperbaiki skala visual `EnemyBlock` yang terlalu kecil (sekarang `anim_scale = 1.2`) dan menyesuaikan posisi `y` agar menempel tepat di atas tanah.
- Fix: Memperbaiki error indentasi (campuran space dan tab) pada script `enemy_block.gd`.
- Naik versi proyek ke 1.3.29-beta

## [1.3.28-beta] - 2026-02-11

- Fix: Restorasi aset audio (BGM/SFX) dan visual yang hilang akibat kesalahan merge.
- Fix: Memperbaiki error `MissionsManager` tidak ditemukan dengan mendaftarkannya kembali ke Autoload.
- Fix: Memperbaiki `LoadingScreen` agar tidak stuck jika remote content tidak tersedia (base_url kosong).
- Audio: Memperbaiki logika inisialisasi `AudioStreamPlayer` dan fallback sistem SFX.
- Git: Sinkronisasi branch dev ke beta untuk backup versi stabil.

## [1.3.27-beta] - 2026-02-10

- Settings: memperbaiki pembukaan menu Settings di main menu dan in-game agar overlay tampil.
- Settings: menghubungkan sinyal Settings ke audio game saat overlay dibuka in-game.
- UI Settings: memastikan isi panel tampil dengan layout scroll yang benar.
- Naik versi proyek ke 1.3.27-beta

## [1.3.26-beta] - 2026-01-30

- Shop: menambahkan label "Coming Soon" pada Cosmetics, Gem Packs, dan Bundles.
- Shop: tampilkan full item shop di editor (data runtime + non-clip).
- Naik versi proyek ke 1.3.26-beta

## [1.3.25-beta] - 2026-01-28

- Shop: menyamakan daftar skill dan upgrade (magnet, shield, double coins, speed boost) antara runtime dan dummy editor, termasuk kategori coins/gems.
- Shop: mengganti font angka (koin, gems, harga item) agar memakai font yang sama dengan judul "Shop" dan menambahkan outline hitam untuk keterbacaan.
- Shop: menambahkan tampilan angka uji `123456789` di editor untuk memeriksa bentuk semua digit.
- Speed Boost: membuat pickup Speed Boost in-game ikut terpengaruh upgrade durasi dan multiplier dari Shop sehingga efek sesuai deskripsi upgrade.
- Naik versi proyek ke 1.3.25-beta

## [1.3.24-beta] - 2026-01-24

- Shop: menambahkan menu Shop baru dengan kategori Skills & Power-ups, Upgrades, Cosmetics, Gem Packs, dan Bundles.
- Shop: memakai koin/gems dari save (`progress/total_coins` dan `progress/total_gems`) dengan tampilan ikon dan harga yang jelas.
- Shop: menampilkan jumlah item/power-up yang sudah dimiliki dan menonaktifkan tombol beli jika saldo tidak cukup atau skin sudah dimiliki.
- Shop: setiap pembelian langsung menyimpan perubahan ke `user://save.cfg` (coins/gems, powerups, dan data cosmetics/skin) serta me-refresh UI Shop.
- Save: memastikan `meta/version` di `user://save.cfg` mengikuti `application/config/version` aktif untuk keperluan debug/migrasi.
- Naik versi proyek ke 1.3.24-beta

## [1.3.23-beta] - 2026-01-17

- Audio: menambahkan BGM khusus saat Game Over.
- Audio: BGM tidak stop dan tidak restart saat Pause/Settings.
- Audio: menambahkan ducking BGM otomatis saat SFX penting.
- Fix: perbaiki strict typing warning (shadowed variable + Variant inference).
- Naik versi proyek ke 1.3.23-beta

## [1.3.22-beta] - 2026-01-17

- SFX: tambah SFX baru untuk enemy kill, game over, dan pickup powerup/heart.
- Gameplay: trigger SFX pada kill enemy, game over, dan pickup magnet/shield/double coins/speed boost/heart.
- Main Menu: menambahkan rotasi backsound + toast judul track.
- Naik versi proyek ke 1.3.22-beta

## [1.3.21-beta] - 2026-01-15

- Missions UI: merapikan alignment row misi (label Name expand + clip).
- Missions UI: memastikan scrollbar list misi tidak tampil tapi tetap bisa drag-scroll.
- Fix: merapikan indentasi `MissionsListScroll.gd`.
- Naik versi proyek ke 1.3.21-beta

## [1.3.20-beta] - 2026-01-14

- Missions UI: merapikan layout panel misi (tab naik, lebar list konsisten, tanpa background hitam transparan).
- Missions UI: memperjelas label reset (format per tipe reset) dan memastikan warna teks hitam.
- Missions UI: membatasi area tampil list misi agar misi ke-5+ masuk scroll (clip + viewport).
- Missions UI: menambahkan drag-scroll pada list misi (tap/drag di area list, tanpa perlu scrollbar).
- Missions UI: mendukung jumlah misi > 5 dengan duplikasi row otomatis dan koneksi tombol Claim aman.
- Fix: perbaiki path refresh panel setelah Claim agar UI langsung ter-update.
- Naik versi proyek ke 1.3.20-beta

## [1.3.19-beta] - 2026-01-09

- Missions: menambahkan struktur misi lengkap (daily, mission, week, month, challenge) dengan field `reward` per misi yang tersimpan di `user://save.cfg`.
- Missions: memastikan progres misi distance dan coins tetap kompatibel dengan save lama dengan fungsi upgrade di `MissionsManager.gd`.
- Missions UI: memperluas scene `DailyMissionsMenu.tscn` menjadi panel tabbed (Daily/Mission/Week/Month/Challenge) dengan tiga slot misi yang menampilkan nama, progress bar, dan reward coins.
- Missions UI: menambahkan tombol `Claim` per misi yang sudah selesai, hanya aktif jika target tercapai, memiliki reward, dan belum diklaim.
- Rewards: saat reward misi di-claim, coins langsung ditambahkan ke `progress/total_coins` di save dan HUD koin di Main Menu ikut ter-update.
- Rewards: menyimpan status reward misi yang sudah diklaim di section `missions/reward_claimed` sehingga tidak bisa diambil dua kali.
- UX: memperbaiki error koneksi sinyal ganda pada tombol Daily/Reward di `MainMenu.gd` dengan guard `is_connected`.
- Naik versi proyek ke 1.3.19-beta

## [1.3.18-beta] - 2026-01-09

- Speed Boost: membuat efek boostspeed benar-benar mempercepat ground, parallax, dan run speed player secara instan selama durasi skill.
- Speed Boost: menambahkan mode terbang (fly) dengan ketinggian yang bisa diatur dan memastikan player turun kembali dengan aman.
- Speed Boost: mencegah player jatuh langsung ke jurang ketika countdown boost berakhir tepat di atas gap, dengan menahan gravitasi hingga ada ground di bawah.
- HUD: menambahkan label internal untuk memantau kecepatan environment, parallax, dan player saat boost (hanya aktif saat debug).
- HUD: mematikan kembali semua label debug dan informasi spawn untuk build normal agar tampilan lebih bersih.
- Naik versi proyek ke 1.3.18-beta

## [1.3.17-beta] - 2026-01-08

- Coins: mengurangi densitas coins dengan menerapkan peluang nyata pada awal grup (`coin_spawn_chance`) dan juga pada fallback isi-kolom kosong di `infinite_ground.gd`, sehingga jalur tidak lagi dipenuhi coins di hampir setiap kolom.
- Coins: mempertahankan pola grup dan gap berbasis tile (min/max panjang grup dan jarak antar grup) sehingga feel lari tetap variatif, tapi dengan jumlah coins yang lebih wajar.
- Hearts: mengunci perilaku agar heart darurat hanya muncul saat HP berkurang dan tidak ada heart lain di depan, dengan jarak spawn 500–700px di depan kamera.
- Hearts: memblokir semua spawn heart dari generator ground ketika HP player sudah penuh dengan memanggil `Main.can_spawn_hearts()` dari `infinite_ground.gd`, sehingga heart tidak lagi terbuang saat HP full.
- Game over: memastikan dunia berhenti (ground, terrain, parallax) dan tidak lagi men‑spawn heart setelah status game over aktif.
- Naik versi proyek ke 1.3.17-beta

## [1.3.16-beta] - 2026-01-03

- UI Game Over: memisahkan panel konfirmasi (ConfirmPanel) ke scene terpisah agar mudah dipakai ulang dan lebih rapi di `Main.tscn`.
- UI Game Over: mengganti ConfirmDialog bawaan Godot dengan panel kustom berukuran 350x244 yang selalu muncul di tengah layar.
- UI Game Over: memperkecil dan mengganti tombol konfirmasi menjadi ikon checklist dan X versi 64x64, dengan jarak dan posisi yang konsisten di semua resolusi.
- UI Game Over: memastikan teks konfirmasi selalu berwarna hitam dan tidak terkena override tema lain, baik di editor maupun saat runtime.
- UX: mengubah flow sehingga panel konfirmasi hanya muncul saat pemain menekan tombol Lanjut ke Menu atau Bonus, bukan langsung ketika Game Over.
- Naik versi proyek ke 1.3.16-beta

## [1.3.15-beta] - 2025-12-30

- Gameplay/UI: menyederhanakan flow game over sehingga tombol tidak perlu ditekan dua kali; semua aksi (ulang, lanjut bonus, kembali ke menu) sekarang memakai panel konfirmasi popup.
- UI Game Over: mengganti tombol teks menjadi ikon datar tanpa background, disusun horizontal di bagian bawah panel.
- UI Game Over: menyesuaikan posisi konten (score, jarak, tombol) agar lebih terpusat di kartu.
- Stabilitas: memperbaiki peringatan `ext_resource invalid UID` untuk aset `tombol_home_96x96.png` di `Main.tscn` dan `GameOver.tscn`.
- Save: menyimpan versi game aktif ke `user://save.cfg` pada kunci `meta/version` untuk keperluan debugging dan migrasi data di masa depan.
- Naik versi proyek ke 1.3.15-beta

## [1.3.14-beta] - 2025-12-30

- Powerup: menambahkan countdown HUD untuk skill 2x coins, selaras dengan magnet/shield
- Powerup: memindahkan ikon 2x coins ke bawah ikon skill lain di HUD
- Powerup: menambahkan jarak minimum global antar powerup agar tidak spawn terlalu rapat
- Powerup: mencegah spawn magnet/shield/2x coins terlalu dekat atau menempel dengan deretan coins
- Powerup: memastikan heart hanya muncul saat health belum penuh dan tetap terpisah dari powerup lain
- Ground runner: menambahkan jarak aman horizontal antar powerup berbasis tile di generator segmen
- Fix: menghilangkan peringatan integer division di infinite_ground.gd dengan pembagian float
- Fix: memastikan scene DoubleCoinsPowerup terhubung ke game_manager untuk mengaktifkan mode 2x coins
- Naik versi proyek ke 1.3.14-beta

## [1.3.13-beta] - 2025-12-29

- Powerup: cegah spawn shield dan magnet saat efek masih aktif
- Powerup: jangan spawn heart jika health pemain sudah penuh
- Powerup: bersihkan semua magnet dan shield aktif saat powerup berjalan
- Fix: perbaiki error strict typing dan shadowed variable di game_manager.gd
- Naik versi proyek ke 1.3.13-beta

## [1.3.12-beta] - 2025-12-28

- Shop: mengganti layout menu Shop menjadi list horizontal penuh layar dengan grup produk per kategori
- Shop: menambahkan contoh grup produk Power-ups, Upgrades, Cosmetics, Gem Packs, dan Bundles dengan harga coins dan real money (placeholder)
- Shop: membuat kartu item dengan panel border sehingga setiap produk lebih jelas terpisah dari background
- Shop: mengatur area scroll Shop agar bisa di-drag kiri–kanan (swipe-style) tanpa bergantung pada klik scrollbar
- Shop: menghapus loading screen saat masuk dan keluar dari menu Shop sehingga transisi ke/dari Main Menu lebih cepat
- Naik versi proyek ke 1.3.12-beta

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
- Ground title: tetap flat tanpa jurang melalui konfigurasi generator ground
- Naik versi proyek ke 1.3.1-beta

## [1.3.0-beta] - 2025-12-16

- Dokumentasi flow teknis runtime dan rekomendasi fitur/flow di `GAME_CONCEPT_AND_PLAYER_IMPLEMENTATION.md`
- Penjelasan step-by-step MainMenu → Main → gameplay → game over
- Rekomendasi profil kesulitan, Super Easy mode, power-up magnet, dan biome
- Perbaikan bug: ground awal kini mengikuti konfigurasi flat start pada generator ground
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
