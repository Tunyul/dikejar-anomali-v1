# Android Build & UI Fix Checklist

## UI & Layout

- [ ] **UI Anchoring**: Perbaiki sistem anchor pada Shop dan HUD agar tidak bergeser saat layar melebar (Android Expand mode).
- [ ] **Mobile Controls Positioning**: Pindahkan posisi tombol Jump dan Attack dari posisi absolut ke sistem Anchor (Pojok Kanan Bawah).
- [ ] **Panel Scaling**: Sesuaikan ukuran panel Shop agar tidak terlalu besar di rasio layar 20:9.

## Resource Loading & Assets (Android)

- [ ] **FileAccess.file_exists() Failure**:
  - [ ] `ShopMenu.gd`: Hapus penggunaan `FileAccess.file_exists()` di `_load_currency_icons()`. Gunakan `ResourceLoader.exists()` atau langsung `load()`.
  - [ ] `TransitionManager.gd`: Periksa `_get_sfx_stream()` yang mencoba memuat file `.mp3` dari path statis yang mungkin tidak ada (e.g., `res://assets/audio/sfx/coin.mp3`).
- [ ] **Path Case-Sensitivity & Accuracy**:
  - [ ] `TransitionManager.gd`: Path `res://assets/audio/sfx/` + key + `.mp3` asumsikan semua SFX ada di folder tersebut, padahal file asli memiliki nama panjang (e.g., `audio-SFX-only...`).
  - [ ] `ShopMenu.gd`: Verifikasi path `res://assets/mc/run/idle run.png` (spasi pada nama file bisa bermasalah di beberapa filesystem).
- [ ] **Export Presets Configuration**:
  - [ ] Tambahkan Launcher Icons (Main 192x192, dll) di `export_presets.cfg`.
  - [ ] Pastikan filter ekspor menyertakan semua ekstensi yang diperlukan (`*.png, *.jpg, *.jpeg, *.ogg, *.mp3, *.wav, *.tscn, *.tres`).
- [ ] **Audio Format & SFX System**:
  - [ ] `TransitionManager.gd` menggunakan generator WAV internal jika file tidak ditemukan. Pastikan sistem fallback ini bekerja atau ganti dengan referensi aset yang benar.
  - [ ] Verifikasi apakah `AudioStreamPlayer` di mobile memerlukan setting khusus (e.g., Audio Driver).
- [ ] **Texture Compression**:
  - [ ] Pastikan `textures/vram_compression/import_etc2_astc` aktif di `project.godot` (Sudah OK).

## Rendering & Gameplay

- [ ] **Parallax Gaps**: Perbaiki `motion_mirroring` pada background agar menutupi seluruh lebar viewport Android.
- [ ] **Ground Alignment**: Perbaiki kalkulasi lebar segmen ground agar tidak terputus di layar lebar.

## Input & Controls

- [ ] **Button Visibility**: Pastikan `TouchScreenButton` muncul dan tidak terhalang oleh node UI lain (`mouse_filter`).
- [ ] **Input Mapping**: Verifikasi `Action` pada tombol mobile sudah terhubung ke `InputMap` (jump, attack).
