# Baseline Tuning v1 (Frozen)

Date: 2026-03-05
Scope: Endless runner core loop, spawn, reward, economy, progression.

## 1. Gameplay Speed and Difficulty
- Base speed: `180.0`
- Max speed: `360.0`
- Speed gain per meter: `0.015`
- Enemy ramp enabled: `true`
- Enemy ramp start distance: `400.0`
- Countdown duration: `3.0`

Difficulty profile runtime defaults:
- Window `20s`: enemy weight `1.0`, speed mult `1.0`, spawn interval `1.0`
- Window `45s`: enemy weight `1.2`, speed mult `1.05`, spawn interval `0.95`
- Window `75s`: enemy weight `1.35`, speed mult `1.1`, spawn interval `0.88`
- Window `105s`: enemy weight `1.5`, speed mult `1.15`, spawn interval `0.8`

Anomaly event baseline:
- Enabled: `true`
- Interval: `22.0s`
- Duration: `6.0s`
- Speed shift multiplier: `1.15`
- Gravity shift multiplier: `1.2`

Daily challenge rotation baseline:
- `standard`: speed `1.0`, xp `1.0`, coin bonus `0%`
- `swift_chase`: speed `1.08`, xp `1.10`, coin bonus `0%`
- `treasure_wave`: speed `1.0`, xp `1.0`, coin bonus `20%`
- `survival_drill`: speed `1.05`, xp `1.12`, coin bonus `10%`

## 2. Spawn Baseline
Infinite ground spawn defaults:
- Coin spawn chance: `1.0`
- Enemy spawn chance: `0.3`
- Enemy block weight: `1.0`
- Enemy cone weight: `1.0`

Spawn safety policy:
- Ground/enemy/coin generation uses emergency and min-density safeguards (`_ensure_min_spawn_density`, emergency spawn requests from `GameManager`).
- Run should not enter long empty segments without collectible/obstacle coverage.

## 3. XP and Progression Baseline
- XP per meter: `0.02`
- XP per collected coin: `0.2`
- XP required formula:
  - `base = 100`
  - `required(level) = 100 + (level-1)*30 + round(pow(level-1, 1.35)*9.0)`

## 4. Reward and Currency Integrity Baseline
- Save schema: `v3`
- Reward anti-duplicate ledger enabled (`reward_grant_ledger`, max entries `512`)
- Monetization counters persisted (`rewarded_request_count`, `purchase_success_count`, `last_rewarded_unix`)
- Continue rollback uses granted totals, not only collected values.

## 5. Shop and Economy Baseline
Daily claim:
- Min coins: `100`
- Max coins: `500`
- First claim free, next claim same day ad-gated.

Core consumables (coins):
- Magnet 30s: `150`
- Shield 1 hit: `200`
- Double coins run: `250`
- Speed boost run: `200`

IAP catalog (single source of truth):
- `gems_small`: Rp 15.000 -> 100 gems
- `gems_standard`: Rp 45.000 -> 330 gems
- `gems_big`: Rp 99.000 -> 950 gems
- `gems_mega`: Rp 199.000 -> 2500 gems
- `starter_bundle`: Rp 29.000 -> 1000 coins + 100 gems + utility powerups
- `progress_bundle`: Rp 59.000 -> 2500 coins + 250 gems + utility powerups
- `cosmetic_bundle`: Rp 49.000 -> 1500 coins + 200 gems + utility powerups

## 6. Monetization Flow Baseline
- Rewarded continue uses guarded flow (eligible state + in-flight lock + one grant per offer serial).
- Purchase real-money grants only after billing callback status `success`/`restored` and grant ledger check.
- Purchase statuses handled: `success`, `pending`, `cancelled`, `failed`, `restored`.
