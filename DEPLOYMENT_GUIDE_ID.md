# Panduan Deployment Anomaly Rush! (v1.3.37-beta)

Dokumen ini berisi langkah-langkah persiapan dan deployment untuk fase QA dan Beta Test.

## 1. Persiapan Managerial (Minta ke Manager)

### Akses & Kredensial
- [ ] **Akses Google Play Console:** Undangan sebagai `Admin` atau `Release Manager`.
- [ ] **ID Iklan AdMob Produksi:**
  - App ID
  - Banner Unit ID
  - Interstitial Unit ID
  - Rewarded Unit ID
  - *Catatan: ID di `project.godot` saat ini masih ID Test.*

### Aset Toko (Store Listing)
- [ ] **Privacy Policy URL:** Link kebijakan privasi yang aktif.
- [ ] **Grafis:**
  - Icon (512x512 PNG)
  - Feature Graphic (1024x500 PNG)
  - Screenshot HP (Min 2, 16:9)
- [ ] **Tester List:** Daftar email Gmail tim QA/Tester.

### Infrastruktur
- [ ] **Remote Content URL:** Hosting untuk aset tambahan (jika ada).

## 2. Persiapan Teknis (Godot)

### Keystore (Kunci Rilis)
- [ ] Buat `release.keystore` jika belum ada.
- [ ] Konfigurasi di **Export > Android > Options > Keystore**.

### Konfigurasi Project
- [ ] **Versi:** Cek `version/code` dan `version/name` di Export Presets.
- [ ] **AdMob:** Ganti ID Test dengan ID Produksi di `project.godot` sebelum build final.
- [ ] **Debug Mode:** Matikan "Export With Debug" untuk rilis toko.

## 3. Alur Deployment

### Fase 1: Internal Testing (QA)
1. Build **AAB** (Android App Bundle).
2. Upload ke **Play Console > Testing > Internal testing**.
3. Tambahkan email tester.
4. Tester download via link undangan.

### Fase 2: Open Beta
1. Promosikan dari Internal ke **Open Testing**.
2. Tunggu review Google (1-3 hari).
3. Link publik tersedia untuk user umum.

### Fase 3: Production
1. Promosikan ke **Production**.
2. Rilis resmi.
