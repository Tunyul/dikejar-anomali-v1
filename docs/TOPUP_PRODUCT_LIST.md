# Topup Product List

Dokumen ini merangkum item yang saat ini layak dianggap sebagai produk topup real-money untuk web dan Google Play.

Source of truth utama:

- `scripts/data/ShopCatalog.gd`
- `docs/BASELINE_TUNING_V1.md`

## Produk yang Bisa Ditopup

| Product ID | Nama Produk | Kategori | Harga | Grant | Catatan |
| --- | --- | --- | --- | --- | --- |
| `gems_small` | Gems Small Pack | Gems | Rp 15.000 | 100 gems | Paket kecil untuk kebutuhan mendesak. |
| `gems_standard` | Gems Standard Pack | Gems | Rp 45.000 | 330 gems | Paket standar dengan bonus gems 10%. |
| `gems_big` | Gems Big Pack | Gems | Rp 99.000 | 950 gems | Paket besar dengan bonus gems lebih tinggi. |
| `gems_mega` | Gems Mega Pack | Gems | Rp 199.000 | 2500 gems | Paket terbesar, cocok untuk spender besar. |
| `starter_bundle` | Starter Bundle | Bundle | Rp 29.000 | 1000 coins, 100 gems, 2 magnet tokens, 1 shield charge, 1 double-coins token | Bundle entry-level untuk pemain baru. |
| `progress_bundle` | Progress Bundle | Bundle | Rp 59.000 | 2500 coins, 250 gems, 3 magnet tokens, 2 shield charges, 2 double-coins tokens | Bundle percepatan progres. |
| `cosmetic_bundle` | Cosmetic Bundle | Bundle | Rp 49.000 | 1500 coins, 200 gems, 2 shield charges | Bundle hemat untuk kebutuhan kosmetik. |

## Rekomendasi untuk Web Topup Tahap 1

Jika ingin mulai sederhana, cukup tampilkan 7 produk ini di website:

1. `gems_small`
2. `gems_standard`
3. `gems_big`
4. `gems_mega`
5. `starter_bundle`
6. `progress_bundle`
7. `cosmetic_bundle`

Alasannya:

- Semua sudah punya `real_product_id`.
- Semua sudah punya harga dan grant yang jelas.
- Semua sudah muncul sebagai katalog IAP real-money di project.

## Item yang Bukan Produk Topup Real-Money

Item berikut jangan dimasukkan ke halaman topup web karena dibeli dengan currency in-game, bukan uang asli:

- Upgrade skill/power-up berbasis coins
- Upgrade berbasis gems
- Cosmetic berbasis coins atau gems
- Coin exchange dari gems ke coins
- Reward harian, reward misi, dan grant gameplay

## Format Data yang Disarankan untuk Frontend Web

```json
[
  {
    "id": "gems_small",
    "name": "Gems Small Pack",
    "category": "gems",
    "price_amount": 15000,
    "currency": "IDR",
    "grants": {
      "coins": 0,
      "gems": 100,
      "powerups": {}
    }
  }
]
```

## Catatan Implementasi

- Untuk web topup, sebaiknya `product_id` tetap sama dengan katalog game agar mapping grant sederhana.
- Grant tetap harus diproses di backend, bukan di frontend web atau client game.
- Jika nanti ada produk baru, update dokumen ini dan `ShopCatalog.gd` bersamaan.
