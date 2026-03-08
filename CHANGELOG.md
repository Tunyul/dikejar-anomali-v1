# Changelog

All notable changes to this project are documented in this file.
The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## [Unreleased]

- Belum ada perubahan.

## [1.3.56-beta] - 2026-03-08

- Tutorial First Run: alur onboarding gameplay dipindah ke scene khusus `MainTutorial` dengan routing first-run yang lebih stabil.
- Tutorial Controls: tombol mobile jump/attack kini tampil kontekstual per step, disembunyikan saat countdown, dan sinkron dengan prompt aktif.
- Tutorial Prompt UX: overlay hint jump/attack diperkuat (spotlight + finger pulse) dan transisi prompt dibersihkan agar tidak dobel/nyangkut.
- Tutorial Ground Pattern: generator tutorial diubah ke scripted deterministic dengan urutan tetap (flat, gap jump, flat, rise, enemy, turun, flat, gap game over).
- Tutorial Enemy Timing: enemy tutorial dikunci jadi satu spawn di ujung platform naik (dekat titik turun) agar pacing step attack konsisten.
- Tutorial Jump Step 2: ditambahkan prompt jump kedua sebelum tiles naik dengan trigger jarak 1 tile dari player.
- Tutorial Attack Step: prompt attack kini trigger saat enemy berada dalam jarak 2 tile dan dunia dipause sementara sampai attack dilakukan.
- Tutorial Stability: perbaikan freeze/unfreeze world + animasi player pada step tutorial agar sinkron dan bebas race condition.
- Spawn Safety: hardening spawn enemy scripted agar tetap muncul pada step tutorial meski flag spawn acak dinonaktifkan.
- Version Sync: sinkronisasi `project.godot`, `export_presets.cfg`, dan `VERSION` ke `1.3.56-beta`.
- Naik versi proyek ke `1.3.56-beta`.

## [1.3.55-beta] - 2026-03-07

- Missions Claim Fix: memperbaiki claim misi yang macet setelah reset periodik dengan `grant_id` periodik untuk tipe `daily/week/month` di `MissionsManager`, sehingga tidak bentrok dengan `reward_grant_ledger` lama.
- Rewards Integrity: menambahkan helper token periode reset agar grant misi mengikuti siklus reset dan tetap anti-duplikasi di periode yang sama.
- UI Missions: panel misi kembali bisa claim untuk misi selesai pada siklus baru tanpa perubahan layout/tombol.
- Main Menu Responsive: menambahkan layout responsif berbasis viewport + safe-area untuk HUD kiri/kanan, tombol utilitas kanan atas, panel reward, dan panel profil agar tetap proporsional di landscape sempit sampai lebar.
- Season Rewards Responsive: panel season kini diskalakan responsif terhadap safe-area, dengan animasi open/close mengikuti skala target agar konsisten di berbagai resolusi.
- Shop Responsive: perapian layout shop untuk landscape sempit (safe-area inset, ukuran/spacing elemen header adaptif, card dan icon item lebih proporsional, serta pembersihan lebar minimum scroll runtime).
- Skill Progress Responsive: panel skill progress kini memakai safe layout rect, margin horizontal adaptif, dan tuning ukuran card/scroll agar tidak clipping pada resolusi kecil.
- Daily Missions Responsive: tuning komponen panel misi (tab/header/list/row claim) agar font, spacing, dan ukuran kontrol adaptif serta tetap terbaca di resolusi landscape kecil.
- Season Rewards Open Sync Fix: perbaikan race saat open panel season pertama kali yang kadang kembali ke level 1; kini sinkronisasi scroll awal ke level player dilakukan robust (immediate + deferred) dengan fallback progres dari `save.cfg`.
- Android Horizontal Safe-Area Fix: perbaikan layout Main Menu, Shop Menu, dan Skill Progress agar inset kiri-kanan dari safe-area Android tidak mendorong UI dan menyisakan area kosong di sisi kiri.
- Profile Avatar Size Polish: pembesaran avatar/border pada HUD profil Main Menu dan panel profil agar lebih terbaca di layar mobile tanpa mengubah struktur layout stabil yang sudah ada.
- Shop Coin Exchange (Gems): menambahkan grup pertukaran gems ke coins di Shop lengkap dengan alur exchange khusus, sinkronisasi saldo otoritatif, tombol `Exchange`, serta indikator hasil `+X Coins` pada kartu.
- Shop Economy Rebalance: tuning ulang paket Coin Exchange ke rasio balance (`5->180`, `10->360`, `25->950`, `50->2.000`, `100->4.200`) agar tidak overpowered dan tetap memberi bonus bertahap untuk paket lebih besar.
- QA Matrix Landscape: validasi headless lintas scene UI utama pada 1024x576, 1280x720, 1560x720, dan 1920x1080; hasil lulus tanpa error.
- QA: validasi ulang `sanity_check.gd` dan `smoke_check_runner.gd` dalam mode headless, hasil lulus.
- Version Sync: sinkronisasi `project.godot`, `export_presets.cfg`, `VERSION`, dan badge `README` ke `1.3.55-beta`.
- Naik versi proyek ke `1.3.55-beta`.

## [1.3.54-beta] - 2026-03-07

- Pooling Safety: hardening pool collectible di `InfiniteGround` dan `GameManager` agar node yang sudah `queue_free()`/invalid tidak bisa masuk atau dipakai lagi dari pool, menutup crash Android `Trying to assign invalid previously freed instance` pada heart/power-up.
- Season Rewards Performance: optimasi render daftar hadiah dengan pooling card dan refresh visible-range yang didefer per frame, sehingga scroll horizontal tidak lagi membuang dan membuat ulang item terus-menerus saat drag.
- Season Rewards UX: menu sekarang langsung fokus ke level player aktif saat dibuka, bukan selalu mulai dari reward level 1.
- Season Rewards Feedback: tambah loading overlay ringan dengan spinner coin saat menu dibuka dan saat daftar hadiah sedang di-refresh ketika drag/scroll.
- Android Export Metadata: sinkronisasi `project.godot`, `export_presets.cfg`, dan badge `README` ke versi `1.3.54-beta`.
- Naik versi proyek ke `1.3.54-beta`.

## [1.3.53-beta] - 2026-03-06

- Stability Guard: Aktifkan warning kritis GDScript sebagai error (`shadowed_variable`, `shadowed_variable_base_class`) di `project.godot` untuk mencegah warning lolos ke build QA.
- Loading/Preloader: Perbaikan kompatibilitas runtime Godot 4 pada warmup asset (`AnimatedSprite2D` tanpa `advance()`), serta perbaikan warning variabel shadowed pada layout `LoadingScreen`.
- Shop UX: Popup konfirmasi pembelian dibuat lebih ringkas dan ramah anak (nama item + harga), termasuk normalisasi nama upgrade agar tidak redundan.
- Shop Economy Integrity: Perbaikan sinkronisasi saldo coin/gems di `ShopMenu` agar pembelian selalu memakai nilai otoritatif `GameManager` (snapshot + signal `currencies_changed`), mencegah kasus coin tidak berkurang setelah buy.
- Shop Upgrade Pricing: Perbaikan bug harga upgrade yang melonjak di popup konfirmasi karena kalkulasi runtime berulang; harga card, popup, dan eksekusi beli kini konsisten.
- Skill Progress Panel: Perbaikan layout responsif dan tinggi panel agar konten pas (tanpa area kosong berlebih), plus dukungan preview editor untuk validasi visual scene.
- Skill Tokens UI: Perapian proporsi card agar konsisten, pembesaran ikon/teks agar lebih terbaca, dan penyusunan ulang layout token supaya lebih mirip pola card skill di bagian atas.
- Skill Tokens Readability: Penghapusan label yang terlalu panjang (`Token ...`) menjadi nama ringkas (`Magnet`, `Shield`, `Double Coins`, `Speed Boost`) serta penghilangan pemotongan teks `...` pada card token.
- Coin Integrity: Perbaikan state reset object pool pada `coin.gd` (reset `always_magnet`, `magnet_speed`, segment/currency defaults) agar coin normal tidak ikut "ketarik magnet" dari state lama.
- Coin Pickup Safety: Koleksi coin sekarang hanya valid untuk body player, mencegah trigger pickup oleh node non-player.
- Pooling Safety: Return `CollisionObject2D` ke pool kini otomatis deferred saat physics callback untuk menghindari error `Removing a CollisionObject node during a physics callback`.
- Heart Pickup Fix: `CollectibleHeart.tscn` kini memiliki collision shape aktif, serta hardening script heart agar monitoring/layer-masks konsisten setelah reset dan pickup hanya oleh player.
- Heart Spawn Guard: Perbaikan logika clear heart di `GameManager` (cek `HeartsA/HeartsB/CoinsA/CoinsB`) dan auto-clear heart tersisa saat HP kembali penuh agar tidak ada heart spawn berlebih ketika player sudah full heal.
- QA Automation: `smoke_check_runner.gd` diperluas untuk cek pipeline preloader (boot/deferred/warmup), format teks konfirmasi shop, reset-state coin pool, dan integritas pickup heart.
- QA Process: Tambah langkah Automated Preflight pada `QA_CORE_REGRESSION_CHECKLIST_V1` (`sanity_check` + `smoke_check_runner`) sebelum test manual.
- Naik versi proyek ke `1.3.53-beta`.

## [1.3.52-beta] - 2026-03-05

- Core Stabilization: hardening state transisi run (`entry -> countdown -> playing -> game over`), pause/resume lifecycle, dan flow continue agar tidak mudah race-condition.
- Reward Integrity: integrasi `reward_grant_ledger`, penyelarasan save schema v3, serta guard anti-duplicate untuk grant misi/claim harian/season/IAP.
- Monetization Service: tambah autoload `MonetizationService` sebagai kontrak unified untuk `buy()`, rewarded flow, status callback, dan telemetry dasar monetisasi.
- Billing Flow: refactor `BillingManager` untuk status `success/pending/cancelled/failed/restored`, context purchase, serta katalog produk sinkron dengan source-of-truth shop.
- Shop IAP Integration: `ShopMenu` kini memproses pembelian real-money melalui callback billing resmi + mapping grant terpusat, bukan grant lokal langsung.
- Difficulty & Gameplay: tambah baseline `DifficultyProfile`, daily challenge rotation, ramp difficulty runtime, serta event anomali ringan (distorsi jalur dan shift gravitasi/kecepatan).
- Missions Robustness: normalisasi template nama misi lintas bahasa, infer kind yang lebih aman (ID/EN/CN), dan formatting teks misi konsisten saat render/toast.
- UX Polish: animasi buka/tutup `SettingsMenu` diselaraskan (fade + scale) agar konsisten dengan panel overlay utama.
- Localization: pembaruan besar `translations.csv` + resource `.translation`, perbaikan label bahasa (`Chinese`) dan fix kasus teks CN yang tertinggal setelah kembali ke bahasa Indonesia.
- QA Artifacts: tambah dokumen `BASELINE_TUNING_V1`, `BUG_PRIORITY_MATRIX_V1`, dan `QA_CORE_REGRESSION_CHECKLIST_V1` untuk baseline harian tim QA.

## [1.3.51-beta] - 2026-03-04

- Skill Progress Panel: perombakan rendering card dan layout horizontal agar stabil saat buka-tutup panel, posisi awal konsisten, serta drag-scroll horizontal kembali responsif.
- Skill Progress Panel: perbaikan visual teks (judul ganda/artefak subtitle), trimming label nilai, dan sinkronisasi font/theme agar tetap rapi di resolusi mobile.
- Shop Menu: sinkronisasi perilaku scroll saat panel progress aktif, serta perapian alur input agar drag panel tidak bentrok dengan drag daftar item shop.
- Shop Economy: harga upgrade permanen kini dihitung dinamis per level (growth coins/gems) dan status `MAX` ditangani konsisten di tampilan serta eksekusi pembelian.
- GameManager API: penambahan domain API/signal untuk `shop`, `cosmetics`, dan `settings` (`get_*_snapshot`, `update_*`, dan signal perubahan) sebagai sumber kebenaran tunggal data UI.
- MainMenu/Settings/Shop: migrasi baca-tulis save ke API `GameManager` untuk domain terkait, mengurangi penulisan langsung `ConfigFile` dari UI layer.
- Runtime Stability: menonaktifkan mode `@tool` pada `ShopMenu.gd` untuk mencegah konflik eksekusi editor terhadap UI runtime saat debugging.

## [1.3.50-beta] - 2026-03-04

- Core Save/Data: Konsolidasi domain data gameplay dengan `GameManager` sebagai owner `progress/powerups/rewards` dan `MissionsManager` sebagai owner `missions`, termasuk migrasi schema save v2 yang kompatibel dengan data lama.
- Missions/Rewards: Standarisasi alur claim (mission claim, daily-all claim, season claim, claim-all season) ke API manager dengan kontrak return deterministik.
- Skill System: Penyeragaman dispatcher aktivasi skill lintas pickup/shop/pre-run, termasuk sinkronisasi tracking used-skill dan konsumsi token yang konsisten.
- Shop/UI: Penambahan panel `Skill Progress` di Shop untuk menampilkan level, nilai saat ini, nilai berikutnya, dan stok token skill secara realtime.
- UI/UX: Refine besar pada panel `Skill Progress` (layout responsif, drag-scroll horizontal, tipografi konsisten, trimming teks, dan sinkronisasi tema).
- Fix: Perbaikan bug tampilan harga di Shop yang membuat angka kebutuhan koin/diamond terlihat hilang karena label collapse.
- Localization: Sinkronisasi resource terjemahan (`translations.csv` dan file `.translation`) untuk label skill progress dan UI shop/missions terbaru.
- QA/Smoke: Pembaruan sanity/smoke checks untuk mencakup scene dan flow baru agar integrasi MainMenu/Shop/SeasonRewards tetap aman.

## [1.3.49-beta] - 2026-03-02

- Gameplay: Menstabilkan alur in-game (entry, countdown, dan transisi) agar tidak langsung lompat ke fase bermain.
- Core: Migrasi routing event gameplay ke autoload `GameManager` (coin, diamond, skill/powerup, shield check, pause state, enemy drop/kill callback).
- Fix: Memperbaiki tombol lanjut via iklan di Game Over agar memanggil `GameManager.try_rewarded_continue()` dan menampilkan feedback saat ad belum siap.
- Fix: Memperbaiki type mismatch `Array` ke `Array[Dictionary]` pada sistem pending level rewards saat kalkulasi XP/game over.
- UI/Profile: Menambahkan fallback loading avatar border saat file border legacy tidak ditemukan.
- UI In-game: Menyesuaikan keterbacaan HUD (font/icon) dan menyetel ulang ukuran/posisi tombol mobile agar lebih proporsional.

## [1.3.48-beta] - 2026-02-27

- **Season Rewards**:
  - Lazy Loading System: Implementasi pemuatan cerdas untuk mendukung hingga 1000 level hadiah tanpa lag.
  - UI/UX Refinement: Pengecilan skala card (0.8x), penyesuaian `_item_width` (170px), dan penambahan tinggi container (310px) agar tidak terpotong.
  - Drag Scrolling: Navigasi daftar hadiah yang halus untuk mouse dan sentuhan.
  - Fix: Perbaikan error duplikasi koneksi sinyal pada `SeasonRewardItem.gd`.
- **Audio & BGM**:
  - Centralization: Migrasi seluruh kontrol BGM ke `TransitionManager.gd` dan pembersihan kode redundan di `GameManager`.
  - Audio Ducking: Fitur pengecilan volume otomatis saat transisi atau munculnya SFX penting.
  - Early BGM Fix: Menghapus pemutaran BGM prematur di `LoadingScreen.gd` agar musik hanya mulai setelah loading selesai.
- **Localization (i18n)**:
  - CSV Migration: Konversi sistem terjemahan dari `.tres` ke format standar `translations.csv` untuk stabilitas tinggi.
  - Fix Error: Perbaikan error "No Loader" pada resource terjemahan di `project.godot`.
- **Optimization**:
  - Code Cleanup: Penghapusan variabel tak terpakai (`_bgm_base_db`, `_bgm_fade_tween`, `ui_font`) di `game_manager.gd`.
  - HUD Sync: Sinkronisasi otomatis saldo koin/permata setelah melakukan claim hadiah season.
- Naik versi proyek ke 1.3.48-beta.

## [1.3.47-beta] - 2026-02-27

- Fix: Memperbaiki koin yang tembus ke tanah dengan standarisasi height offset (1.5 tiles) dan penambahan fungsi `reset()` pada script koin.
- Fix: Implementasi fungsi `reset()` pada `HeartPickup.gd` dan `CollectibleHeart.gd` untuk memastikan state yang bersih saat diambil dari object pool.
- Fix: Memperbaiki error "Identifier not declared" pada `infinite_ground.gd` dengan merestorasi variabel @export yang hilang.
- Gameplay: Menyeimbangkan tinggi spawn untuk koin, diamond, heart, dan powerup agar tidak terlalu tinggi dan lebih mudah dijangkau.
- UI/UX: Memperbaiki teks misi yang terpotong/hilang dengan mengaktifkan autowrap dan penyesuaian size flags pada `DailyMissionsMenu.gd`.
- UI/UX: Standardisasi tinggi baris misi (64px) dan vertical alignment (Center) untuk tampilan yang lebih rapi dan konsisten.
- UI/UX: Memperbesar tombol Claim (72x48px) dan meningkatkan responsivitas layout panel misi di berbagai ukuran layar.
- Naik versi proyek ke 1.3.47-beta.

## [1.3.46-beta] - 2026-02-26

- UI/UX: Implementasi fitur sembunyi scrollbar pada Shop Menu dan Settings Menu untuk tampilan yang lebih bersih.
- UI/UX: Perbaikan sistem scroll pada Settings Menu agar dapat di-drag langsung pada item (Label, Slider, Button).
- UI/UX: Optimasi input handling pada Settings Menu untuk mencegah konflik antara scrolling dan interaksi slider.
- UI/UX: Penambahan logic otomatis untuk mengatur `mouse_filter` pada elemen UI di dalam scroll container.

## [1.3.45-beta] - 2026-02-26

- Localization: Implementasi sistem lokalisasi real-time pada Profile Panel (Judul, Tombol Ganti Avatar/Border, Tutup).
- Localization: Penambahan key terjemahan baru untuk elemen profil di `id.tres`, `en.tres`, dan `zh.tres`.
- Fix: Perbaikan bug bahasa yang tidak berubah pada Profile Panel tanpa menutup panel terlebih dahulu.
- Fix: Pembersihan total kesalahan indentasi (Tab vs Space) pada `MainMenu.gd` untuk standarisasi 4 spasi.
- UI/UX: Sinkronisasi visual Profile Panel agar konsisten dengan tema game di seluruh bahasa.

## [1.3.44-beta] - 2026-02-26

- UI/UX: Optimasi Profile Panel agar 100% aman dari gangguan AdMob Banner (jarak bebas >100px dari dasar layar).
- UI/UX: Sinkronisasi lebar Stats Card (Lv, XP, Score) menjadi 280px agar sejajar sempurna dengan tombol di bawahnya.
- UI/UX: Perbaikan visual judul "PROFIL PEMAIN" menggunakan font standar game (Fredoka Bold) dengan outline tegas.
- UI/UX: Penyesuaian ukuran ikon statistik (32x32) dan font (22px) agar kartu profil lebih compact dan profesional.
- UI/UX: Perbaikan masalah panel terpotong di bagian atas pada layar landscape dengan penyesuaian offset_top (-270px).
- UI/UX: Rebalancing posisi elemen vertikal agar seluruh konten panel berada tepat di tengah (centered) dan lega.

## [1.3.43-beta] - 2026-02-25

- UI/UX: Refactor Profile Panel ke layout horizontal (HBox) untuk kompatibilitas layar landscape (1024x576).
- UI/UX: Implementasi icon-based stats (Level, XP, Trophy) pada Profile Panel untuk tampilan yang lebih modern dan bersih.
- UI/UX: Penambahan efek Glassmorphism pada panel profil dengan shadow dan border yang lebih halus.
- UI/UX: Penambahan animasi hover (scale & glow) pada semua tombol interaktif di Profile Panel.
- UI/UX: Perbaikan alignment judul "PROFIL PEMAIN" dan layouting tombol agar tidak tumpang tindih.
- Avatar Border: Standarisasi padding untuk semua Premium Border (Gold, Silver, Neon, Shadow) agar avatar tidak terpotong.
- Avatar Border: Penyesuaian khusus padding Fire Border (32px) untuk memastikan avatar berada tepat di dalam lubang api.
- Fix: Perbaikan path node `CloseProfileButton` pada script `MainMenu.gd` agar sesuai dengan struktur UI baru.

## [1.3.42-beta] - 2026-02-25

- Avatar Border: Perbaikan misalignment pada Fire Border agar presisi di tengah icon.
- Avatar Border: Implementasi sistem switching border yang sudah dibeli dari Shop ke Main Menu.
- Avatar Border: Penambahan node `InnerIcon` untuk pemisahan visual antara avatar dan border di Main Menu.
- Avatar Border: Perbaikan bug persistensi data border agar tetap tersimpan setelah game ditutup.
- Shop: Perbaikan duplikasi icon Gold pada menu pembelian border.
- Animation: Perbaikan bug `AnimatedSprite2D` pada animasi Attack yang sebelumnya menampilkan seluruh spritesheet sekaligus.
- Animation: Perbaikan bug `AnimatedSprite2D` pada animasi Jump yang tidak terpotong (slice) karena perbedaan ukuran aset.
- Animation: Implementasi sistem slicing otomatis yang lebih generik untuk semua animasi utama (Run, Jump, Attack).
- Fix: Pembersihan error indentasi (Tab vs Space) pada `game_manager.gd`.
- Fix: Pembersihan kode yang tidak terjangkau (_unreachable code_) pada fungsi mobile button tints.

## [1.3.41-beta] - 2026-02-25

- Android: Perbaikan bug game yang terdeteksi sebagai aplikasi launcher (Home Screen) dengan menghapus `CATEGORY_HOME` dari manifest.
- Android: Penyesuaian `app_category` ke `Game` (1) dan penonaktifan flag launcher otomatis di export presets.
- Fix: Pembersihan metadata launcher pada build debug dan release untuk mencegah konflik dengan sistem UI Android.
- MainMenu: Perbaikan bug tombol "Ganti Border" yang salah mengarahkan ke Shop saat pemain masih menggunakan border default.
- MainMenu: Sinkronisasi daftar pilihan border agar selalu menyertakan opsi "Tanpa Border" dan "Gold Border" (default).
- Shop: Perbaikan bug BGM yang hilang saat masuk ke ShopMenu dengan mengganti path audio ke aset yang tersedia (`backsound-mainmenu-2.mp3`).
- TransitionManager: Implementasi sistem manajemen BGM terpusat untuk transisi antar scene yang lebih mulus dan persisten.
- TransitionManager: Menambahkan fungsi `play_bgm`, `play_playlist`, dan `stop_bgm` yang mendukung pemuatan file audio secara dinamis dari path string.
- ShopMenu: Integrasi dengan `TransitionManager.fade_to_scene` untuk transisi kembali ke Main Menu dengan efek visual dan audio yang konsisten.

## [1.3.40-beta] - 2026-02-24

- Profile: Implementasi sistem profil pemain interaktif yang dapat diakses dengan men-tap foto profil di Main Menu.
- Profile: Menambahkan `ProfilePanel` UI untuk menampilkan Nama, Level, XP, dan Best Score pemain.
- Avatar: Implementasi sistem avatar dinamis yang terintegrasi dengan sistem Skin (Basic, Premium, Neon, Shadow).
- Avatar: Menggunakan aset gambar profil baru (Basic, Premium, Neon, Ninja) untuk ikon avatar dan shop.
- Avatar: Menambahkan dukungan border avatar (Gold Border) yang dapat dimuat secara dinamis.
- Shop: Ekstensi kategori `Avatar Borders` di menu Shop dengan variasi baru (Gold, Silver, Neon, Shadow) dan sistem `Equip`.
- Avatar: Memperbarui sistem pemilihan border di Main Menu agar sinkron dengan pilihan di Shop dan tampil di Profile Panel.
- Profile: Menambahkan fitur "Quick Change" (Cycle) untuk Avatar dan Border langsung dari Profile Panel bagi item yang sudah dimiliki.
- Fix: Memperbaiki error `load_current_player()` pada `PlayGamesManager.gd` dengan menambahkan argumen `force_reload` dan koreksi tipe data `PlayGamesPlayer`.
- Fix: Memperbaiki masalah indentasi pada `MainMenu.gd` yang menyebabkan error linter.

## [1.3.39-beta] - 2026-02-22

- UI: Menghilangkan indikator visual area sentuh (lingkaran biru/kuning) pada tombol mobile untuk tampilan yang lebih bersih.
- Fix: Memperbaiki masalah tombol Attack dan Jump yang tetap muncul saat Game Over.

## [1.3.38-beta] - 2026-02-24

- Core: Added `BillingManager.gd` for Google Play Billing integration.
- Core: Added `PlayGamesManager.gd` for Google Play Games Services login.
- Docs: Updated project timeline for solo development (`TIMELINE_SOLO_DEV_REALISTIC.csv`).
- Docs: Cleaned up deprecated timeline files.

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
