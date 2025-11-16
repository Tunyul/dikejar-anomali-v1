## Tujuan
- Menambahkan script GDScript untuk menghasilkan peta ubin (tilemap) secara prosedural pada `TileMapLayer` di `scenes/Ground.tscn`.

## Fitur Utama
- Ukuran peta dapat diatur (`width`, `height`).
- Pengacakan berbasis `seed` agar hasil reproducible.
- Generator berbasis noise (`FastNoiseLite`) untuk pola alami.
- Threshold untuk pemilihan tile (mis. grass vs dirt).
- Opsi `auto_generate_on_ready` dan `clear_before_generate`.
- Metode publik `generate()` dan `clear_map()` untuk dipanggil dari editor atau runtime.

## Implementasi Teknis
- Buat file `scripts/TileMapGenerator.gd` dengan `@tool` agar dapat dipakai di editor.
- Target node: pasang script pada node `TileMapLayer` (`scenes/Ground.tscn:21`).
- Ekspor variabel:
  - `@export var width: int = 64`
  - `@export var height: int = 64`
  - `@export var seed: int = 12345`
  - `@export var noise_frequency: float = 0.02`
  - `@export var grass_threshold: float = 0.5`
  - `@export var dirt_threshold: float = 0.3`
  - `@export var auto_generate_on_ready: bool = true`
  - `@export var clear_before_generate: bool = true`
  - `@export var grass_source_id: int = 0` (mengacu `TileSet` sumber `Grass` di `scenes/Ground.tscn:16–17`)
  - `@export var dirt_source_id: int = 1`
  - `@export var atlas_coords_grass: Vector2i = Vector2i(0, 0)`
  - `@export var atlas_coords_dirt: Vector2i = Vector2i(0, 0)`
- Logika `generate()`:
  - Validasi `tile_set` pada node.
  - Inisialisasi `FastNoiseLite` dengan `seed` dan `frequency`.
  - Iterasi `x in [0,width)` dan `y in [0,height)`:
    - Ambil nilai noise `n = noise.get_noise_2d(x, y)`.
    - Jika `n >= grass_threshold`: set cell ke `grass_source_id`.
    - Else jika `n >= dirt_threshold`: set cell ke `dirt_source_id`.
    - Else: biarkan kosong (atau pilih tile lain opsional).
  - Gunakan API `TileMapLayer` untuk `clear()` dan `set_cell(...)` (sesuaikan signature Godot 4).
- `clear_map()` memanggil `clear()` pada `TileMapLayer`.
- Di `_ready()`: jika `auto_generate_on_ready`, panggil `generate()`.

## Struktur Kode
- `scripts/TileMapGenerator.gd`: berisi logika generator dan variabel ekspor.
- Tidak mengubah struktur scene selain menautkan script ke node `TileMapLayer`.

## Integrasi
- Tautkan script ke `TileMapLayer` di `Ground.tscn`.
- Pastikan `tile_set` memuat `TileSet` yang memiliki `sources/0` (Grass) dan `sources/1` (Dirt) seperti pada `scenes/Ground.tscn:15–18`.
- Pastikan `scale` node tetap `Vector2(1, 1)` agar ukuran tile tampil benar.

## Validasi
- Jalankan scene dan verifikasi tile muncul sesuai threshold.
- Ubah `seed` dan `threshold` untuk melihat variasi pola.
- Periksa performa pada ukuran besar; sesuaikan `frequency` dan `width/height` bila perlu.

## Ekstensi Opsional
- Variasi atlas (`alternative_tile`) untuk mengurangi repetisi.
- Lapisan multi-biome (misal: sand, rock) dengan lebih banyak threshold.
- Penambahan dekorasi (pohon, bunga) dengan probabilitas terpisah.
- Tombol editor via `EditorPlugin` untuk memicu `generate()` dari Inspector.

Konfirmasi rencana ini. Setelah disetujui, saya akan menambahkan file script dan menautkannya ke `TileMapLayer`. 