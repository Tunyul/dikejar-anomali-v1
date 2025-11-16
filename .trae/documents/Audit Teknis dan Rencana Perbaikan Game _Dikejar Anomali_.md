## Ringkasan Arsitektur
- Main scene: `res://scenes/Main.tscn` dengan pengelola `scripts/simple_game_manager.gd` (fase game, loading, countdown, transisi UI). Latar belakang `ParallaxBackground` menggunakan `scripts/parallax_auto_scroll.gd`. UI: `TitleScreen`, `LoadingScreen`, `GameOverScreen`. Player: instans `scenes/player.tscn` (`scripts/player.gd`).
- Ground: `scenes/Ground.tscn` memakai `scripts/ground_generator.gd` (generasi tile, progres, collision polygon). Saat ini belum diinstans di `Main`.
- UI gameplay (Healthbar, DistanceCounter, GameTimer) tersedia di `scenes/UIManager.tscn` namun belum dipakai di `Main`.

## Temuan Kritis
1. Node yang direferensikan tetapi tidak ada di `Main`: `Terrain`, `TerrainB`, `Ground`, `TerrainB/Ground`, `Camera2D`. Tanpa ground, player akan jatuh dan loading terjebak karena progres tidak pernah naik.
2. `Ground.tscn` tidak memiliki anak `CollisionPolygon2D`, sehingga `_build_collision()` tidak menulis polygon dan tidak ada collision.
3. Sistem skor/jarak tidak terhubung ke UI; `DistanceCounter` tidak diinstans.
4. Tidak ada musuh/AI, audio, dan sistem save/load.
5. Potensi duplikasi koneksi sinyal pada siklus start/restart.

## Rencana Perbaikan (Tahap Bertahap)
### Tahap 1: Fungsionalitas Dasar Game
- Instans `Ground.tscn` di `Main` (nama node `Ground`) dan tambahkan anak `CollisionPolygon2D` agar generator dapat menulis polygon collision.
- Sesuaikan `simple_game_manager.gd` agar mendukung 1 ground (fallback jika `TerrainB/Ground` tidak ada), serta pastikan loading selesai berdasarkan progres ground yang ada.
- Pastikan player berada di atas ground pada state `ENTRY`/`PLAYING` dengan verifikasi `is_on_floor()`.

### Tahap 2: Integrasi UI Gameplay
- Instans `UIManager.tscn` di `CanvasLayer` dan hubungkan: `distance` dari game manager ke `DistanceCounter`, timer mulai/berhenti sesuai fase, dan healthbar jika diperlukan.

### Tahap 3: Musuh & Interaksi
- Buat scene musuh sederhana (mis. obstacle bergerak) dan integrasikan ke `spawn_scenes` `ground_generator.gd`. Tambahkan deteksi tabrakan (damage/game over) via layer/mask.

### Tahap 4: Audio
- Tambahkan `AudioStreamPlayer` untuk BGM dan SFX (loncat, game over). Trigger dari `player.gd` dan `simple_game_manager.gd`.

### Tahap 5: Save/Load
- Implementasi persistensi skor terbaik/jarak total menggunakan `ConfigFile` atau `FileAccess` JSON. Muat saat startup, simpan saat game over.

### Tahap 6: Kebersihan & Optimasi
- Cegah duplikasi koneksi sinyal (`is_connected` sebelum connect). Putus koneksi saat tidak diperlukan.
- Review performa generator: batasi `await` per kolom untuk jumlah kolom besar, dan pastikan pembersihan node konsisten.
- Pertimbangkan penambahan `Camera2D` atau hapus referensi jika tidak dipakai.

### Output yang Diharapkan
- Game berjalan dari title → loading → entry → playing → game over dengan ground collision aktif.
- UI menampilkan jarak/skor dan timer. Musuh dasar muncul dari generator. Audio aktif. Data skor terbaik tersimpan.

Silakan konfirmasi rencana ini. Setelah disetujui, saya akan menerapkan perubahan tahap demi tahap dan memverifikasi hasilnya di preview.