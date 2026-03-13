# Blueprint Web Top-up Dual Channel (Google Play Billing + Website)

Dokumen ini menjadi panduan implementasi top-up yang aman, patuh policy, dan siap produksi untuk game **Dikejar Anomali**.

## 1. Tujuan

- Menjalankan pembelian digital di Android dengan **Google Play Billing**.
- Menyediakan kanal top-up tambahan melalui **website resmi**.
- Menyatukan grant coin/gems di backend agar konsisten dan anti-duplikasi.

## 2. Prinsip Policy

- Pembelian digital di dalam app Android wajib lewat Google Play Billing.
- Website top-up diposisikan sebagai kanal terpisah di browser.
- Jangan menaruh secret key payment gateway di client game atau frontend web.

## 3. Arsitektur Ringkas

- **Game Client (Godot)**
  - In-app purchase via BillingManager/MonetizationService.
  - Sinkronisasi saldo dari backend setelah transaksi.
- **Web Frontend**
  - Login akun game.
  - Pilih paket top-up.
  - Redirect/check status pembayaran.
- **Backend API**
  - Buat order.
  - Verifikasi payment webhook.
  - Grant saldo coin/gems idempotent.
  - Sediakan endpoint saldo dan histori transaksi.
- **Database**
  - Users, wallets, transactions, grant ledger, audit logs.

## 4. Data Model Minimum

### 4.1 users

- id (uuid, pk)
- game_user_id (string, unique)
- email (string, nullable)
- created_at
- updated_at

### 4.2 wallets

- user_id (fk users.id, unique)
- coins (bigint, default 0)
- gems (bigint, default 0)
- updated_at

### 4.3 products

- id (string, pk) contoh: `gems_small`
- channel (`google_play` | `web`)
- currency (`idr`)
- price_amount (integer)
- grants_json (jsonb) contoh: `{ "coins": 0, "gems": 100 }`
- is_active (bool)
- updated_at

### 4.4 topup_transactions

- id (uuid, pk)
- user_id (fk)
- product_id (fk products.id)
- channel (`google_play` | `web`)
- provider (`google` | `airwallex` | `xendit` dll)
- provider_txn_id (string, nullable)
- external_order_id (string, unique)
- status (`created` | `pending` | `paid` | `failed` | `expired` | `cancelled`)
- amount (integer)
- raw_payload_json (jsonb)
- created_at
- updated_at

### 4.5 grant_ledger

- id (uuid, pk)
- transaction_id (fk topup_transactions.id, unique)
- grant_key (string, unique) contoh: `grant:web:order_123`
- coins_delta (bigint)
- gems_delta (bigint)
- applied_at

### 4.6 audit_logs

- id (uuid, pk)
- actor_type (`system` | `user` | `admin`)
- actor_id (string)
- action (string)
- object_type (string)
- object_id (string)
- payload_json (jsonb)
- created_at

## 5. Endpoint API Minimum

## 5.1 Auth

- `POST /v1/auth/login`
- `POST /v1/auth/refresh`
- `POST /v1/auth/logout`

## 5.2 Catalog & Wallet

- `GET /v1/products?channel=web`
- `GET /v1/wallet/balance`
- `GET /v1/wallet/transactions?limit=20&cursor=...`

## 5.3 Web Top-up

- `POST /v1/topup/web/create-order`
  - input: product_id
  - output: order_id, payment_url
- `GET /v1/topup/web/order/:order_id`
  - output: status pembayaran dan status grant
- `POST /v1/payments/webhook/:provider`
  - endpoint callback dari payment gateway
  - verifikasi signature + timestamp + replay protection

## 5.4 Google Play Validation

- `POST /v1/topup/google/verify`
  - input: product_id, purchase_token
  - backend validasi token ke API Google
  - jika valid dan belum di-grant, grant saldo

## 6. Flow Utama

### 6.1 Flow Android (Google Play Billing)

1. User beli di app.
2. App kirim `product_id + purchase_token` ke backend.
3. Backend verifikasi ke Google.
4. Backend buat/update transaksi `paid`.
5. Backend apply grant via grant_ledger (idempotent).
6. App panggil `GET /wallet/balance` untuk refresh HUD.

### 6.2 Flow Website Top-up

1. User login web dan pilih paket.
2. Backend create order dan kembalikan payment URL.
3. User bayar di gateway.
4. Gateway kirim webhook ke backend.
5. Backend validasi webhook lalu update transaksi.
6. Backend apply grant via grant_ledger (idempotent).
7. Saat user buka game, saldo sudah bertambah.

### 6.3 Fallback Mode Saat Belum Ada UID/ID Google Play

1. Anggap fitur Google Play sebagai `disabled` secara default.
2. Jika credential Google Play belum lengkap, endpoint `POST /v1/topup/google/verify` harus menolak dengan `service_unavailable`.
3. Pada game client:
   - Tombol beli real-money Google Play dinonaktifkan atau disembunyikan.
   - Login Play Games, leaderboard, dan achievement dijalankan dalam mode opsional.
   - Pesan UI jelas: `Billing belum tersedia` atau `Segera hadir`.
4. Kanal web top-up tetap bisa berjalan jika backend dan gateway web sudah siap.
5. Tidak boleh ada grant manual dari client saat Google verify gagal.
6. Aktivasi ulang fitur Google Play hanya lewat feature flag setelah checklist credential lulus.

### 6.4 Checklist Credential Google Play Minimum

- Package name final aplikasi Android.
- Product ID final di Play Console.
- Akses Play Console yang valid.
- Service account backend untuk verifikasi purchase token.
- OAuth client + SHA-1/SHA-256 untuk Play Games Sign-In.
- Leaderboard ID dan Achievement ID final.
- Daftar tester internal untuk sandbox.

## 7. Security Checklist Wajib

- HTTPS only + HSTS.
- Secret key hanya di backend dan secret manager.
- JWT short-lived + refresh token rotation.
- CSRF protection untuk endpoint web berbasis cookie.
- Rate limiting per IP + per user untuk endpoint sensitif.
- Validasi server-side semua harga dan product_id.
- Idempotency key untuk create-order dan apply-grant.
- Webhook signature verification + replay guard.
- Audit log untuk create order, verify, grant, admin action.
- Alerting untuk spike `failed webhook`, `grant mismatch`, `5xx`.
- Feature flag wajib untuk menyalakan atau mematikan channel Google Play/Web.

## 8. Anti-Duplikasi Grant (Paling Penting)

- Setiap transaksi harus punya `grant_key` unik.
- `grant_ledger.transaction_id` wajib unique.
- Proses grant harus atomic dalam 1 DB transaction:
  - insert grant_ledger
  - update wallet
  - commit
- Jika insert grant_ledger gagal karena unique conflict, anggap sudah pernah grant.

## 9. Operasional Production

- Pisahkan environment: dev, staging, prod.
- Jalankan migrasi DB terkontrol.
- Siapkan dashboard monitor:
  - payment success rate
  - webhook latency
  - grant success rate
  - saldo mismatch count
- Siapkan runbook incident:
  - payment paid tapi saldo belum masuk
  - webhook telat
  - duplicate callback

## 10. Backup, Restore, dan Disaster Recovery

### 10.1 Backup Policy Minimum

- Full backup database harian.
- Incremental backup setiap 15-60 menit.
- Retensi backup:
  - Harian: 14 hari
  - Mingguan: 8 minggu
  - Bulanan: 6-12 bulan
- Simpan backup terenkripsi di region berbeda.
- Simpan checksum untuk validasi integritas file backup.

### 10.2 Recovery Objective

- RPO target: maksimal kehilangan data 15 menit.
- RTO target: layanan pulih maksimal 60 menit.
- Jika belum mampu target ini, tulis target aktual di SLA internal.

### 10.3 Restore SOP

1. Freeze sementara endpoint grant/top-up.
2. Restore database dari snapshot terakhir + incremental log.
3. Verifikasi data inti:
   - wallets
   - topup_transactions
   - grant_ledger
4. Jalankan reconcile:
   - transaksi `paid` tanpa grant
   - grant tanpa transaksi valid
5. Buka endpoint bertahap setelah metrik sehat.

### 10.4 Uji Backup Berkala

- Simulasi restore minimal 1x per bulan di staging.
- Catat durasi restore aktual dan bandingkan dengan RTO.
- Buat laporan hasil uji:
  - start/end time
  - data mismatch
  - tindakan koreksi
- Tes skenario gagal:
  - backup corrupt
  - region storage utama tidak tersedia
  - webhook tertunda setelah restore

## 11. Roadmap 14 Hari

- Hari 1-2: finalisasi schema DB + auth.
- Hari 3-4: endpoint products, wallet, transactions.
- Hari 5-6: create order web + integrasi gateway sandbox.
- Hari 7-8: webhook verification + grant_ledger idempotent.
- Hari 9-10: verify Google purchase token + grant flow Android.
- Hari 11: sinkronisasi game client ke endpoint balance.
- Hari 12: observability + alerting + audit logs.
- Hari 13: hardening security + negative testing.
- Hari 14: UAT + soft launch terbatas.

## 12. Definition of Done

- Transaksi web dan Google Play sama-sama bisa grant saldo tanpa duplikasi.
- Seluruh endpoint sensitif lolos security checklist.
- Monitoring dan alert dasar aktif.
- Ada prosedur manual reconcile untuk kasus anomali.
- Uji end-to-end lulus untuk status `success`, `pending`, `failed`, `duplicate webhook`.
- Uji restore backup lulus dengan bukti waktu restore dan hasil verifikasi data.
