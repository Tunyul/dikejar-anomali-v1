# Anomaly Rush – Deskripsi Game

## Pitch Singkat

Anomaly Rush adalah game **endless runner 2D** di mana pemain terus berlari ke depan sambil dikejar "anomali" misterius dari belakang layar. Tugas pemain sederhana: **jangan tertangkap**, lompat rintangan, dan kumpulkan koin sebanyak mungkin.

Game ini dirancang ringan, cepat dimengerti, dan nyaman dimainkan di perangkat mobile, tetapi tetap punya progres jangka panjang lewat misi, koin, dan rencana pengembangan level/biome.

## Core Gameplay

- Karakter berlari otomatis ke kanan.
- Pemain hanya fokus ke dua aksi utama:
  - **Lompat** untuk menghindari jurang, jebakan, dan obstacle.
  - **Mengambil koin dan power-up** yang muncul di jalur lari.
- Jika pemain terkena jebakan atau tertangkap anomali → **game over**, run berakhir dan statistik run disimpan.

Rasa kontrol dibuat simpel, dengan input satu/two button agar nyaman untuk keyboard, mouse, dan layar sentuh.

## Progres dan Sistem Misi

- Setiap run akan memperbarui:
  - **Best score / best distance** (jarak terbaik yang pernah dicapai).
  - **Total coins** yang pernah dikumpulkan sepanjang akun.
- Sistem misi (missions) menggunakan data:
  - Jarak tempuh (distance).
  - Jumlah koin yang dikumpulkan.
- Contoh misi:
  - Capai jarak 500m.
  - Kumpulkan 20/50 koin.

Misi yang selesai akan tersimpan dan dapat dikaitkan ke **reward** (skin, boost, dll) serta **daily/weekly/event missions** melalui tombol mission di main menu.

## Main Menu dan Struktur UI

- **Latar belakang hidup**:
  - Parallax background multi-layer (langit, awan, pegunungan, ground berjalan).
  - Memberi kesan dunia yang sudah hidup bahkan sebelum game dimulai.
- **Tombol utama** di tengah:
  - **Play** – mulai run baru (menu → loading → scene gameplay utama).
  - **Shop** – akses ke toko (skin, item, power-up) terhubung dengan currency koin.
  - **Settings** – pengaturan audio:
    - Slider volume BGM dan SFX.
    - Tombol mute.
- **Tombol mission kecil** (ikon) di kiri atas:
  - Membuka halaman **Daily / Weekly / Event Missions**.
  - Ikon dapat berubah menjadi versi **ceklis** jika ada misi yang sudah selesai (indikator visual kepada pemain).
- **Informasi pemain**:
  - Label yang menampilkan `Best: X | Coins: Y` mengambil data dari `user://save.cfg`.
- **Informasi build**:
  - Label versi di kiri bawah, membaca `application/config/version` dari `ProjectSettings` dengan fallback default.

## Flow Teknis Singkat

1. **Startup**
   - Engine membuka `MainMenu.tscn` sebagai scene awal.
   - `MainMenu.gd` membaca save file dan mengisi UI (best score, total coins, status mission icon).
   - Ground dan parallax di-set ke mode title (bergerak otomatis untuk latar hidup).

2. **Dari Main Menu ke Gameplay**
   - Menekan tombol **Play**:
     - Menyembunyikan UI main menu.
     - Mengatur `Preloader` ke `Main.tscn`.
     - Menjalankan transisi ke `LoadingScreen.tscn`, lalu ke scene gameplay utama.

3. **Run dan Game Over**
   - `game_manager.gd` mengatur kecepatan lingkungan, skor, jarak, coin, dan interaksi dengan player.
   - Saat game over:
     - Menghitung `last_score`, `last_coins`, dan menambah `total_coins`.
     - Memperbarui misi (distance & coins) melalui `MissionsManager.gd`.
     - Menyimpan progres ke `user://save.cfg`.
   - Pemain bisa memilih retry atau kembali ke Main Menu.

## Target Pengguna dan Rasa Game

- **Target**:
  - Pemain yang suka game cepat dan simple (mobile-friendly).
  - Cocok untuk sesi bermain pendek, tetapi tetap punya progres jangka panjang.
- **Rasa yang diinginkan**:
  - Kontrol mudah, responsif, dan tidak bikin frustasi.
  - Visual jelas dan kontras, dengan UI yang bersih.
  - Perasaan terus dikejar dan berpacu dengan jarak serta misi.

## Arah Pengembangan Lanjut (Ringkas)

Status per: 1.3.19-beta (2026-01-09)

- Loop utama, sistem skor/jarak/coin, health, heart, dan beberapa power-up (magnet, double coins, shield, speed boost) sudah aktif.
- Missions dasar sudah terhubung lewat `MissionsManager.gd`, dengan UI misi tabbed (daily/weekly/challenge) dan reward coins yang bisa di-claim dari Main Menu.
- Shop dan Settings sudah memiliki scene dan UI dasar; integrasi inventory, upgrade, dan IAP belum penuh.
- Level/biome masih satu tema utama (Hills) dan belum memakai sistem Level Dunia.

Fokus pengembangan berikut:

- Lengkapi konten **Shop** (skin, efek trail, power-up) dan hubungkan ke save.
- Kuatkan sistem **missions** (daily, weekly, event) dengan reward nyata dan UI claim yang jelas.
- Implementasi penuh konsep **Level/Biome** (Hills, City, Lab) berdasarkan jarak.
- Poles animasi, efek suara, dan performa untuk rilis mobile.
