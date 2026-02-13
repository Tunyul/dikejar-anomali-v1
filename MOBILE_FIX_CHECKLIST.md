# Android Build & UI Fix Checklist

## UI & Layout

- [ ] **UI Anchoring**: Perbaiki sistem anchor pada Shop dan HUD agar tidak bergeser saat layar melebar (Android Expand mode).
- [ ] **Mobile Controls Positioning**: Pindahkan posisi tombol Jump dan Attack dari posisi absolut ke sistem Anchor (Pojok Kanan Bawah).
- [ ] **Panel Scaling**: Sesuaikan ukuran panel Shop agar tidak terlalu besar di rasio layar 20:9.

## Resource Loading (Android)

- [ ] **FileAccess Fix**: Hapus pengecekan `FileAccess.file_exists()` untuk resource internal di `ShopMenu.gd` (karena gagal di APK/PCK).
- [ ] **Path Case-Sensitivity**: Verifikasi semua path aset agar menggunakan huruf besar/kecil yang konsisten (Case-Sensitive).

## Rendering & Gameplay

- [ ] **Parallax Gaps**: Perbaiki `motion_mirroring` pada background agar menutupi seluruh lebar viewport Android.
- [ ] **Ground Alignment**: Perbaiki kalkulasi lebar segmen ground agar tidak terputus di layar lebar.

## Input & Controls

- [ ] **Button Visibility**: Pastikan `TouchScreenButton` muncul dan tidak terhalang oleh node UI lain (`mouse_filter`).
- [ ] **Input Mapping**: Verifikasi `Action` pada tombol mobile sudah terhubung ke `InputMap` (jump, attack).
