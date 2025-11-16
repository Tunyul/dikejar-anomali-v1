## Masalah
Klik Regenerate mengubah `position.y` (~959) dan `scale` (0.25), padahal Anda ingin Node2D Ground tetap pada transform awal (x=0, y=0, scale=1).

## Solusi
- Hapus semua perubahan transform dalam `generate()` (jangan set `scale` atau `position.y` sama sekali).
- Gunakan transform node saat ini sebagai acuan perhitungan (border/label) tanpa memodifikasi node:
  - `base_px = position.y + ground_y_tiles * tile_size * tile_scale` dipakai untuk hitung border/label.
- Pertahankan `tile_scale` hanya sebagai faktor ukuran tile (untuk `tile_px`), bukan sebagai skala node.
- Pastikan `auto_generate=false` (sudah default) agar transform tidak disentuh pada startup.

## Implementasi
1. Di `generate()`:
   - Hapus atau bungkus dengan flag semua baris yang menyetel `scale` dan `position.y`. Ganti dengan komentar internal: “no transform changes”.
   - Simpan logika pembuatan TileSet, cells, collision, border, dan label seperti sekarang.
2. Validasi border dan label:
   - Sudah memakai `position.y` untuk menghitung `world_px`. Pastikan tetap tidak memodifikasi `position.y`.
3. Opsional, hapus `update_transform_on_generate` karena perilaku default sekarang: tidak mengubah transform.

## Hasil
- Klik Regenerate tidak mengubah `position`/`scale` Node2D Ground.
- Terrain, collision, border dan label tetap dihasilkan sesuai setelan Inspector (tanpa efek samping pada transform).

## Verifikasi
- Set Node2D Ground ke x=0,y=0,scale=1.
- Klik Regenerate: transform tidak berubah, tile muncul sesuai setelan.
- Cek border px dan label px dunia—selaras dengan ground tanpa mengubah node.
