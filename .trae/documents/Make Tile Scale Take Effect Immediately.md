## Diagnosa
- `tile_scale` dipakai untuk perhitungan `tile_px`, tapi node `TileMapLayer` tidak di‑scale ketika generate, sehingga perubahan visual tidak tampak.
- Ada gating yang pernah ditambahkan agar generate tidak mengubah transform; akibatnya skala node tidak diupdate.

## Solusi
1. Terapkan `tile_scale` ke `scale` node setiap kali nilai berubah atau saat `Regenerate`:
   - Tambah setter: `@export var tile_scale: float = 0.25 : set = _set_tile_scale`.
   - `func _set_tile_scale(v): tile_scale = max(0.01, v); scale = Vector2(tile_scale, tile_scale)` dan panggil `generate()` agar border/collision ikut recalculated.
2. Di `generate()`, pastikan `scale = Vector2(tile_scale, tile_scale)` dieksekusi tanpa mengubah `position.y`.
3. Tetap biarkan transform posisi node tidak diubah, hanya skala yang mengikuti `tile_scale`.
4. Pastikan border/collision memakai `tile_px = tile_size * tile_scale`, sehingga tetap selaras.

## Verifikasi
- Set `tile_scale = 5.0` di Inspector → klik Regenerate → tiles membesar, border/collision selaras.
- Ubah kembali ke `0.25` → tiles mengecil, transform posisi tidak bergeser.
