# Skill / Power-Up

- Bubble shield (tahan 1 tabrakan lalu hilang)
- Magnet coin (menarik coin dalam radius tertentu)

Status per: 1.3.18-beta (2026-01-09)

- Magnet coin sudah aktif penuh (pickup → efek → HUD → habis).
- Double coins dan speed boost sudah aktif sebagai power tambahan di gameplay.
- Shield dan sistem health/heart sudah terintegrasi dengan HUD dan game over.
- Skill lain masih di level desain.

## Todos Skill / Power-Up

- Definisikan daftar final skill yang dipakai di versi 1.0
- Tentukan durasi, cooldown, dan rarity tiap skill
- Implementasi sistem pengaktifan skill (pickup / tombol / otomatis)
- Tambah feedback visual: efek, warna, outline, icon HUD tiap skill
- Tambah feedback audio: SFX khusus saat aktif dan berakhir
- Integrasi skill dengan sistem skor (bonus, multiplier, coin boost)
- Uji kombinasi skill agar tetap seimbang

# Fitur Ingame

- Sistem skor berbasis jarak tempuh
- Coin dan currency untuk beli item atau skin di Shop
- Combo atau multiplier bila tidak kena obstacle dalam waktu tertentu
- Misi harian atau mingguan sederhana (collect X coin, jarak Y, dsb.)
- Sistem life atau attempt (nyawa atau tiket run)
- Sistem difficulty scaling (speed dan obstacle naik bertahap)
- Pause dan Settings ingame (BGM, SFX, sensitivitas input)
- Game over screen dengan statistik run (jarak, coin, best, misi)
- Sistem achievement sederhana (milestone jarak, coin, skill usage)

## Todos Fitur Ingame

- Finalisasi formula skor: jarak, coin, bonus combo, mission bonus
- Tambah penyimpanan progres achievement (best score dan total coin sudah disimpan)
- Rancang dan implementasi misi harian atau mingguan 3–5 template
- Tambah sistem difficulty curve per jarak (tabel atau fungsi)
- Integrasi Shop dengan currency: beli skin, efek trail, atau boost
- Lengkapi Game Over menu: tombol retry dan kembali ke menu sudah ada; tambah akses cepat ke misi dan informasi run
- Tambah indikator UI untuk multiplier, mission progress, active skill
- Lakukan balancing awal lewat playtest dan revisi angka utama
