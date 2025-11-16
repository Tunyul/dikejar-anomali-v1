## Masalah
Mengubah `tile_scale` di Inspector tidak berdampak saat Regenerate karena `generate()` tidak lagi menyetel `Node2D.scale`. Saat ini `tile_scale` hanya dipakai untuk perhitungan internal (`tile_px`, border, label), bukan visual.

## Solusi
- Terapkan `tile_scale` ke `Node2D.scale` setiap kali `generate()` dipanggil.
- Tetap TIDAK mengubah `position.y` (baseline tidak memaksa transform) agar node tidak bergeser.
- Pastikan border/collision tetap memakai `tile_px = tile_size * tile_scale` sehingga selaras.

## Implementasi
1. Di `generate()`, set `scale = Vector2(tile_scale, tile_scale)` tanpa mengubah `position`.
2. Tidak mengubah bagian lain (TileSet, collision, border), karena sudah konsisten terhadap `tile_px`.

## Verifikasi
- Set `tile_scale` ke 0.5, klik Regenerate → tiles tampak lebih besar, border dan collision tetap selaras.
- Kembalikan ke 0.25 → tiles mengecil; transform `position` tidak berubah (tetap y=0 bila node Anda di 0).
