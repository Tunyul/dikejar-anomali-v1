# Main Menu – Status Fitur

Ringkasan status fitur main menu untuk Anomaly Rush.

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
  - SettingsButton
    - Texture khusus dengan ikon gear.
    - Tampil di sebelah kanan Play.
- Informasi pemain:
  - StatsLabel menampilkan "Best: X | Coins: Y" dari user://save.cfg.
- Informasi build:
  - VersionLabel di kiri bawah, mengambil application/config/version dengan fallback default.

## Fitur yang Belum Dikerjakan (Perlu Implementasi Lanjut)

- Fungsi penuh tombol Shop:
  - Scene/menu Shop untuk belanja skin, item, atau power-up.
  - Integrasi dengan currency coin dan sistem save.
- Fungsi penuh tombol Settings:
  - Menu pengaturan BGM/SFX (slider dan mute).
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

