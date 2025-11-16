## Tujuan
- Rapihkan dan kurangi parameter Inspector hanya yang berfungsi.
- Pastikan generate tidak mengubah transform Node2D.
- Tetapkan default aman (flat, tanpa jurang, collision opsional) dan urutkan parameter secara logis.
- Perbaiki potensi bug (clamp tinggi tanjakan saat default 0).

## Penghapusan Parameter (tidak dipakai/duplikatif)
- Hapus `enable_debug_visuals` (tidak digunakan di kode).
- Hapus `grass_color`, `dirt_color` (base tiles tidak ditint; pewarnaan hanya untuk tiles hill).
- Hapus `flat_prefix_tiles` (tidak digunakan di generator baru).

## Perbaikan Keamanan & Konsistensi
- Di `_place_up/_place_down`: ubah `var h: int = clamp(height, 1, hill_max_height)` menjadi aman saat default 0:
  - `var max_h: int = max(1, hill_max_height)`
  - `var h: int = clamp(height, 1, max_h)`
- Pastikan `generate()` tidak menyetel `position/scale` (sudah ditahan) — hapus flag `update_transform_on_generate` bila tidak diperlukan.

## Urutan Inspector Baru
### 1. Dimensi Dasar
- `tile_size`
- `tile_scale`
- `world_width_tiles`

### 2. Posisi & Baseline
- `ground_y_tiles`
- `target_baseline_px` (hanya untuk kalkulasi border/label, tidak mengubah transform)

### 3. Pola & Flat
- `enable_random_patterns`
- `flat_min_tiles`
- `flat_max_tiles`
- `min_gap_tiles`
- `max_gap_tiles`
- `hill_max_height`
- `max_step_height`
- `use_caps`

### 4. Collision & Border
- `enable_ground_collision`
- `collision_top_ratio`
- `draw_border`
- `border_color`
- `border_width_px`
- `border_target_world_px` (opsional; memanggil `set_border_world_px`)

### 5. Debug Posisi
- `show_tile_positions`
- `tile_label_step`

### 6. Tekstur
- `use_raw_load_for_base`
- `grass_texture_path`
- `dirt_texture_path`
- `grass_left_texture_path`
- `grass_right_texture_path`
- `hill_up_texture_path`
- `hill_down_texture_path`
- `hill_up2_texture_path`
- `hill_down2_texture_path`
- `colorize_tiles`
- `up_color`, `down_color`, `up2_color`, `down2_color`

### 7. Proses
- `auto_generate`
- `regenerate` (setter tetap reset ke false)

## Implementasi
- Hapus deklarasi ekspor yang disebut di bagian Penghapusan.
- Terapkan perbaikan clamp di `_place_up/_place_down`.
- Reorder deklarasi ekspor sesuai urutan di atas.
- Sisakan generate tanpa perubahan transform.

## Verifikasi
- Regenerate: transform node tetap (x=0,y=0,scale=1).
- Flat default: tidak ada jurang/naik turun.
- Aktifkan collision: player dapat berdiri di ground; border selaras px dunia.
- Turn on random patterns: up/down tetap aman walau `hill_max_height` default 0 (karena clamp aman).
