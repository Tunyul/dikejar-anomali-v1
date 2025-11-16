## Masalah
- Mengubah `tile_scale` di Inspector tidak mengubah ukuran visual tile karena skala node tidak di-update.
- Saat ini, perubahan skala node hanya terjadi jika `update_transform_on_generate` aktif.

## Solusi
1. Tambah setter `tile_scale` agar setiap perubahan langsung diterapkan ke skala node dan regenerate:
   - `@export var tile_scale: float = 0.25 : set = _set_tile_scale`
   - `func _set_tile_scale(v): tile_scale = max(0.01, v); scale = Vector2(tile_scale, tile_scale); generate()`
2. Di `generate()`, selalu set `scale = Vector2(tile_scale, tile_scale)` tanpa menyentuh `position.y`.
3. Pertahankan border/collision berbasis `tile_px = tile_size * tile_scale` untuk tetap selaras.
4. Opsional: hapus `update_transform_on_generate` (tidak diperlukan lagi) atau tetapkan tetapi diabaikan untuk `scale`.

## Verifikasi
- Ubah `tile_scale` ke 0.5, 5.0, dll. → visual tile berubah instan atau setelah Regenerate, sementara `position` tetap.
- Border/label/collision mengikuti skala baru karena memakai `tile_px`.

## Dampak
- Inspector menjadi responsif untuk kontrol ukuran tile.
- Tidak ada perubahan pada posisi node; hanya skala di-update.
