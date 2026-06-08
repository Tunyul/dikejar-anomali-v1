# Anomaly Rush! - Product Catalog (Source of Truth)

**Version**: 1.3.57-beta
**Last Updated**: 2026-04-12
**Purpose**: Official product catalog for Web Top-up Portal integration

---

## Currency Products

### Gems (Premium Currency)

| Field | Value |
|-------|-------|
| **product_id** | `gems_5` |
| **name** | 5 Gems |
| **price_id** | `price_gems_5_idr` (to be configured in payment gateway) |
| **grant_data** | `{ "currency": "gems", "amount": 5 }` |
| **icon_asset_path** | `res://assets/diamond_animation/diamond-1024x1024.png` |
| **display_price_idr** | 15000 |
| **bonus** | None |

---

| Field | Value |
|-------|-------|
| **product_id** | `gems_15` |
| **name** | 15 Gems |
| **price_id** | `price_gems_15_idr` |
| **grant_data** | `{ "currency": "gems", "amount": 15 }` |
| **icon_asset_path** | `res://assets/diamond_animation/diamond-1024x1024.png` |
| **display_price_idr** | 40000 |
| **bonus** | +2 bonus gems (total 17) |

---

| Field | Value |
|-------|-------|
| **product_id** | `gems_30` |
| **name** | 30 Gems |
| **price_id** | `price_gems_30_idr` |
| **grant_data** | `{ "currency": "gems", "amount": 30 }` |
| **icon_asset_path** | `res://assets/diamond_animation/diamond-1024x1024.png` |
| **display_price_idr** | 75000 |
| **bonus** | +5 bonus gems (total 35) |

---

| Field | Value |
|-------|-------|
| **product_id** | `gems_60` |
| **name** | 60 Gems |
| **price_id** | `price_gems_60_idr` |
| **grant_data** | `{ "currency": "gems", "amount": 60 }` |
| **icon_asset_path** | `res://assets/diamond_animation/diamond-1024x1024.png` |
| **display_price_idr** | 140000 |
| **bonus** | +10 bonus gems (total 70) |

---

| Field | Value |
|-------|-------|
| **product_id** | `gems_120` |
| **name** | 120 Gems (Best Value) |
| **price_id** | `price_gems_120_idr` |
| **grant_data** | `{ "currency": "gems", "amount": 120 }` |
| **icon_asset_path** | `res://assets/diamond_animation/diamond-1024x1024.png` |
| **display_price_idr** | 270000 |
| **bonus** | +25 bonus gems (total 145) |
| **badge** | "Best Value" |

---

### Coins (Soft Currency)

| Field | Value |
|-------|-------|
| **product_id** | `coins_500` |
| **name** | 500 Coins |
| **price_id** | `price_coins_500_idr` |
| **grant_data** | `{ "currency": "coins", "amount": 500 }` |
| **icon_asset_path** | `res://assets/coin_animation/coin-1024x1024.png` |
| **display_price_idr** | 10000 |
| **bonus** | None |

---

| Field | Value |
|-------|-------|
| **product_id** | `coins_1500` |
| **name** | 1,500 Coins |
| **price_id** | `price_coins_1500_idr` |
| **grant_data** | `{ "currency": "coins", "amount": 1500 }` |
| **icon_asset_path** | `res://assets/coin_animation/coin-1024x1024.png` |
| **display_price_idr** | 25000 |
| **bonus** | +200 bonus coins (total 1,700) |

---

| Field | Value |
|-------|-------|
| **product_id** | `coins_5000` |
| **name** | 5,000 Coins |
| **price_id** | `price_coins_5000_idr` |
| **grant_data** | `{ "currency": "coins", "amount": 5000 }` |
| **icon_asset_path** | `res://assets/coin_animation/coin-1024x1024.png` |
| **display_price_idr** | 75000 |
| **bonus** | +1,000 bonus coins (total 6,000) |

---

## Bundle Products

### Starter Bundles

| Field | Value |
|-------|-------|
| **product_id** | `starter_bundle_basic` |
| **name** | Starter Pack - Basic |
| **price_id** | `price_starter_basic_idr` |
| **grant_data** | `{ "currency": "gems", "amount": 20 }, { "currency": "coins", "amount": 1000 }, { "item_id": "skin_basic", "type": "cosmetic" }` |
| **icon_asset_path** | `res://assets/icon/icon_gift_box_96x96.png` |
| **display_price_idr** | 35000 |
| **contents** | 20 Gems, 1,000 Coins, Basic Skin Unlock |
| **badge** | "New Player" |
| **limit** | One-time purchase per account |

---

| Field | Value |
|-------|-------|
| **product_id** | `starter_bundle_premium` |
| **name** | Starter Pack - Premium |
| **price_id** | `price_starter_premium_idr` |
| **grant_data** | `{ "currency": "gems", "amount": 50 }, { "currency": "coins", "amount": 3000 }, { "item_id": "skin_premium", "type": "cosmetic" }, { "powerup": "magnet_30s_tokens", "amount": 5 }` |
| **icon_asset_path** | `res://assets/icon/icon_gift_box_96x96.png` |
| **display_price_idr** | 85000 |
| **contents** | 50 Gems, 3,000 Coins, Premium Skin, 5 Magnet Tokens |
| **badge** | "Most Popular" |
| **limit** | One-time purchase per account |

---

### Power-up Bundles

| Field | Value |
|-------|-------|
| **product_id** | `bundle_magnet_pack` |
| **name** | Magnet Power Pack |
| **price_id** | `price_magnet_pack_idr` |
| **grant_data** | `{ "powerup": "magnet_30s_tokens", "amount": 10 }` |
| **icon_asset_path** | `res://assets/icon/icon_magnet_v1_96x96.png` |
| **display_price_idr** | 20000 |
| **contents** | 10 Magnet Tokens (30s each) |

---

| Field | Value |
|-------|-------|
| **product_id** | `bundle_shield_pack` |
| **name** | Shield Protection Pack |
| **price_id** | `price_shield_pack_idr` |
| **grant_data** | `{ "powerup": "shield_1hit_charges", "amount": 10 }` |
| **icon_asset_path** | `res://assets/icon/icon_shield.png` |
| **display_price_idr** | 20000 |
| **contents** | 10 Shield Charges (1-hit protection each) |

---

| Field | Value |
|-------|-------|
| **product_id** | `bundle_double_coins_pack` |
| **name** | Double Coins Pack |
| **price_id** | `price_double_coins_pack_idr` |
| **grant_data** | `{ "powerup": "double_coins_run_tokens", "amount": 10 }` |
| **icon_asset_path** | `res://assets/icon/icon_coinduble_96x96.png` |
| **display_price_idr** | 25000 |
| **contents** | 10 Double Coins Run Tokens |

---

| Field | Value |
|-------|-------|
| **product_id** | `bundle_speed_boost_pack` |
| **name** | Speed Boost Pack |
| **price_id** | `price_speed_boost_pack_idr` |
| **grant_data** | `{ "powerup": "speed_boost_tokens", "amount": 10 }` |
| **icon_asset_path** | `res://assets/icon/icon_boost_96x96.png` |
| **display_price_idr** | 25000 |
| **contents** | 10 Speed Boost Tokens |

---

| Field | Value |
|-------|-------|
| **product_id** | `bundle_power_ups_mega` |
| **name** | Mega Power-ups Bundle |
| **price_id** | `price_mega_powerups_idr` |
| **grant_data** | `{ "powerup": "magnet_30s_tokens", "amount": 5 }, { "powerup": "shield_1hit_charges", "amount": 5 }, { "powerup": "double_coins_run_tokens", "amount": 5 }, { "powerup": "speed_boost_tokens", "amount": 5 }` |
| **icon_asset_path** | `res://assets/icon/icon_gift_box_96x96.png` |
| **display_price_idr** | 60000 |
| **contents** | 5 tokens each of all power-ups |
| **badge** | "Value Pack" |

---

### Cosmetic Bundles

| Field | Value |
|-------|-------|
| **product_id** | `bundle_skin_explorer` |
| **name** | Explorer Collection |
| **price_id** | `price_skin_explorer_idr` |
| **grant_data** | `{ "item_id": "skin_cat_explorer", "type": "cosmetic" }, { "item_id": "border_nature", "type": "border" }` |
| **icon_asset_path** | `res://assets/profile/profile_cat_explorer.png` |
| **display_price_idr** | 45000 |
| **contents** | Cat Explorer Skin + Nature Border |

---

| Field | Value |
|-------|-------|
| **product_id** | `bundle_skin_hero` |
| **name** | Hero Collection |
| **price_id** | `price_skin_hero_idr` |
| **grant_data** | `{ "item_id": "skin_superhero_male", "type": "cosmetic" }, { "item_id": "skin_superhero_female", "type": "cosmetic" }, { "item_id": "border_gold_premium", "type": "border" }` |
| **icon_asset_path** | `res://assets/profile/profile_superhero_male.png` |
| **display_price_idr** | 75000 |
| **contents** | Male & Female Superhero Skins + Gold Premium Border |
| **badge** | "Limited" |

---

| Field | Value |
|-------|-------|
| **product_id** | `bundle_skin_fantasy` |
| **name** | Fantasy Legends Pack |
| **price_id** | `price_skin_fantasy_idr` |
| **grant_data** | `{ "item_id": "skin_wizard", "type": "cosmetic" }, { "item_id": "skin_dragon", "type": "cosmetic" }, { "item_id": "skin_witch", "type": "cosmetic" }, { "item_id": "border_kraken", "type": "border" }` |
| **icon_asset_path** | `res://assets/profile/profile_wizard.png` |
| **display_price_idr** | 95000 |
| **contents** | Wizard, Dragon, Witch Skins + Kraken Border |
| **badge** | "Exclusive" |

---

## Upgrade Products (Skill Progression)

### Duration Upgrades

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_magnet_duration_1` |
| **name** | Magnet Duration +10% |
| **price_id** | `price_upgrade_magnet_dur_1` |
| **grant_data** | `{ "upgrade": "magnet_duration_multiplier", "step": 0.1 }` |
| **icon_asset_path** | `res://assets/icon/icon_magnet_timer_96x96.png` |
| **display_price_idr** | 15000 |
| **effect** | Increases magnet duration by 10% (max 3.0x) |
| **stackable** | Yes, up to cap |

---

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_shield_duration_1` |
| **name** | Shield Duration +10% |
| **price_id** | `price_upgrade_shield_dur_1` |
| **grant_data** | `{ "upgrade": "shield_duration_multiplier", "step": 0.1 }` |
| **icon_asset_path** | `res://assets/icon/icon_shield.png` |
| **display_price_idr** | 15000 |
| **effect** | Increases shield duration by 10% (max 3.0x) |
| **stackable** | Yes, up to cap |

---

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_double_coins_duration_1` |
| **name** | Double Coins Duration +10% |
| **price_id** | `price_upgrade_dc_dur_1` |
| **grant_data** | `{ "upgrade": "double_coins_duration_multiplier", "step": 0.1 }` |
| **icon_asset_path** | `res://assets/icon/icon_coinduble_96x96.png` |
| **display_price_idr** | 18000 |
| **effect** | Increases double coins duration by 10% (max 3.0x) |
| **stackable** | Yes, up to cap |

---

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_speed_boost_duration_1` |
| **name** | Speed Boost Duration +10% |
| **price_id** | `price_upgrade_sb_dur_1` |
| **grant_data** | `{ "upgrade": "speed_boost_duration_multiplier", "step": 0.1 }` |
| **icon_asset_path** | `res://assets/icon/icon_boost_96x96.png` |
| **display_price_idr** | 18000 |
| **effect** | Increases speed boost duration by 10% (max 3.0x) |
| **stackable** | Yes, up to cap |

---

### Multiplier Upgrades

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_double_coins_gain_1` |
| **name** | Double Coins Gain +25% |
| **price_id** | `price_upgrade_dc_gain_1` |
| **grant_data** | `{ "upgrade": "double_coins_gain_multiplier", "step": 0.25 }` |
| **icon_asset_path** | `res://assets/icon/icon_coin_multiplier_96x96.png` |
| **display_price_idr** | 25000 |
| **effect** | Increases coin multiplier from 2.0x (max 5.0x) |
| **stackable** | Yes, up to cap |

---

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_speed_boost_multiplier_1` |
| **name** | Speed Boost Power +10% |
| **price_id** | `price_upgrade_sb_mult_1` |
| **grant_data** | `{ "upgrade": "speed_boost_multiplier_multiplier", "step": 0.1 }` |
| **icon_asset_path** | `res://assets/icon/icon_boost_96x96.png` |
| **display_price_idr** | 25000 |
| **effect** | Increases speed boost multiplier (max 2.5x) |
| **stackable** | Yes, up to cap |

---

### Capacity Upgrades

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_max_heart_1` |
| **name** | Max Heart +1 |
| **price_id** | `price_upgrade_heart_1` |
| **grant_data** | `{ "upgrade": "max_heart_bonus", "step": 1 }` |
| **icon_asset_path** | `res://assets/icon/icon_heart_96x96.png` |
| **display_price_idr** | 30000 |
| **effect** | Increases maximum health by 1 (max +10) |
| **stackable** | Yes, up to cap |

---

| Field | Value |
|-------|-------|
| **product_id** | `upgrade_pickup_range_1` |
| **name** | Pickup Range +1 Tile |
| **price_id** | `price_upgrade_pickup_1` |
| **grant_data** | `{ "upgrade": "pickup_range_bonus", "step": 1 }` |
| **icon_asset_path** | `res://assets/icon/icon_magnet_v1_96x96.png` |
| **display_price_idr** | 20000 |
| **effect** | Increases coin pickup range by 1 tile (max +8) |
| **stackable** | Yes, up to cap |

---

## Special Event Products

### Season Pass (Future Implementation)

| Field | Value |
|-------|-------|
| **product_id** | `season_pass_s1` |
| **name** | Season 1 Battle Pass |
| **price_id** | `price_season_s1_idr` |
| **grant_data** | `{ "season_id": 1, "tier": "premium", "rewards": "see_season_rewards_table" }` |
| **icon_asset_path** | `res://assets/icon/icon_season_pass_96x96.png` |
| **display_price_idr** | 120000 |
| **contents** | Access to premium season rewards track |
| **badge** | "Seasonal" |
| **availability** | Limited time (Season 1 only) |

---

## JSON Format (For API Integration)

```json
{
  "catalog_version": "1.3.57",
  "last_updated": "2026-04-12T00:00:00Z",
  "products": [
    {
      "product_id": "gems_5",
      "name": "5 Gems",
      "category": "currency",
      "currency_type": "gems",
      "base_amount": 5,
      "bonus_amount": 0,
      "total_amount": 5,
      "price_idr": 15000,
      "icon_asset_path": "res://assets/diamond_animation/diamond-1024x1024.png",
      "grant_data": {
        "currency": "gems",
        "amount": 5
      },
      "active": true,
      "purchase_limit": null
    },
    {
      "product_id": "gems_120",
      "name": "120 Gems (Best Value)",
      "category": "currency",
      "currency_type": "gems",
      "base_amount": 120,
      "bonus_amount": 25,
      "total_amount": 145,
      "price_idr": 270000,
      "icon_asset_path": "res://assets/diamond_animation/diamond-1024x1024.png",
      "grant_data": {
        "currency": "gems",
        "amount": 120
      },
      "active": true,
      "purchase_limit": null,
      "badge": "Best Value"
    },
    {
      "product_id": "starter_bundle_premium",
      "name": "Starter Pack - Premium",
      "category": "bundle",
      "price_idr": 85000,
      "icon_asset_path": "res://assets/icon/icon_gift_box_96x96.png",
      "grant_data": {
        "items": [
          {"currency": "gems", "amount": 50},
          {"currency": "coins", "amount": 3000},
          {"item_id": "skin_premium", "type": "cosmetic"},
          {"powerup": "magnet_30s_tokens", "amount": 5}
        ]
      },
      "active": true,
      "purchase_limit": "once_per_account",
      "badge": "Most Popular"
    }
  ]
}
```

---

## Important Notes for Web Developer

### Currency Types
- **gems**: Premium currency (diamond icon)
- **coins**: Soft currency (gold coin icon)

### Item Types
- **cosmetic**: Skins and borders stored in `cosmetics` section of save.cfg
- **powerup**: Consumable tokens stored in `powerups` section
- **upgrade**: Permanent stat multipliers stored in `powerups` section

### Purchase Limits
- `null`: No limit, can purchase multiple times
- `"once_per_account"`: One-time purchase only (tracked in save.cfg)
- `"daily"`: Once per day (reset at midnight server time)
- `"weekly"`: Once per week

### Grant Data Structure
The `grant_data` field tells your backend exactly what to add to the player's account. The game backend will parse this and update the appropriate sections in `save.cfg`.

### Icon Assets
All icon paths are relative to the Godot project root (`res://`). You'll need to export these PNG files to your web server's asset directory. See Section 3 for the complete export list.

### Price Configuration
`price_id` values are placeholders. You must configure actual price IDs in your payment gateway (Midtrans/Xendit/Airwallex) and update this catalog accordingly.

### Badge System
Display badges on product cards for better conversion:
- "Best Value": Highest gem/IDR ratio
- "Most Popular": Frequently purchased
- "New Player": Starter bundles
- "Limited": Time-limited offers
- "Exclusive": Rare/premium items
- "Value Pack": Bundle discounts
- "Seasonal": Event-related

---

## Validation Rules

1. **product_id must be unique** across all products
2. **product_id is permanent** - never change once published
3. **grant_data must be valid** JSON that matches game backend schema
4. **icon_asset_path must exist** in the Godot project
5. **price_idr must be positive** integer (Indonesian Rupiah)
6. **Active products only** should be shown in web portal (check `active: true`)

---

**End of Product Catalog**
