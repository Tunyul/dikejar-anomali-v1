# XP, Missions, Reward – Langkah Implementasi (per 1.3.26-beta)

## Tahap 1 – Konsolidasi XP Gain (SELESAI)

- [x] Pastikan variabel XP dasar ada di `game_manager.gd` (`xp_per_meter`, `xp_per_coin`).
- [x] Hitung XP di `on_player_game_over` dari jarak dan coins.
- [x] Terapkan `_apply_xp_gain` untuk update `player_level`, `player_xp`, `player_xp_required`.
- [x] Simpan nilai XP dan level ke `user://save.cfg` di section `progress`.
- [x] Tampilkan level dan XP terakhir di `MainMenu.gd` lewat `PlayerHUD` (LevelLabel, XPBar, XPLabel).

## Tahap 2 – Pending Level Rewards (SELESAI)

- [x] Tambah struktur data reward per level (minimal: currency/coins) di kode.
- [x] Tambah fungsi utilitas untuk menghitung reward list dari `old_level` → `new_level`.
- [x] Tambah penyimpanan `pending_level_rewards` ke `user://save.cfg` saat level-up.
- [x] Tambah loader `pending_level_rewards` di Main Menu.
- [x] Jadikan `RewardIcon` di `PlayerHUD` indikator ada/tidaknya reward pending (highlight/toggle).
- [x] Siapkan panel sederhana untuk menampilkan daftar reward pending dan tombol Claim.
- [x] Saat Claim ditekan: terapkan efek reward (coins) dan kosongkan/kurangi `pending_level_rewards` lalu simpan.

## Tahap 3 – Missions UI di Main Menu (SELESAI)

- [x] Review `MissionsManager.gd` dan struktur data `missions` di save.
- [x] Pastikan update `add_coins` dan `update_distance` terpanggil dari `game_manager.gd` (sudah aktif).
- [x] Gunakan panel misi di `MainMenu.tscn` (slot Mission1..3) sebagai tampilan 1–3 misi aktif.
- [x] Tambah logika di `MainMenu.gd` untuk memetakan data `missions` ke panel misi (nama, progress bar).
- [x] Tambah indikator kecil di Main Menu bila ada misi selesai tapi reward belum diambil (opsional, lewat XP/reward atau coins bonus).

## Tahap 4 – Sinkronisasi Missions dengan Reward System

- [ ] Tambah XP bonus dari misi completed ke perhitungan XP gain.
- [x] Tambah mekanisme reward khusus misi (coins ekstra) lewat field `reward` di masing-masing entry misi dan tombol Claim di UI.
- [x] Simpan status misi completed/claimed dengan rapi di section `missions` (`missions/reward_claimed`).

## Tahap 5 – Balancing Awal

- [ ] Uji beberapa run pendek dan catat rata-rata XP gain, tempo level-up, dan jumlah coins.
- [ ] Sesuaikan `xp_per_meter`, `xp_per_coin`, dan tabel reward per level agar progres terasa wajar.
- [ ] Dokumentasikan angka final sementara di dokumen desain XP.
