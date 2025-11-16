## Tujuan
- Menetapkan default mapping terrain agar looping: naik 1 tiles → jurang 2 tiles → turun 1 tiles → jurang 2 tiles (repeat).
- Warna tiles hill: naik pakai merah (up2), lalu tepat 1 tiles di atasnya hijau (up). Turun pakai biru (down), lalu tepat 1 tiles di bawahnya kuning (down2).
- Berlaku konsisten di editor (Regenerate) dan runtime.

## Default Parameter
- `world_width_tiles = 128`
- `target_baseline_px = 520`
- `use_alternating_hills_with_gaps = true`
- `hill_run_min_tiles = 2`, `hill_run_max_tiles = 2`
- `min_gap_tiles = 2`, `max_gap_tiles = 2`
- `gap_spacing_tiles = 0` (jurang langsung setelah segmen)
- `flat_prefix_tiles = 0` (mulai pola dari kolom pertama)
- `hill_y_min`/`hill_y_max`: set jarak vertikal realistis, contoh `2..6`.

## Implementasi Pola Deterministik
- Di `scripts/terrain_generator.gd:_generate_chunked()`:
  1. Saat `use_alternating_hills_with_gaps == true`, jalankan builder pola alih-alih memakai probabilitas `gap_chance`/`hill_chance`.
  2. Loop sampai `x < world_width_tiles`:
     - Bangun slope 2 tiles:
       - `dir_up` awal acak saat regenerate (editor) / runtime.
       - `dy = +1` jika naik, `-1` jika turun.
       - Tile urutan:
         - Naik: `start_tid = hill_up2` (merah) di `(x, y)` lalu naik 1, `mid_tid = hill_up` (hijau) di kolom berikut pada `y+1`.
         - Turun: `start_tid = hill_down` (biru) di `(x, y)` lalu turun 1, `mid_tid = hill_down2` (kuning) di kolom berikut pada `y-1`.
       - Isi dirt di bawah setiap kolom sesuai `fill_depth_tiles`.
       - Update `surface_y_by_x[x]` untuk kedua kolom.
     - Sisipkan jurang persis 2 tiles: `x += 2` tanpa menulis cell (gap kosong). Tambahkan caps bila `use_caps` aktif (`grass_right` sebelum gap, `grass_left` sesudah gap).
     - Toggle arah: `dir_up = not dir_up`.
  3. Guard batas dunia: sebelum setiap write, cek `x >= world_width_tiles` → break.

## Sinkronisasi RNG (Editor)
- Saat klik Regenerate di editor dengan `rng_seed == 0`:
  - Tetapkan `_editor_preview_seed` satu kali per klik dan gunakan seed ini di `_generate_chunked()` dan `_rebuild_spikes()` supaya ground & spikes sama-sama berubah tiap klik.
  - Acak arah awal `dir_up` menggunakan RNG seeded tersebut.

## Validasi
- Inspector: klik Regenerate beberapa kali, pastikan:
  - Urutan selalu: naik 1 → jurang 2 → turun 1 → jurang 2 → repeating sampai lebar dunia.
  - Warna tile sesuai: merah → hijau (naik), biru → kuning (turun).
  - Tidak ada out-of-bounds pada `surface_y_by_x`.
- Runtime: mulai game, terrain tetap looping dengan pola sama.

## Penyesuaian Opsional
- Ubah jarak jurang via `min_gap_tiles/max_gap_tiles` (biarkan sama agar selalu 2 tiles).
- Ubah batas vertikal `hill_y_min/hill_y_max` untuk variasi tinggi slope tanpa merusak pola.
- Matikan `use_alternating_hills_with_gaps` bila ingin kembali ke pola acak (pakai `gap_chance/hill_chance`).