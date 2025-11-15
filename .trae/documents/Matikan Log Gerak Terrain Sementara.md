## Tujuan
- Menonaktifkan sementara output log/print dari terrain agar konsol bersih.

## Implementasi
- Tambah flag `@export var enable_debug_logging: bool = false` pada `scripts/terrain_scroll.gd`.
- Ubah dua titik print:
  - Di `_physics_process`: `if state_timer < 1.0 and OS.is_debug_build()` → `if enable_debug_logging and OS.is_debug_build()`.
  - Di `set_movement_enabled`: bungkus `print(...)` dengan `if enable_debug_logging and OS.is_debug_build()`.
- Default flag `false` sehingga log tidak tampil; bisa diaktifkan kembali lewat Inspector jika diperlukan.

## Verifikasi
- Jalankan scene; pastikan pesan "Terrain ... moving ..." dan "Terrain movement_enabled set to" tidak muncul lagi.

Konfirmasi untuk menerapkan perubahan ini sekarang.