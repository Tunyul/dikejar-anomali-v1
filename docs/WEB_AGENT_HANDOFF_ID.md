# Web Agent Handoff

Dokumen ini dipakai untuk briefing agent fullstack web agar bisa langsung eksekusi tanpa banyak asumsi tambahan.

## 1. Tujuan

Bangun website resmi **Anomaly Rush** untuk:

- landing page brand
- halaman top up
- login akun
- dashboard saldo
- tracking status order
- integrasi backend topup yang aman

Fokus rilisan tahap 1:

- user bisa buka landing page
- user bisa login / lookup akun
- user bisa lihat katalog topup
- user bisa buat order
- user bisa bayar
- user bisa cek status order
- saldo user bisa sinkron dari backend

## 2. Scope Halaman

Halaman minimum yang wajib ada:

- `/` landing page
- `/topup` katalog produk topup
- `/login` login / lookup akun
- `/dashboard` profile singkat + saldo + riwayat ringkas
- `/orders` daftar order
- `/orders/:id` status order
- `/help` FAQ + kontak support

Halaman tambahan jika sempat:

- `/update`
- `/privacy`
- `/terms`

## 3. Branding dan Arah Visual

Gunakan identitas visual **Anomaly Rush** yang sudah muncul pada portal web lokal dan aset game.

Aturan visual:

- mobile-first
- playful
- trustable
- clean
- cepat dibaca
- jangan pakai template SaaS generik
- jangan pakai style admin dashboard generik
- ambil nuansa dari game Anomaly Rush

Preferensi visual:

- headline kuat
- CTA jelas
- product cards mudah dipindai
- status order sangat jelas
- layout fokus conversion

## 4. Source of Truth Produk

Gunakan katalog produk yang sama dengan game.

Referensi utama:

- `scripts/data/ShopCatalog.gd`
- `docs/TOPUP_PRODUCT_LIST.md`

Produk tahap 1:

1. `gems_small` — Rp 15.000 — 100 gems
2. `gems_standard` — Rp 45.000 — 330 gems
3. `gems_big` — Rp 99.000 — 950 gems
4. `gems_mega` — Rp 199.000 — 2500 gems
5. `starter_bundle` — Rp 29.000 — 1000 coins, 100 gems, 2 magnet tokens, 1 shield charge, 1 double-coins token
6. `progress_bundle` — Rp 59.000 — 2500 coins, 250 gems, 3 magnet tokens, 2 shield charges, 2 double-coins tokens
7. `cosmetic_bundle` — Rp 49.000 — 1500 coins, 200 gems, 2 shield charges

Aturan:

- `product_id` web harus sama dengan `product_id` di katalog game
- jangan ubah mapping grant tanpa update source of truth
- grant diproses di backend, bukan di frontend

## 5. Flow User

### Login / Lookup

- user masuk ke `/login`
- input `player_id` atau identifier final yang disepakati
- frontend kirim request ke backend
- jika valid, user masuk dashboard
- jika gagal, tampilkan error yang jelas

### Top Up

- user buka `/topup`
- user pilih produk
- user lihat ringkasan produk
- user klik bayar
- frontend panggil backend create order
- backend kembalikan `order_id` dan `payment_url`
- user diarahkan ke gateway atau modal pembayaran
- frontend polling status order
- saat status `paid`, frontend refresh saldo

### Order Tracking

- user buka `/orders/:id`
- frontend ambil status order
- tampilkan state:
  - created
  - pending
  - paid
  - failed
  - expired
  - cancelled

## 6. Kontrak Backend Minimum

Implementasi backend harus mengikuti blueprint yang sudah ada.

Referensi:

- `docs/WEB_TOPUP_BLUEPRINT_ID.md`
- `docs/FRONTEND_SPEC.md`

Endpoint minimum:

- `POST /v1/auth/login`
- `GET /v1/products?channel=web`
- `GET /v1/wallet/balance`
- `GET /v1/wallet/transactions`
- `POST /v1/topup/web/create-order`
- `GET /v1/topup/web/order/:order_id`
- `POST /v1/payments/webhook/:provider`

Aturan backend:

- validasi harga di server
- validasi `product_id` di server
- semua secret hanya di backend
- webhook wajib verifikasi signature
- grant wajib idempotent
- wallet update wajib atomic
- tidak boleh ada grant manual dari frontend

## 7. Definition of Done

Project dianggap selesai jika:

- semua halaman minimum hidup
- desain sudah usable dan branded
- katalog produk tampil sesuai source of truth
- login / lookup jalan
- create order jalan
- redirect / payment flow jalan
- order status jalan
- saldo bisa di-refresh dari backend
- loading, empty, error, success state ada
- semua credential sensitif ada di environment variable
- tidak ada secret hardcoded

## 8. Yang Harus Saya Berikan ke Agent

### Wajib

- nama brand final
- logo final
- warna brand final
- daftar produk final
- payment gateway yang dipakai
- aturan login akun
- endpoint backend final
- contoh request / response
- sandbox credential
- nomor CS / kontak support

### Ideal

- dokumen referensi visual dan benchmark
- copywriting final
- FAQ final
- kebijakan refund
- privacy policy
- terms of service
- Figma atau screenshot referensi
- event tracking analytics
- state error yang diinginkan

### Dokumen Referensi yang Sebaiknya Ikut Diberikan

- `docs/WEB_AGENT_HANDOFF_ID.md`
- `docs/FRONTEND_SPEC.md`
- `docs/WEB_TOPUP_BLUEPRINT_ID.md`
- `docs/TOPUP_PRODUCT_LIST.md`
- `docs/mobile-game-web-topup-reference-analysis.md`
- `docs/official-strategy-game-site-benchmark-2026-03-28.md`
- `docs/the-ants-similar-portal-reference-2026-03-15.md`

Fungsi masing-masing:

- `WEB_AGENT_HANDOFF_ID.md` untuk scope, flow, source of truth, dan definition of done
- `FRONTEND_SPEC.md` untuk kontrak UI flow dan integrasi frontend
- `WEB_TOPUP_BLUEPRINT_ID.md` untuk arsitektur backend, wallet, transaksi, webhook, dan grant ledger
- `TOPUP_PRODUCT_LIST.md` untuk daftar produk topup tahap 1
- tiga dokumen benchmark untuk arah visual, pola UX, susunan halaman, trust pattern, dan referensi kompetitor

## 9. Asset yang Perlu Dicopy ke Project Web

Ya. Asset penting sebaiknya disalin ke project web agar frontend tidak tergantung langsung ke struktur project Godot.

Yang perlu dicopy:

- logo utama
- favicon
- hero image
- social preview image
- screenshot game
- icon bundle / produk
- font brand jika dipakai custom
- ilustrasi karakter / background yang dipakai di landing page

Jangan copy seluruh folder assets game secara mentah.

Hanya copy asset yang dipakai web.

## 10. Struktur Asset yang Disarankan di Project Web

Gunakan struktur sederhana:

- `public/assets/brand/`
- `public/assets/products/`
- `public/assets/hero/`
- `public/assets/social/`
- `public/assets/icons/`
- `public/assets/screenshots/`
- `public/assets/fonts/`

Aturan:

- rename file dengan nama stabil
- hindari nama file acak
- gunakan format web-appropriate
- kompres gambar besar
- jangan jadikan asset game mentah sebagai dependency runtime web

## 11. Asset Checklist yang Harus Disiapkan

Minimal:

- `logo.svg` atau `logo.png`
- `favicon.png` atau `favicon.ico`
- `hero-main.webp`
- `brand-social-card.jpg`
- 3 sampai 6 screenshot game
- icon untuk 7 produk topup

Jika belum ada:

- agent boleh pakai placeholder rapi
- struktur final tetap harus siap untuk diganti asset asli

## 12. Environment Variable yang Perlu Disiapkan

Frontend:

- base URL API backend
- public key analytics
- public site URL

Backend:

- database URL
- JWT secret
- payment secret key
- payment webhook secret
- storage credentials jika ada
- Google verification credentials jika dipakai

Aturan:

- pakai sandbox dulu
- production secret diisi manual nanti

## 13. Instruksi Final ke Agent

Bangun website topup Anomaly Rush yang mobile-first, branded, trustable, dan siap dikembangkan ke production.

Gunakan source of truth produk dari katalog game.

Fokus tahap 1 pada landing page, login, katalog topup, create order, payment redirect, order tracking, dan sinkronisasi saldo.

Jika ada data belum lengkap:

- pakai placeholder yang rapi
- jangan blok progress
- lanjutkan implementasi struktur final

Semua secret harus lewat environment variable.

Semua grant harus diproses di backend.

Jangan buat frontend yang bergantung pada grant dari client.
