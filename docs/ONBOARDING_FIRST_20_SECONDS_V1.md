# Onboarding 20 Detik Pertama v1

Date: 2026-03-07
Owner: UX + Gameplay + UI
Scope: Main gameplay flow 0-20 detik pertama untuk pemain baru

## Tujuan

- Mengurangi kebingungan pemain baru pada run pertama.
- Meningkatkan peluang pemain memahami kontrol inti sebelum gagal.
- Menjelaskan value loop: lompat -> hindari rintangan -> kumpulkan coin -> belanja di Shop.

## Ringkasan Experience Target (0-20 detik)

- Detik 0-3: pemain melihat hint `Tap untuk lompat`.
- Detik 4-8: pemain melihat hint `Hindari rintangan`.
- Detik 9-14: pemain melihat hint `Kumpulkan coin untuk Shop`.
- Detik 15-20: hint terakhir fade out, gameplay lanjut normal tanpa gangguan.

## Konsep Visual Final (Diskusi Disepakati)

- Onboarding tampil sebagai overlay di scene gameplay yang sama, tanpa pindah scene baru.
- Layar diberi layer hitam transparan ringan (`alpha` sekitar `0.25-0.32`) agar fokus ke petunjuk.
- Area input utama (zona tap/jump) diberi spotlight agar pemain tahu titik interaksi.
- Dunia belakang diberi efek slowmo singkat pada step awal (target `0.55x-0.70x`) lalu kembali normal.
- Tambahkan indikator visual: ikon jari tap dan/atau panah pendek ke area input.
- Tutorial bersifat non-blocking: pemain tetap bisa bergerak dan langsung praktik.

## Definisi Selesai (Definition of Done)

- Tiga hint tampil berurutan maksimal sekali per akun/player profile.
- Hint tidak tampil saat pause, game over, atau continue offer.
- Hint mengikuti safe-area landscape dan tidak overlap HUD kritikal.
- Overlay gelap, spotlight, ikon jari/panah, dan slowmo step awal aktif sesuai desain.
- Semua teks onboarding menggunakan `tr("KEY")` dan tersedia di ID/EN/ZH.
- Ada flag save agar onboarding tidak muncul lagi setelah selesai.
- Lulus sanity + smoke + boot scene utama.

## Status Fitur Saat Ini

### Sudah Selesai

- Core loop endless runner stabil (run, obstacle, score, game over, retry).
- HUD currency dan Shop flow coin/gems aktif.
- Missions, season rewards, dan profile cosmetics sudah berjalan.
- Responsiveness landscape + safe-area untuk Main Menu, Shop, Skill Progress sudah dirapikan.

### Belum Selesai (Khusus Onboarding 20 Detik)

- Sistem sequencing hint 3 tahap belum ada.
- Persistensi state onboarding (`sudah selesai`/`belum`) belum ada.
- Trigger kondisi `first run only` belum ada.
- Lokalisasi key onboarding belum ditambahkan ke seluruh bahasa.
- QA checklist khusus onboarding belum ditambahkan.

## Rencana Implementasi Step-by-Step

1. Tambah state onboarding runtime di `game_manager.gd`.
2. Tambah node UI hint overlay di scene gameplay (`Control` + layer gelap + label + ikon jari/panah).
3. Buat scheduler timeline 0-20 detik berbasis waktu run aktif.
4. Tambah spotlight area input jump dan positioning aman safe-area.
5. Integrasikan slowmo singkat di step pertama lalu restore ke speed normal.
6. Pasang guard state (pause, game over, continue, ad flow).
7. Simpan flag completion ke save (`user://save.cfg` via GameManager domain settings/profile).
8. Tambah key terjemahan:
   - `ONBOARD_TAP_JUMP`
   - `ONBOARD_AVOID_OBSTACLE`
   - `ONBOARD_COINS_FOR_SHOP`
9. Integrasi style visual:
   - Font readable, outline cukup, aman di 1024x576.
   - Fade-in/out halus (tidak ganggu kontrol).
10. Tambah coverage smoke test untuk validasi muncul-sekali.
11. Tambah checklist QA manual untuk verifikasi device low-mid Android.

## Rincian Teknis yang Direkomendasikan

### Event dan State

- State minimum:
  - `onboarding_enabled: bool`
  - `onboarding_completed: bool`
  - `onboarding_step: int`
  - `onboarding_elapsed: float`
  - `onboarding_slowmo_active: bool`
- State visual minimum:
  - `overlay_alpha: float`
  - `spotlight_target_rect: Rect2`
  - `hint_indicator_mode: String` (`finger` / `arrow`)
- Event masuk:
  - `set_playing_phase()` memulai timer onboarding jika eligible.
- Event keluar:
  - timer selesai 20 detik -> set completed true -> persist save.

### Rule Eligibility

- Eligible jika:
  - profile baru atau flag onboarding belum selesai.
  - gameplay phase `PLAYING`.
- Tidak eligible jika:
  - phase `GAME_OVER`
  - pause aktif
  - run sedang dalam flow continue/rewarded yang menutup UI utama.

### Integrasi Save

- Simpan di domain settings/profile:
  - `onboarding_first20_completed = true|false`
- Backward compatible:
  - jika key tidak ada, default `false`.

## Risiko dan Mitigasi

- Risiko: hint nutup HUD penting.
  - Mitigasi: anchor top-center dengan margin safe-area.
- Risiko: muncul ulang berkali-kali.
  - Mitigasi: persist flag completion + write-through save setelah selesai.
- Risiko: bentrok dengan popup lain.
  - Mitigasi: auto-hide onboarding saat popup blocking aktif.

## Checklist QA Onboarding

- Fresh install -> hint 1/2/3 tampil urut.
- Relaunch setelah selesai -> hint tidak muncul lagi.
- Force close di tengah onboarding -> resume behavior sesuai desain (lanjut atau restart step 1).
- Pause/resume tidak mempercepat timeline secara salah.
- Game over sebelum detik 20 -> tidak crash, state konsisten.
- Continue via ad -> hint tidak overlap menu continue/game over.
- Landscape 1024x576, 1280x720, 1560x720, 1920x1080 lolos visual.

## Catatan untuk Agentic Berikutnya

- Prioritas eksekusi: `runtime state -> UI overlay -> save flag -> i18n -> smoke/QA`.
- Gunakan overlay di scene gameplay yang sama, jangan membuat transisi scene tutorial terpisah untuk fase ini.
- Jangan ubah loop gameplay inti saat menambah onboarding.
- Fokus perubahan hanya di layer guidance pemain baru, bukan balancing ekonomi.
