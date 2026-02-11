# Shop Mobile – Horizontal Scroll per Group

## Struktur Layar Utama Shop
- Layar utama shop dengan layout portrait (mobile).
- Header shop: judul, tombol back/close, ikon bantuan.
- Panel informasi player: avatar kecil, nama, level (opsional).
- Panel mata uang: soft currency, premium currency, tiket/fragment (bila ada).
- Daftar group/kategori shop (mis. Featured, Promo, Gems, Coins, Bundles, Skin).
- Setiap group tampil sebagai blok terpisah dengan judul dan tombol "Lihat semua" (opsional).
- Di dalam tiap group: list item yang bisa di-scroll horizontal.
- Indikator scroll (fade di kiri/kanan atau scrollbar halus).
- Area notifikasi: banner diskon, waktu event, error (koneksi, dsb.).

## Kategori / Group Shop
- Featured / Rekomendasi.
- Starter Pack / New Player.
- Daily / Weekly Deals.
- Mata uang premium (gems/diamonds).
- Mata uang biasa (coins/gold/energy).
- Bundle (paket item campuran).
- Skin / Costume / Cosmetic.
- Item konsumsi (boost, ticket, key).
- Battle Pass / Season Pass (jika ada).
- Event khusus (limited time, seasonal).

## Komponen UI per Group (Horizontal Strip)
- Container group dengan judul dan icon kategori.
- Label deskripsi singkat group.
- Tombol info (jika group punya mekanik khusus).
- List item dalam bentuk kartu yang bisa di-scroll horizontal.
- Navigasi horizontal: swipe, drag, dan pan gesture.
- Tombol panah kiri/kanan (opsional) untuk navigasi tambahan.
- Indikator posisi (dot/page) jika item dibagi per halaman.
- Tombol "Lihat semua" untuk membuka layar full list group (vertical).

## Komponen UI per Item (Card)
- Thumbnail/gambar item atau bundle.
- Nama item.
- Deskripsi singkat atau highlight benefit.
- Harga utama (soft/premium currency).
- Harga coret (jika diskon) dan label % discount.
- Label rarity (Common/Rare/Epic/Legendary) jika relevan.
- Badge: "Best Value", "Most Popular", "Limited", "New".
- Timer event / countdown (jika item terbatas waktu).
- Informasi jumlah (x10, x50, dll.).
- Indikator sudah dimiliki / owned (untuk cosmetic).
- Tombol beli utama.
- Tombol detail untuk membuka pop-up info item.

## Navigasi dan Interaksi
- Scroll vertikal untuk berpindah group (jika banyak group di satu layar).
- Scroll horizontal di dalam tiap group untuk melihat item lain.
- Gesture support: swipe/fling dengan inertia.
- Snapping item ke posisi tengah atau grid saat scroll berhenti.
- Lock input saat transaksi sedang diproses.
- Tap di area luar kartu tidak memicu pembelian.
- Back/close dari hardware (Android) menutup shop dengan aman.

## Logika Data dan Konfigurasi
- Definisi model Item Shop (id, nama, deskripsi, icon, harga, currency type, quantity, rarity, tags, group_id).
- Definisi model Group Shop (id, nama, icon, urutan, tipe group).
- Mapping item ke group berdasarkan group_id atau tag.
- Konfigurasi prioritas urutan group dan item (sorting).
- Konfigurasi visibilitas per platform/negara (jika perlu).
- Konfigurasi waktu aktif (start/end date) untuk item/event.
- Konfigurasi stok/limit pembelian (per hari, per akun, dsb.).
- Konfigurasi label promo (discount %, bundle value).

## Alur Loading dan Refresh
- Inisialisasi list group dan item saat shop dibuka.
- Loading state (skeleton/placeholder) untuk list horizontal per group.
- Fallback data lokal jika koneksi lambat/gagal (opsional).
- Mekanisme refresh manual (pull to refresh / tombol reload).
- Cache data shop untuk mengurangi request berulang.
- Update real-time untuk timer event dan ketersediaan item.

## Alur Pembelian (Client-side)
- Validasi status akun dan koneksi sebelum memulai pembelian.
- Tap tombol beli pada item membuka pop-up konfirmasi.
- Pop-up konfirmasi menampilkan: nama item, isi bundle, harga, diskon, currency yang terpakai.
- Tombol konfirmasi dan cancel.
- Lock UI/tombol saat permintaan pembelian dikirim.
- Menangani keberhasilan: animasi reward, update currency dan inventory.
- Menangani kegagalan: pesan error jelas (koneksi, saldo kurang, dsb.).
- Menangani pembelian berulang/tap spam dengan cooldown.

## Integrasi Pembayaran
- Integrasi IAP platform (Google Play / App Store) untuk currency premium/bundle.
- Validasi receipt di server (bila ada backend).
- Sinkronisasi currency dan item setelah pembelian sukses.
- Penanganan edge case: pembayaran sukses tapi app tertutup, restore purchase.

## UX dan Feedback Visual
- Animasi saat group muncul (fade/slide ringan).
- Animasi scroll horizontal yang halus.
- Highlight kartu saat di-hover/tap.
- Efek khusus untuk item promo/rare (glow, border khusus).
- Transisi pembukaan dan penutupan shop.
- State kosong (jika group tidak punya item tersedia).
- Pesan saat shop tidak bisa dimuat (offline/maintenance).

## Tracking dan Analytics
- Tracking open/close shop.
- Tracking scroll dan interaksi per group (berapa kali dilihat, di-scroll).
- Tracking klik beli per item (intent) dan pembelian sukses.
- Tracking performa setiap group (conversion rate per kategori).

## Optimasi Performa
- Batasi jumlah item yang dirender sekaligus per group (virtualization).
- Lazy loading gambar/item saat akan masuk viewport.
- Kompres ukuran gambar dan gunakan atlas/spritesheet.
- Minimalkan komponen berat dalam kartu item.
- Reuse/pool node UI untuk kartu item yang di-scroll keluar layar.

## State dan Persistensi
- Simpan pengaturan terakhir: group yang terakhir dibuka, posisi scroll (opsional).
- Simpan info cooldown/limit pembelian lokal untuk feedback cepat.
- Sinkronisasi dengan server saat koneksi tersedia.

## QA dan Edge Case
- Uji di berbagai resolusi dan rasio layar (tall, wide, notch).
- Uji input multi-touch dan gesture conflict dengan layer lain.
- Uji perilaku saat koneksi putus di tengah pembelian.
- Uji perilaku saat jumlah currency tidak cukup.
- Uji tampilan ketika jumlah item/group sangat banyak.

