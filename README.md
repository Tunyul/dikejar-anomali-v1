# 🏃‍♂️ Anomaly Rush!

![Banner](https://img.shields.io/badge/Status-In--Development-yellow?style=for-the-badge)
![Godot Engine](https://img.shields.io/badge/Godot-4.6-%23478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)
![Version](https://img.shields.io/badge/Version-1.3.28--beta-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Anomaly Rush!** adalah game *Endless Runner 2D* yang dikembangkan menggunakan Godot Engine 4.6. Pemain harus bertahan hidup dari kejaran "Anomaly" sambil melewati rintangan dan mengumpulkan sumber daya di dunia yang terus berubah.

---

## 📌 Daftar Isi
- [Gameplay](#-gameplay)
- [Fitur Utama](#-fitur-utama)
- [Struktur Proyek](#-struktur-proyek--dokumentasi)
- [Instalasi](#-cara-menjalankan)
- [Kontribusi](#-kontribusi)
- [Lisensi](#-lisensi)

---

## 🎮 Gameplay
- **Genre**: 2D Endless Runner.
- **Core Loop**: Berlari, melompat, dan menyerang untuk menghindari rintangan/musuh.
- **Objective**: Kumpulkan koin dan gems, capai jarak terjauh, dan selesaikan misi harian.
- **Progression**: Tingkatkan skill dan power-ups di Shop menggunakan koin yang dikumpulkan.

### Kontrol
| Aksi | Keyboard | Mouse/Touch |
| :--- | :--- | :--- |
| **Lompat** | `Space` | Klik Kiri / Tap |
| **Serang** | `K` | Klik Kanan / Double Tap |
| **Pause** | `Esc` | Tombol Pause UI |

---

## ✨ Fitur Utama
- **Sistem Misi**: Misi harian, mingguan, dan tantangan dengan sistem reward dinamis.
- **Shop & Upgrades**: Tingkatkan durasi Power-ups (Magnet, Shield, Double Coins, Speed Boost).
- **XP & Leveling**: Sistem progres pemain dengan hadiah setiap kenaikan level.
- **Audio Dinamis**: BGM khusus untuk gameplay dan game over, dengan sistem audio ducking.
- **Optimization**: Renderer Mobile dioptimalkan untuk performa tinggi di perangkat Android.

---

## 🛠️ Struktur Proyek & Dokumentasi
Dokumentasi teknis lengkap tersedia di folder [docs/](docs/):

- 📜 [**Changelog**](CHANGELOG.md) - Riwayat perubahan versi.
- 🤖 [**AI Collaboration**](AI_COLLABORATION.md) - Panduan bekerja dengan AI.
- 🗺️ [**Roadmap**](ROADMAP.md) - Rencana pengembangan fitur.
- 🏗️ [**Arsitektur Pemain**](docs/GAME_CONCEPT_AND_PLAYER_IMPLEMENTATION.md) - Detail teknis kontrol dan state machine.
- 💰 [**Sistem Ekonomi**](docs/PLAYER_XP_AND_REWARD_SYSTEM.md) - XP, Level, dan Reward.
- 🛒 [**Desain Shop**](docs/SHOP_SHOP_DESIGN.md) - Struktur data dan UI Shop.
- 🎯 [**Sistem Misi**](docs/MISSIONS_PANEL_STRUCTURE.md) - Logika misi harian dan tantangan.

---

## 🚀 Cara Menjalankan
1. Pastikan Anda menggunakan **Godot Engine 4.6**.
2. Clone repository ini:
   ```bash
   git clone https://git.rakhasa.com/android-mini-game/dikejar-anomali.git
   ```
3. Buka `project.godot` melalui Godot Project Manager.
4. Tekan `F5` untuk menjalankan game (dimulai dari [LoadingScreen](scenes/LoadingScreen.tscn)).

---

## 🤝 Kontribusi
Kami menerima kontribusi dalam bentuk pelaporan bug, saran fitur, maupun pull request. Silakan baca [CONTRIBUTING.md](CONTRIBUTING.md) untuk panduan lebih lanjut.

---

## 📄 Lisensi
Proyek ini dilisensikan di bawah **MIT License**. Lihat file [LICENSE](LICENSE) untuk detail lebih lanjut.

---
© 2026 **Rakhasa Team** - [Okka Putra](mailto:okka.putra@rakhasa.com)
