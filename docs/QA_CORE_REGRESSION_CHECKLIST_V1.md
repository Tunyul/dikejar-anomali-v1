# QA Core Regression Checklist v1

Date: 2026-03-05
Tester target: Non-programmer QA
Build target: Android internal QA build

## How to use
- Mark each case: `PASS` / `FAIL`
- Jika `FAIL`, lampirkan video + timestamp + device + langkah repro.
- Jalankan checklist ini minimal 1x per build harian.

## Automated Preflight (Wajib Sebelum Test Manual)
Jalankan dari root project:
- `godot --headless --path . --script res://scripts/tools/sanity_check.gd`
- `godot --headless --path . --script res://scripts/smoke_check_runner.gd`

Expected:
- `sanity_check`: `--- Check Passed: No errors found ---`
- `smoke_check_runner`: `SMOKE_CHECK_OK`

## Device and Build Info
- Device:
- OS Version:
- Build Version:
- Tester:
- Date:

## Core Loop and Stability
1. Start run normal -> play -> game over -> restart.
2. Start run -> game over -> return menu -> start run lagi.
3. Pause saat playing -> resume -> flow tetap normal.
4. Minimize app saat playing -> restore -> state konsisten (tidak stuck).
5. 30 run berturut-turut tanpa soft-lock.

## Rewarded Continue
6. Rewarded continue sukses hanya 1x per run.
7. Rewarded continue cancel/fail tidak memberi benefit.
8. Rewarded continue saat ad tidak siap: game flow tidak freeze.
9. Continue tidak bisa dieksploitasi untuk nyawa tak terbatas.

## IAP and Shop
10. IAP sukses memberi grant tepat 1x.
11. IAP pending/cancel/fail tidak memberi grant.
12. Restore purchase tidak men-duplicate grant.
13. Item coming-soon tidak bisa dibeli.
14. Daily claim gratis pertama sukses.
15. Daily claim ad-gated sukses saat ad tersedia.
16. Claim reward tidak bisa dobel setelah relaunch.

## Missions and Rewards
17. Mission progress sesuai aksi collect/jump/survive/use powerup.
18. Claim mission tidak dobel walau spam tap.
19. Season reward lock/unlock sesuai level.
20. Claim all season reward tidak dobel.

## Save, Migration, Offline
21. Force close setelah claim -> relaunch -> progress konsisten.
22. Save lama termigrasi ke schema v3 tanpa data loss.
23. Offline mode: gameplay tetap jalan, online features fallback aman.

## Performance
24. Soak test 30 menit tanpa leak signifikan.
25. FPS stabil pada device low-mid target.

## Result Summary
- Total PASS:
- Total FAIL:
- Blocker (P0):
- Recommendation: `GO` / `NO-GO`
