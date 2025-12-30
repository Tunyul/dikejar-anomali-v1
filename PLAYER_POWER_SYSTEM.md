# Sistem Power / Power-Up Player

Dokumen ini merangkum kondisi saat ini dan daftar kerja yang dibutuhkan
untuk menyambungkan power/power-up ke gameplay player.

---

## 1. Kondisi Saat Ini

- Player:
  - Script utama: `scripts/player.gd` (auto-run, lompat, attack, health).
  - Belum ada state khusus untuk power-up (dash, shield, ghost, dsb.).
  - Sudah mendukung `air_jumps` sebagai parameter umum (bisa dipakai untuk double jump).

- Game Manager:
  - Script: `scripts/game_manager.gd` (fase ENTRY/PLAYING/GAME_OVER, skor, jarak, coins).
  - Power-up magnet:
    - Variabel runtime: `magnet_enabled`, `magnet_timer`.
    - Parameter durasi: `powerup_magnet_duration_sec` (export).
    - HUD: `MagnetIcon` dan `MagnetTimerLabel` di `CanvasLayer` sudah terhubung ke `magnet_enabled` dan `magnet_timer`.
  - XP dan progres player sudah dihubungkan (level, xp, reward) lewat sistem di dokumen lain.

- Magnet Power-Up:
  - Scene: `scenes/MagnetPowerup.tscn` (Area2D dengan `scripts/magnet_powerup.gd`).
  - Saat player menyentuh:
    - Memanggil `activate_magnet(duration_sec)` di scene utama (GameManager).
    - GameManager mengatur `magnet_timer` dan `magnet_enabled`.
    - `scripts/coin.gd` membaca `magnet_enabled` dari node root `Main` dan melakukan coin-magnet ke posisi player.
  - Hasil: power-up magnet SUDAH aktif dan terintegrasi penuh (pickup → efek → HUD → habis).

- Shop / Power Items:
  - Script shop: `scripts/ShopMenu.gd`.
  - Grup "Power-ups (Coins)": `magnet_30s`, `shield_1hit`, `double_coins_run`, `extra_heart_run`.
  - Grup "Upgrades (Coins)": upgrade `max_heart_plus1`, `magnet_duration_plus10`, `shield_duration_plus10`, `pickup_range_plus1`.
  - Saat ini shop hanya:
    - Mengurangi `total_coins` di `user://save.cfg`.
    - Menampilkan pesan "Pembelian berhasil".
    - BELUM menyimpan status power-up yang dibeli sebagai inventory/run modifiers.

- Dokumen Desain:
  - `GAME_SKILLS_AND_FEATURES.md`:
    - Daftar skill: dash, double jump, bubble shield, magnet coin, slow motion, giant, ghost phase.
    - Todos general untuk skill/power-up (durasi, cooldown, rarity, feedback visual/audio, integrasi skor, balancing).
  - `GAME_CONCEPT_AND_PLAYER_IMPLEMENTATION.md`:
    - Bagian khusus magnet power-up (sudah sebagian besar tercapai di kode).
    - Power-up lain masih di level konsep.

Kesimpulan: satu-satunya power yang benar-benar aktif di gameplay player saat ini adalah
magnet coin. Semua power lain masih konsep atau hanya muncul sebagai item di Shop tanpa
efek ke gameplay.

---

## 2. Tujuan Sistem Power Player

Tujuan:

- Punya kerangka power-up yang konsisten:
  - Power berbasis pickup (in-run, misalnya MagnetPowerup di level).
  - Power berbasis shop (pre-run, misalnya extra heart 1 run).
  - Power berbasis progression (permanent upgrade, misalnya magnet duration +10%).
- Power memodifikasi perilaku player dan rules GameManager secara jelas dan terukur.
- UI menampilkan status power yang aktif dengan jelas (icon, timer, indikator).

---

## 3. Daftar Kerja Inti (Framework Power-Up)

### 3.1. Struktur Data Power-Up Run

- Tambah struktur data di GameManager untuk menyimpan power run-scope, misalnya:
  - Flag satu-run: magnet_30s, shield_1hit, double_coins_run, extra_heart_run.
  - Nilai numerik hasil upgrade: extra_max_health, magnet_duration_multiplier, shield_duration_multiplier, pickup_radius_bonus.
- Sumber data:
  - Dibaca dari `save.cfg` saat masuk gameplay (hasil pembelian di Shop).
  - Dibersihkan / dikurangi setelah dipakai dalam satu run (untuk power "1 Run").

### 3.2. Integrasi Power dengan Siklus Run

- Di flow start run (`_start_play_phase` atau setara):
  - Baca semua power aktif dari data progres.
  - Terapkan ke player dan GameManager:
    - Max health dan starting health.
    - Durasi magnet default.
    - Modifikator skor/coin.
    - Shield status awal (jika ada).
- Di akhir run (Game Over):
  - Kurangi/clear power jenis "1 Run" dari save.
  - Simpan kembali progres di `save.cfg`.

### 3.3. API Antar-Komponen

- GameManager expose fungsi sederhana untuk power:
  - Mengaktifkan magnet (sudah ada).
  - Mengaktifkan shield (baru).
  - Mengaktifkan double coins untuk run ini.
  - Menambah max health / extra heart.
- Player expose fungsi untuk efek langsung ke tubuh player:
  - Set max health dan current health awal.
  - Set jumlah air jump (untuk power double jump jika dipakai).
  - Aktif/nonaktifkan state shield/ghost/giant secara sementara.

---

## 4. Daftar Kerja per Power

### 4.1. Magnet Coin (sudah ada, perlu pematangan)

- Review:
  - Pickup dan efek core sudah bekerja.
  - HUD sudah menampilkan icon dan timer.
- Pekerjaan lanjutan:
  - Kaitkan durasi magnet dengan upgrade di Shop (`magnet_duration_plus10`).
  - Tambah efek visual di player saat magnet aktif (glow/outline/partikel).
  - Pastikan magnet tetap performa-ok saat banyak coin di layar.

### 4.2. Shield 1 Hit

- Desain efek:
  - Menahan satu tabrakan dengan musuh/obstacle tanpa game over.
  - Setelah trigger, shield hilang dan memberi feedback visual/audio.
- Kerja teknis:
  - Tambah state `shield_charges` atau flag sejenis di GameManager atau Player.
  - Di kode damage/player-hit:
    - Jika shield aktif dan ada charge:
      - Konsumsi satu charge, batalkan damage/game over.
      - Trigger efek visual/audio khusus shield break.
    - Jika tidak ada shield: perilaku tetap seperti sekarang.
  - Integrasi Shop:
    - Pembelian `shield_1hit` menambah shield charge untuk run berikutnya.
    - Upgrade `shield_duration_plus10` jika nanti ada shield dengan durasi.
  - HUD:
    - Icon shield + indikator jumlah charge/aktif.

### 4.3. Double Coins (1 Run)

- Efek:
  - Menggandakan coin yang didapat selama run ini.
- Kerja teknis:
  - Tambah flag `double_coins_run_active` di GameManager.
  - Di tempat coin dikreditkan (coin.gd → GameManager):
    - Jika flag aktif, tambahkan 2 coin per pickup (atau multiplier configurable).
  - Integrasi Shop:
    - Pembelian `double_coins_run` mengaktifkan flag untuk run berikutnya.
    - Setelah run selesai, flag dikembalikan ke false dan disimpan di save.
  - HUD:
    - Icon multiplier coin / teks kecil "x2" dekat coin HUD.

### 4.4. Extra Heart (1 Run)

- Efek:
  - Menambah kapasitas health player hanya untuk satu run.
- Kerja teknis:
  - Player sudah punya `max_health` dan `starting_health`.
  - Tambah modul:
    - Extra heart run: hanya berlaku untuk satu run (di-reset setelah game over).
    - Upgrade `max_heart_plus1`: menaikkan `max_health` permanen lewat progres.
  - Integrasi Shop:
    - `extra_heart_run` → flag/nilai yang hanya hidup satu run.
    - `max_heart_plus1` → naikkan angka permanent di `save.cfg` dan sinkron ke Player.
  - HUD:
    - Pastikan HealthBar mengikuti max health terbaru.

### 4.5. Double Jump sebagai Power

- Kondisi saat ini:
  - Player sudah punya variabel `air_jumps` untuk support lompat udara.
- Kerja teknis:
  - Gunakan power (pickup atau shop) untuk:
    - Mengubah `air_jumps` saat run dimulai (misal 1).
    - Kembalikan ke default setelah run selesai.
  - Opsional: power yang memberi double jump untuk beberapa detik saja (state dengan timer).
  - HUD: icon double jump saat efek aktif (jika sifatnya temporary).

### 4.6. Dash, Slow Motion, Giant, Ghost Phase

- Masih 100% pada level desain, belum ada code.
- Kerja teknis umum:
  - Tambah state machine mini untuk setiap power di Player atau modul terpisah.
  - Tentukan input (tekan tombol, auto saat pickup, atau pasif).
  - Tambah durasi/cooldown dan integrasi dengan GameManager (supaya tersimpan jika perlu).
  - UI: icon per power, timer jika efek sementara.

---

## 5. Integrasi Shop → Gameplay

### 5.1. Penyimpanan Data Power di Save File

- Perlu format yang jelas di `user://save.cfg`, misalnya di section `powerups`:
  - Counter untuk power 1-run: `shield_1hit_charges`, `double_coins_run_tokens`, `extra_heart_run_tokens`.
  - Nilai upgrade permanen: `max_heart_bonus`, `magnet_duration_multiplier`, `shield_duration_multiplier`, `pickup_range_bonus`.
- Shop:
  - Saat pembelian:
    - Selain mengurangi coins, update nilai di section `powerups`.
    - Simpan file.

### 5.2. Pemakaian Power Saat Run Dimulai

- Di GameManager saat memulai run:
  - Baca data `powerups` dari save.
  - Terapkan ke Player dan variabel internal.
  - Untuk power 1-run:
    - Kurangi stok/charge dari save.
    - Simpan ulang supaya item dianggap sudah terpakai.

### 5.3. Sinkronisasi dengan UI

- Tambah icon/label di HUD untuk:
  - Magnet (sudah ada).
  - Shield.
  - Double coins.
  - Extra heart (opsional, bisa cukup lewat health bar yang lebih panjang).
- Pastikan semua icon hanya membaca state dari GameManager/Player, tidak mengubah logika.

---

## 6. Prioritas Implementasi

Urutan kerja yang praktis untuk power pada gameplay player:

1. Rapikan framework data power di GameManager dan save file.
2. Integrasi Shop u0010 save u0010 konsumsi power 1-run saat run dimulai.
3. Finalisasi dan pemolesan magnet (durasi, efek visual, balancing radius/speed).
4. Implementasi shield 1 hit dan efek visual/audio-nya.
5. Implementasi double coins run dan indikator di HUD.
6. Integrasi extra heart (run-scope + upgrade permanen max health).
7. Jadikan double jump sebagai power (opsional, berbasis `air_jumps`).
8. Desain dan implementasi awal untuk dash/slow motion/giant/ghost phase.

Dengan daftar ini, semua power yang sudah direncanakan di dokumen desain bisa
diarahkan secara bertahap ke implementasi konkret dalam gameplay player.

---

## 7. TODO Detail Implementasi

### 7.1. Framework Data Power

- Tambah section `powerups` di `user://save.cfg` untuk menyimpan:
  - Counter 1-run: `shield_1hit_charges`, `double_coins_run_tokens`, `extra_heart_run_tokens`.
  - Upgrade permanen: `max_heart_bonus`, `magnet_duration_multiplier`, `shield_duration_multiplier`, `pickup_range_bonus`.
- Di `game_manager.gd`:
  - Tambah variabel runtime yang membaca nilai dari `powerups` saat load.
  - Pastikan `_save_progress()` menyimpan kembali `powerups` dengan aman.

### 7.2. Integrasi Shop → Save

- Di `ShopMenu.gd`:
  - Saat pembelian power 1-run:
    - Tambah atau increment counter di `powerups` (bukan hanya kurangi `total_coins`).
  - Saat pembelian upgrade permanen:
    - Update nilai multiplier/bonus di `powerups`.
  - Pastikan error handling jika `save.cfg` belum punya section `powerups`.

### 7.3. Start Run: Apply Power ke Gameplay

- Di flow start run GameManager:
  - Baca data `powerups` dan tentukan:
    - Berapa shield charge dipakai di run ini.
    - Apakah `double_coins_run` aktif.
    - Berapa extra heart untuk run ini.
    - Berapa multiplier durasi magnet.
  - Kirim nilai yang relevan ke Player (health, shield, air jump).
  - Simpan kembali `powerups` jika stok 1-run berkurang.

### 7.4. Implementasi Shield 1 Hit

- Tambah state shield di Player atau GameManager:
  - `shield_charges_run` dan/atau flag `shield_active`.
- Di alur damage/hit player:
  - Jika shield aktif dan ada charge:
    - Kurangi charge.
    - Batalkan efek fatal (damage besar / game over).
    - Trigger efek visual dan audio "shield break".
  - Jika shield tidak ada: biarkan flow sekarang berjalan.
- Tambah icon HUD shield yang membaca state shield dari GameManager/Player.

### 7.5. Implementasi Double Coins Run

- Tambah flag `double_coins_run_active` di GameManager.
- Di tempat coin dikreditkan:
  - Jika flag aktif, kalikan jumlah coin (misalnya ×2).
- Tambah indikator HUD (icon atau label kecil "x2" dekat coin HUD).

### 7.6. Implementasi Extra Heart

- Hitung `effective_max_health = base_max_health + max_heart_bonus + extra_heart_run`.
- Set ke Player saat run dimulai:
  - `max_health` dan `starting_health` mengikuti nilai efektif.
- Pastikan HealthBar mengikuti `max_health` baru.

### 7.7. Double Jump sebagai Power

- Tentukan default `air_jumps` (misalnya 0) untuk run tanpa power.
- Saat power double jump aktif:
  - Set `air_jumps` ke nilai > 0 (misal 1) saat run dimulai.
- Opsional: variasi sementara dengan timer khusus.

### 7.8. Power Lain (Dash, Slow Motion, Giant, Ghost)

- Definisikan minimal 1 power tambahan (misalnya dash) sebagai implementasi pertama:
  - Tentukan input atau pemicu.
  - Tambah state dan timer di Player.
  - Sesuaikan animasi dan collision jika perlu.
- Tambah placeholder entry di `powerups` untuk power tersebut agar bisa di-extend dari Shop/XP.
