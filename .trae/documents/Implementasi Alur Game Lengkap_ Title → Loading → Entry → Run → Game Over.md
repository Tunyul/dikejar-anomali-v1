## Target & Prinsip
- Engine: Godot 4.5 (open-source dan lintas platform). Fokus transisi yang smooth, animasi fluid, tanpa glitch, dan optimal di semua device.
- Ubah secukupnya pada file yang sudah ada; hanya tambah scene/script baru bila diperlukan.

## Rincian Implementasi per Spesifikasi
1) Title Screen Awal
- Tampilan transparan: gunakan `TitleScreen.tscn` yang sudah ada dan perkuat overlay transparan.
- Parallax bergerak sejak awal, terrain datar, tanpa player:
  - Parallax: set aktif saat title. Update `ParallaxBackground` via `parallax_auto_scroll.gd` untuk `set_movement_enabled(true)` ketika phase title aktif.
  - Terrain: visible tapi tidak bergerak. Tambah mode “title” di `TerrainGenerator` (disable hills dan gap; regenerasi datar).
- Manajemen phase: di `simple_game_manager.gd` (src/scripts/simple_game_manager.gd:1), tambahkan state permainan (TITLE, LOADING, PLAYING, GAME_OVER), dan kontrol `parallax`/`terrain` sesuai phase.

2) Loading Screen
- Tambah `scenes/LoadingScreen.tscn` + `scripts/loading_screen.gd` berisi progress bar.
- Integrasi progress:
  - Emit `signal generation_progress(pct: float)` dari `TerrainGenerator` selama `_generate_chunked()` (src/scripts/terrain_generator.gd:282–390) berdasarkan `x/world_width_tiles`.
  - Loading menampilkan progress: asset, generate terrain, dan init.
- Flow: setelah `start_game_requested`, tampilkan Loading → setelah progress 100%, lanjut ke Entry Player.

3) Animasi Masuk Player
- Player muncul dari kiri, memberi kesan dikejar anomali:
  - `player.gd` (src/scripts/player.gd:191–217, 266–296): ubah state APPEARING supaya `enable_environment_movement(false)` dan lerp X dari kiri ke target; tambahkan efek kecil (shake/ease/out) untuk kesan dikejar.
  - Pastikan parallax dan terrain diam saat animasi masuk.

4) Inisiasi Pergerakan
- Target posisi `x=280` dan `y=444`:
  - Set `entry_stop_x = 280` (src/scripts/player.gd:25) dan kunci Y ke `444` saat APPEARING/RUNNING_IN_PLACE.
  - Saat mencapai posisi tersebut, mulai animasi `run` dan aktifkan pergerakan parallax & terrain pada transisi ke `FULL_MOVEMENT` (src/scripts/player.gd:449–471).

5) Perbaikan Collision
- Pastikan `AnimatedSprite2D` centered (player.tscn:53–57) dan `CollisionShape2D` berukuran `130x200` (player.tscn:45–59).
- Revisi gravitasi dan deteksi lantai:
  - Gunakan `move_and_slide()` dengan `set_up_direction(Vector2.UP)` dan `set_floor_snap_length(24.0)` untuk snapping yang lebih stabil (src/scripts/player.gd:375–383).
  - Hapus collision nodes yang tidak perlu bila ada (audit di `player.tscn`).
- Terrain collision: telah dirapikan dengan helper, tetap gunakan top collision yang cukup tebal; jika perlu, tingkatkan rasio dari `0.3` ke `0.5` untuk grass/dirt.

6) Mekanika Game Over
- Bila tidak mengenai terrain collision, player jatuh; jika keluar area, trigger game over (src/scripts/player.gd:391–416 sudah ada).
- Tambah `scenes/GameOverScreen.tscn` + `scripts/game_over_screen.gd` dengan tombol restart.
- `simple_game_manager.gd` (src/scripts/simple_game_manager.gd:26–50): tampilkan overlay game over, stop environment movement, restart reset state dan posisi player.

7) Perbaikan UI
- Gunakan `UIManager.tscn` (scenes/UIManager.tscn:8–53):
  - Atur ulang anchor/offset untuk skor/jarak/waktu agar tidak menutupi gameplay.
  - Sesuaikan ukuran dan posisi untuk resolusi viewport; gunakan Anchors Preset dan margin konsisten.
  - Pastikan UI berada di `CanvasLayer` dengan layer tinggi dan tetap visible.

8) Teknis & Performa
- Transisi smooth: gunakan `call_deferred` dan `_generate_chunked()` seperti saat ini; hindari kerja berat di frame awal.
- Animasi fluid: jalankan pergerakan di `_physics_process` untuk konsistensi frame rate (parallax & terrain sudah demikian).
- Optimasi: gating log sudah aktif; pastikan parallax dan terrain hanya bergerak pada phase yang tepat.

## Perubahan File yang Direncanakan
- Edit:
  - `scripts/simple_game_manager.gd`: tambah state machine fase game; koneksi Title/Loading/GameOver.
  - `scripts/player.gd`: set target posisi (280, 444), disable env movement saat APPEARING, enable pada FULL_MOVEMENT; tingkatkan `floor_snap_length`.
  - `scripts/parallax_auto_scroll.gd`: dukung aktif-awal saat TITLE, expose helper untuk toggle.
  - `scripts/terrain_generator.gd`: tambah signal progress dan mode `set_title_mode(bool)` untuk terrain datar.
  - `scenes/Main.tscn`: tambahkan `LoadingScreen` dan `GameOverScreen` ke `CanvasLayer`; atur properti awal parallax/terrain.
  - `scenes/UIManager.tscn`: penyesuaian anchor/offset.
- Tambah:
  - `scenes/LoadingScreen.tscn` + `scripts/loading_screen.gd`.
  - `scenes/GameOverScreen.tscn` + `scripts/game_over_screen.gd`.

## Verifikasi
- Jalankan dari Title: parallax bergerak, terrain datar, player hidden.
- Loading: bar naik ke 100% selama generate; tidak lag.
- Entry: player masuk dari kiri, parallax/terrain diam; mencapai (280,444), animasi run mulai.
- Run: parallax/terrain aktif, collision stabil, fps konsisten.
- Game Over: saat jatuh di luar area, overlay tampil dengan opsi restart; restart mengembalikan ke Title atau langsung ke Title sesuai desain.

Konfirmasi rencana ini, lalu saya lanjut implementasi end-to-end sesuai urutan di atas dengan pengujian di setiap fase.