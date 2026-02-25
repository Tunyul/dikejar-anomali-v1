# Android Build & UI Fix Checklist

## UI & Layout

- [ ] **UI Anchoring**: Perbaiki sistem anchor pada Shop dan HUD agar tidak bergeser saat layar melebar (Android Expand mode).
- [ ] **Mobile Controls Positioning**: Pindahkan posisi tombol Jump dan Attack dari posisi absolut ke sistem Anchor (Pojok Kanan Bawah).
- [ ] **Panel Scaling**: Sesuaikan ukuran panel Shop agar tidak terlalu besar di rasio layar 20:9.

## Resource Loading & Assets (Android)

- [x] **FileAccess.file_exists() Failure**:
  - [x] `ShopMenu.gd`: Ganti `FileAccess.file_exists()` dengan `ResourceLoader.exists()` pada fungsi `_create_item_card()` agar ikon item shop muncul di Android. (Fixed)
  - [x] `ShopMenu.gd`: Hapus penggunaan `FileAccess.file_exists()` di `_load_currency_icons()`. Gunakan `ResourceLoader.exists()` atau langsung `load()`. (Fixed)
  - [x] `TransitionManager.gd`: Periksa `_get_sfx_stream()` yang mencoba memuat file `.mp3` dari path statis yang mungkin tidak ada (e.g., `res://assets/audio/sfx/coin.mp3`). (Fixed: sudah menggunakan ResourceLoader dan mapping file yang benar)
- [x] **Path Case-Sensitivity & Accuracy**:
  - [x] `TransitionManager.gd`: Path `res://assets/audio/sfx/` + key + `.mp3` asumsikan semua SFX ada di folder tersebut, padahal file asli memiliki nama panjang (e.g., `audio-SFX-only...`). (Fixed: mapping manual untuk nama file panjang sudah ada)
  - [x] `ShopMenu.gd`: Verifikasi path `res://assets/mc/run/idle_run.png` (Tidak ada spasi, sudah menggunakan underscore). (Fixed)
- [x] **Export Presets Configuration**:
  - [x] Tambahkan Launcher Icons (Main 192x192, dll) di `export_presets.cfg`. (Fixed: ditambahkan ukuran 48, 72, 96, 144, 192, dan adaptive)
  - [x] **Launcher App Flag & Category Fix**:
    - [x] Hapus `android.intent.category.HOME` dari `AndroidManifest.xml` (debug & release) yang menyebabkan game dianggap sebagai launcher sistem.
    - [x] Setel `package/app_category` ke `1` (Game) di `export_presets.cfg`.
    - [x] Nonaktifkan `package/show_as_launcher_app` di `export_presets.cfg` karena sudah ditangani secara manual di manifest custom.
- [x] Pastikan filter ekspor menyertakan semua ekstensi yang diperlukan (`*.png, *.jpg, *.jpeg, *.ogg, *.mp3, *.wav, *.tscn, *.tres`). (Fixed: spasi dihapus dan \*.pck ditambahkan)
- [ ] **Audio Format & SFX System**:
  - [x] `TransitionManager.gd` menggunakan generator WAV internal jika file tidak ditemukan. Pastikan sistem fallback ini bekerja atau ganti dengan referensi aset yang benar. (Fixed: sistem fallback generator sudah aktif)
  - [ ] Verifikasi apakah `AudioStreamPlayer` di mobile memerlukan setting khusus (e.g., Audio Driver).
- [x] **Texture Compression**:
  - [x] Pastikan `textures/vram_compression/import_etc2_astc` aktif di `project.godot` (Sudah OK).
- [x] **Dynamic Asset Loading (DirAccess)**:
  - [x] `MainMenu.gd`: Perbaiki `_load_menu_bgm_paths()` untuk menangani sufiks `.remap` dan `.import` di Android. (Fixed)
  - [x] `game_manager.gd`: Perbaiki `_load_bukit_bgm_paths()` dan `_load_gameover_bgm_paths()` untuk menangani sufiks `.remap` dan `.import`. (Fixed)

## Rendering & Gameplay

- [ ] **Parallax Gaps**: Perbaiki `motion_mirroring` pada background agar menutupi seluruh lebar viewport Android.
- [ ] **Ground Alignment**: Perbaiki kalkulasi lebar segmen ground agar tidak terputus di layar lebar.

## Input & Controls

- [x] **BUG: Tombol Jump & Attack Hilang di Android**
  - [x] Audit inisialisasi tombol di `game_manager.gd`.
  - [x] Tambahkan fallback layout jika tekstur gagal dimuat.
  - [x] Paksa visibilitas node `MobileControls` saat inisialisasi.
  - [x] Tambahkan validasi ukuran viewport untuk inisialisasi mobile yang lebih stabil.
  - [x] Tambahkan Z-Index tinggi (100) untuk memastikan tombol di atas UI lain.
  - [x] Tambahkan debug logging runtime untuk melacak inisialisasi node di Android.
  - _Status: Selesai. Logika layout diperkuat, visibilitas dipaksa, dan debug logging ditambahkan untuk verifikasi._
- [ ] **Input Mapping**: Verifikasi `Action` pada tombol mobile sudah terhubung ke `InputMap` (jump, attack).

## Kesimpulan Perbaikan Terakhir (v1.3.31-beta)

1. **BGM Fix**: Menangani akhiran `.remap` dan `.import` pada Android.
2. **Icon Fix**: Menambahkan berbagai resolusi icon dan mengaktifkan flag launcher.
3. **Shop Icon Fix**: Migrasi ke `ResourceLoader.exists()` untuk kompatibilitas Android.
4. **Mobile Controls Fix**: Memperbaiki logika layout dan visibilitas tombol Jump/Attack.
