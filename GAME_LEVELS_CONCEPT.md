# Konsep Level untuk Anomaly Rush

Game ini dasarnya endless runner: satu run bisa lanjut terus sampai player gagal.
"Level" dipakai sebagai lapisan progres di atas run tersebut.

## 1. Level sebagai Dunia / Biome

- Level = perubahan dunia saat jarak tertentu tercapai.
- Contoh urutan:
  - Level 1 – Hills: background hijau, obstacle dasar, speed pelan.
  - Level 2 – City: kota malam, obstacle lebih padat, speed naik.
  - Level 3 – Lab Anomali: tema eksperimen, hazard berat, power-up lebih sering.
- Pemicu level naik: jarak tempuh (mis. 0–1500, 1500–3500, 3500+).
- Yang berubah per level:
  - Parallax background dan warna langit.
  - Set ground/obstacle yang boleh muncul.
  - Parameter speed dasar dan batas atas.

## 2. Level sebagai Progres Akun (Meta Level)

- Player punya Level Akun terpisah dari run.
- Naik level karena akumulasi jarak, coin, dan misi.
- Setiap kenaikan level bisa membuka:
  - Power-up baru.
  - Skin/visual baru di Shop.
  - Mode atau difficulty baru.

## 3. Level sebagai Chapter / Misi

- Level di-present sebagai chapter dengan objective jelas.
- Contoh:
  - Chapter 1: capai jarak 800 dan ambil 50 coin.
  - Chapter 2: capai biome kedua sekali saja.
- Run masih endless, tetapi keberhasilan chapter ditentukan oleh objective.

## Arah yang Dipilih

- Menggabungkan konsep 1 dan sedikit 3:
  - Biome/dunia berubah otomatis berdasarkan jarak (Level Dunia).
  - Di atasnya ada misi atau chapter yang memakai jarak/biome sebagai target.
- Level Akun (konsep 2) bisa ditambahkan kemudian bila progres jangka panjang dirasa kurang.

## Todos Implementasi Level

- Definisikan data Level Dunia:
  - Nama, jarak mulai/akhir, tema background, set obstacle, speed.
- Update generator ground dan parallax agar membaca Level Dunia aktif.
- Tambah indikator UI level saat ini (HUD dan/atau Main Menu).
- Rancang minimal 3 Level Dunia pertama (Hills, City, Lab Anomali).
- Desain 3–5 chapter yang memakai target jarak, coin, dan biome.
- Simpan progres level/chapter di save file.

