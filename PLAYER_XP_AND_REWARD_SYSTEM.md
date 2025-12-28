# Sistem XP Player dan Reward

Dokumen ini menjelaskan desain awal sistem XP, level, dan reward untuk pemain di Anomaly Rush.

Tujuannya:
- Memberi rasa progres jangka panjang di luar skor dan coin.
- Menjadi fondasi untuk fitur hadiah harian, skin, dan power-up khusus.
- Tetap sederhana untuk versi awal, tapi mudah di-extend.

## 1. Data yang Disimpan

Semua data disimpan di `user://save.cfg` bagian `progress`:

- `player_level` (int, default `1`)
  - Level pemain saat ini.
- `player_xp` (int, default `0`)
  - XP yang sudah terkumpul di level saat ini.
- `player_xp_required` (int, default `100`)
  - Total XP yang dibutuhkan untuk naik dari level saat ini ke level berikutnya.

Contoh isi `save.cfg` (bagian progres):

```ini
[progress]
best_score=1200
last_score=800
last_coins=45
total_coins=630
player_level=3
player_xp=40
player_xp_required=150
```

## 2. Sumber XP

Sistem XP versi awal mengambil XP dari beberapa sumber utama:

- **Jarak tempuh run**
  - Tiap X meter jarak yang ditempuh player memberi Y XP.
  - Contoh awal: `1 XP` per `50m` jarak.
- **Coin yang dikumpulkan**
  - Tiap coin yang diambil memberi XP kecil.
  - Contoh awal: `1 XP` per `5 coin`.
- **Misi harian / missions**
  - Misi yang selesai memberi XP bonus.
  - Contoh awal: `+20 XP` setiap misi yang complete.
- **Event khusus / reward iklan** (opsional, future)
  - Menyelesaikan event tertentu atau menonton iklan rewarded bisa memberi XP tambahan.

Konversi jarak/coin ke XP bisa diatur lewat konstanta di `game_manager.gd` (TODO implementasi),
misalnya:

- `xp_per_meter`
- `xp_per_coin`
- `xp_per_mission_completed`

## 3. Rumus Level dan XP Required

Rumus sederhana dan mudah dibaca untuk versi awal:

- `player_xp_required(level) = base_xp + (level - 1) * xp_step`

Contoh angka:

- `base_xp = 100`
- `xp_step = 25`

Sehingga:

- Level 1 → 2: `100 XP`
- Level 2 → 3: `125 XP`
- Level 3 → 4: `150 XP`
- Level 4 → 5: `175 XP`, dst.

Keuntungan:
- Pola linear, gampang di-balance.
- Bisa diganti ke rumus non-linear (misal kuadratik) jika butuh progres lebih panjang.

## 4. Flow Update XP dan Level-Up

Secara garis besar, update XP terjadi di akhir run dan/atau saat event tertentu:

1. **Selama run**
   - `game_manager.gd` menghitung jarak (`distance`) dan coin yang diambil.
   - Missions menerima update distance/coins melalui `MissionsManager.gd`.

2. **Saat game over**
   - Hitung XP yang didapat run ini:
     - `xp_from_distance = floor(distance * xp_per_meter)`
     - `xp_from_coins = floor(total_coins_run / coins_per_xp)`
     - `xp_from_missions = missions_xp_bonus`
   - Total XP run:
     - `xp_gain = xp_from_distance + xp_from_coins + xp_from_missions`

3. **Tambahkan ke progres pemain**
   - `player_xp += xp_gain`.
   - Selama `player_xp >= player_xp_required`:
     - `player_xp -= player_xp_required`.
     - `player_level += 1`.
     - Hitung `player_xp_required` baru berdasarkan rumus di atas.
     - Tandai bahwa terjadi **level-up** (dipakai untuk animasi dan reward).

4. **Simpan ke save file**
   - Set nilai baru `player_level`, `player_xp`, `player_xp_required` ke `ConfigFile`.
   - `cfg.save("user://save.cfg")` dipanggil bersama data progres lain.

## 5. Integrasi dengan UI (PlayerHUD)

Main Menu sudah memiliki HUD player di kiri atas (`PlayerHUD`):

- `AvatarIcon` – menampilkan icon/avatar player.
- `LevelLabel` – menampilkan teks `Lv X`.
- `XPBar` – progress bar XP saat ini.
- `XPLabel` – teks `current_xp/required_xp XP`.
- `RewardIcon` – icon hadiah berikutnya atau indikator reward siap di-claim.

Saat `MainMenu.tscn` dibuka, `MainMenu.gd` melakukan:

- Membaca `player_level`, `player_xp`, `player_xp_required` dari `user://save.cfg`.
- Mengisi `LevelLabel`, `XPBar`, dan `XPLabel` sesuai nilai terakhir.
- `RewardIcon` bisa dipakai untuk highlight jika ada reward level-up yang belum diambil.

## 6. Sistem Reward

Reward di sini adalah hadiah yang pemain terima saat mencapai level tertentu
atau mengisi XP sampai penuh beberapa kali.

### 6.1 Tipe Reward

Beberapa kategori reward yang disarankan:

- **Currency**
  - Tambahan `total_coins` (misal +50, +100, +200, dst.).
- **Kustomisasi**
  - Skin karakter, trail efek lari, warna UI.
- **Power-Up Unlock**
  - Membuka skill baru (magnet, shield, dash) atau menaikkan durasi/efeknya.
- **Quality-of-Life** (opsional)
  - Slot misi harian lebih banyak, bonus coin di akhir run, dsb.

### 6.2 Pola Reward per Level

Contoh tabel sederhana (bisa diubah nanti):

| Level | Reward Utama             |
|-------|--------------------------|
| 2     | +50 coins                |
| 3     | +100 coins               |
| 4     | Unlock skin basic        |
| 5     | +150 coins               |
| 6     | Upgrade durasi magnet    |
| 7     | +200 coins               |
| 8     | Unlock trail efek dasar  |

Implementasi tabel ini bisa dilakukan di script (misal di `game_manager.gd`
atau modul terpisah `XPRewardManager.gd`) dalam bentuk array/dictionary.

### 6.3 Claim Reward

Alur claim reward yang disarankan:

1. Saat level-up terjadi di akhir run:
   - Tambahkan entry reward pending, misalnya di `save.cfg`:
     - `pending_level_rewards = [2,4,6]` (contoh level yang punya reward belum di-claim).

2. Di Main Menu:
   - `MainMenu.gd` membaca `pending_level_rewards`.
   - Jika tidak kosong, **nyalakan highlight** pada `RewardIcon` di `PlayerHUD`.
   - Tekan `RewardIcon` (atau tombol lain di UI) membuka panel reward.

3. Saat pemain menekan tombol *Claim*:
   - Terapkan efek reward (tambah coins, unlock skin, dsb.).
   - Hapus level terkait dari `pending_level_rewards`.
   - Simpan ulang `save.cfg`.

## 7. Roadmap Implementasi

Urutan kerja yang disarankan untuk mengaktifkan sistem ini sepenuhnya:

1. **Implementasi perhitungan XP di `game_manager.gd`**
   - Tambah variabel export/konstanta untuk `xp_per_meter`, `xp_per_coin`, `xp_per_mission_completed`.
   - Hitung `xp_gain` di akhir run dan update `player_level`, `player_xp`, `player_xp_required`.
   - Simpan ke `save.cfg` bersama progres lain.

2. **Tambah modul pengelola reward**
   - Buat fungsi yang menerima `old_level` dan `new_level`, lalu mengembalikan list reward.
   - Simpan reward pending di save file.

3. **Integrasi UI di Main Menu**
   - Sambungkan `RewardIcon` dengan panel kecil yang menampilkan reward pending.
   - Tampilkan animasi/efek kecil saat ada reward baru.

4. **Balancing dan Playtest**
   - Tes beberapa run pendek untuk memastikan XP naik dengan kecepatan yang terasa pas.
   - Koreksi `base_xp`, `xp_step`, dan nilai reward agar progres terasa rewarding tapi tidak terlalu cepat.

