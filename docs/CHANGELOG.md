Perubahan 2025-11-12

- Tambah layer `Clouds` dengan spawn acak `Cloud_1.png` dan `Cloud_2.png`, kontrol transparansi, skala, interval, batas area spawn, dan pembersihan otomatis.
- Perbaiki looping gunung: algoritma wrap memakai tepi kanan efektif untuk transisi yang smooth dan infinite; pastikan `Mountain_4` muncul kembali setelah keluar layar.
- Parameter ekspor baru: `mountain_far4_motion_scale`, `cloud_motion_scale`, `cloud_spawn_interval_min/max`, `cloud_spawn_y_min/max_ratio`, `cloud_scale_min/max`, `cloud_alpha`, `cloud_max_count`.
- Naikkan `MountainFar4.motion_scale` (20%).
- Perbaiki error sintaks ternary di `parallax.gd` ke bentuk `truthy if cond else falsy`.
- Hilangkan peringatan unused parameter dengan mengganti `delta` ke `_delta` di `game.gd`.
