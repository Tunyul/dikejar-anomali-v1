# Main Menu – Status Fitur

Ringkasan status fitur main menu untuk Anomaly Rush.

Status per: 1.3.18-beta (2026-01-09)

## Fitur yang Sudah Dikerjakan

- Background parallax multi-layer (sky, clouds, hills, mountain) dengan gerakan otomatis.
- Ground/title mode berjalan di belakang untuk memberi kesan dunia hidup.
- Logo / title game tampil di bagian atas.
- Tombol utama:
  - PlayButton
    - Texture hijau khusus.
    - Posisi di tengah baris tombol.
    - Terhubung ke MainMenu.gd → Preloader → Main.tscn → LoadingScreen.
  - ShopButton
    - Texture biru dengan ikon keranjang.
    - Tampil di sebelah kiri Play.
    - Membuka scene Shop dengan layout horizontal scroll dan grup produk.
  - SettingsButton
    - Texture khusus dengan ikon gear.
    - Tampil di sebelah kanan Play.
    - Membuka overlay Settings dengan panel BGM/SFX dan tombol tutup.
- Informasi pemain:
  - StatsLabel menampilkan "Best: X | Coins: Y" dari user://save.cfg.
- Informasi build:
  - VersionLabel di kiri bawah, mengambil application/config/version dengan fallback default.

## Fitur yang Belum Dikerjakan (Perlu Implementasi Lanjut)

- Pengembangan lanjut Shop:
  - Integrasi penuh dengan currency, inventory, dan sistem save (power-up, upgrade, skin).
  - Alur pembelian yang aman (konfirmasi, error handling, limit harian) dan siap IAP.
- Pengembangan lanjut Settings:
  - Penyimpanan dan pemuatan pengaturan audio yang lebih lengkap (profil, kategori).
  - Opsi kontrol dasar dan kualitas efek visual bila diperlukan.
- Integrasi konsep Level/Biome ke Main Menu:
  - Menampilkan dunia/biome terkunci dan yang sudah terbuka.
  - Indikator biome aktif berdasarkan progres jarak.
- Integrasi sistem misi/quest:
  - Panel kecil dengan 1–3 misi aktif dan progress bar.

## Rekomendasi Pengembangan Berikutnya

- Selesaikan flow Shop dan Settings sehingga semua tombol utama benar-benar fungsional.
- Tambah panel ringkasan run terakhir (jarak, coins, sebab game over).
- Tambah daily reward sederhana yang bisa diklaim dari main menu.
- Tambah tips rotasi singkat di bagian bawah agar pemain baru cepat paham kontrol.
