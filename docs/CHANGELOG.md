Perubahan 2026-01-30 (v1.3.26-beta)

- Shop: menambahkan label "Coming Soon" pada Cosmetics, Gem Packs, dan Bundles.
- Shop: tampilkan full item shop di editor (data runtime + non-clip).

Perubahan 2026-01-28 (v1.3.25-beta)

- Shop: menyamakan daftar skill dan upgrade (magnet, shield, double coins, speed boost) antara runtime dan dummy editor.
- Shop: mengganti font angka koin/gems/harga agar sama dengan judul "Shop" dan menambahkan outline hitam untuk keterbacaan.
- Shop: menambahkan tampilan angka uji `123456789` di editor guna mengecek bentuk digit.
- Speed Boost: membuat pickup Speed Boost in-game ikut terpengaruh upgrade durasi dan multiplier dari Shop.

Perubahan 2026-01-24 (v1.3.24-beta)

- Shop: menambahkan menu Shop baru dengan kategori Skills & Power-ups, Upgrades, Cosmetics, Gem Packs, dan Bundles.
- Shop: memakai koin/gems dari save (`progress/total_coins` dan `progress/total_gems`) dengan tampilan ikon dan harga yang jelas.
- Shop: menampilkan jumlah item/power-up yang sudah dimiliki dan menonaktifkan tombol beli jika saldo tidak cukup atau skin sudah dimiliki.
- Shop: setiap pembelian langsung menyimpan perubahan ke `user://save.cfg` (coins/gems, powerups, dan data cosmetics/skin) serta me-refresh UI Shop.
- Save: memastikan `meta/version` di `user://save.cfg` mengikuti `application/config/version` aktif.

Perubahan 2025-11-12

Catatan: untuk daftar perubahan terbaru lihat `CHANGELOG.md` di root proyek.

- Tambah layer `Clouds` dengan spawn acak `Cloud_1.png` dan `Cloud_2.png`, kontrol transparansi, skala, interval, batas area spawn, dan pembersihan otomatis.
- Perbaiki looping gunung: algoritma wrap memakai tepi kanan efektif untuk transisi yang smooth dan infinite; pastikan `Mountain_4` muncul kembali setelah keluar layar.
- Parameter ekspor baru: `mountain_far4_motion_scale`, `cloud_motion_scale`, `cloud_spawn_interval_min/max`, `cloud_spawn_y_min/max_ratio`, `cloud_scale_min/max`, `cloud_alpha`, `cloud_max_count`.
- Naikkan `MountainFar4.motion_scale` (20%).
- Perbaiki error sintaks ternary di `parallax.gd` ke bentuk `truthy if cond else falsy`.
- Hilangkan peringatan unused parameter dengan mengganti `delta` ke `_delta` di `game.gd`.
