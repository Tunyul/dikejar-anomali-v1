# Bug Priority Matrix v1

Date: 2026-03-05
Owner: Core gameplay + monetization team

## Priority Definition
- `P0 (Blocker)`: Core loop tidak bisa selesai, data/progress corrupt/hilang, purchase/reward grant salah, crash/hang.
- `P1 (Major)`: Fitur utama berjalan tapi banyak gangguan signifikan (state mismatch, reward miss, balancing parah).
- `P2 (Minor)`: Visual polish, teks, UX kecil, edge-case non-blocking.

## Current Matrix
| ID | Priority | Area | Symptom | Repro | Expected | Owner | Status |
|---|---|---|---|---|---|---|---|
| CORE-001 | P0 | Core loop/state | Soft-lock transisi run (entry/countdown/playing/game_over) | 30 run berturut | Selalu bisa restart/continue/menu | Gameplay | Open |
| SAVE-001 | P0 | Save/load | Progress currency/reward hilang atau dobel setelah relaunch | Claim -> force close -> relaunch | Nilai konsisten | Systems | Open |
| MON-001 | P0 | Rewarded continue | Continue bisa digrant lebih dari 1x per offer | Tap cepat/close-open ad | Maks 1 grant per offer serial | Monetization | Open |
| MON-002 | P0 | IAP | Item tergrant walau purchase cancel/fail | Cancel/failed purchase | Tidak ada grant | Monetization | Open |
| ECO-001 | P1 | Economy curve | Leveling terlalu cepat/lambat vs durasi run | 20 run mixed skill | XP curve smooth | Design | Open |
| MIS-001 | P1 | Mission sync | Progress mission miss/hit dobel | Collect/jump/survive actions | Increment tepat | Systems | Open |
| UX-001 | P2 | Shop clarity | User bingung efek item/upgrade | Fresh user walkthrough | Efek & next benefit jelas | UI/UX | Open |

## Triage Rules
- P0 wajib di-fix sebelum release candidate.
- P1 bisa dibawa ke RC hanya jika ada mitigasi jelas dan tidak mengganggu monetisasi/data integrity.
- P2 boleh defer ke patch minor setelah rilis stabil.

## Exit Criteria (Build QA)
- Tidak ada P0 tersisa.
- P1 tersisa maksimal 2 item dan punya workaround jelas.
- Semua test case inti (core loop + monetisasi + save/load) pass.
