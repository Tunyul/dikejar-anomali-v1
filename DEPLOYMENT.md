# Panduan Deployment & Keamanan

## 1. Arsitektur Server
Aplikasi ini menggunakan **Node.js** sebagai backend utama. Untuk production, sangat disarankan menggunakan **Nginx** sebagai *Reverse Proxy* di depannya.

**Mengapa Nginx (bukan Apache)?**
- Nginx lebih ringan dan cepat dalam menangani koneksi konkuren (banyak user sekaligus).
- Sangat cocok dipasangkan dengan Node.js untuk menangani file statis dan SSL.

## 2. Cara Mengaktifkan Nginx
Di server production (VPS Ubuntu/Debian), lakukan langkah berikut:

1.  **Install Nginx:**
    ```bash
    sudo apt update
    sudo apt install nginx
    ```

2.  **Pasang Konfigurasi:**
    Salin file `nginx.conf` dari project ini ke konfigurasi Nginx sistem.
    *Catatan: File `nginx.conf` di project ini adalah contoh full config. Biasanya Anda hanya perlu menyalin blok `server { ... }` ke `/etc/nginx/sites-available/default`.*

    Contoh isi `/etc/nginx/sites-available/web-anomaly-rush`:
    ```nginx
    server {
        listen 80;
        server_name domain-anda.com;

        location / {
            proxy_pass http://localhost:3000; # Arahkan ke Node.js
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

3.  **Restart Nginx:**
    ```bash
    sudo systemctl restart nginx
    ```

## 3. Checklist Keamanan (Sudah Diterapkan di Kode)

### A. Backend (Node.js)
- [x] **Validasi Webhook**: `verifySignature` diaktifkan di `topupController.js`. Hacker tidak bisa memalsukan status pembayaran.
- [x] **Rate Limiting**: `express-rate-limit` membatasi user spamming request.
- [x] **Helmet**: Header keamanan HTTP otomatis aktif.
- [x] **Validasi Input**: Menggunakan `express-validator` (perlu dipastikan di semua route).
- [x] **User Check**: Endpoint `/api/users/check/:id` aman, hanya mengembalikan info publik (username).

### B. Frontend
- [x] **No Fake Success**: Logika simulasi webhook di sisi klien sudah dihapus. Frontend hanya menunggu konfirmasi dari server atau redirect.
- [x] **Input Sanitization**: Mencegah XSS sederhana via `innerText` (pastikan tidak pakai `innerHTML` untuk input user tak terpercaya).

### C. Server (Nginx) - *Perlu di-setup saat deploy*
- [ ] **HTTPS/SSL**: Wajib gunakan Certbot (Let's Encrypt) agar data terenkripsi.
- [ ] **Firewall**: Tutup port 3000 dari akses publik, hanya buka port 80/443 (Nginx).

## 4. Environment Variables (.env)
Pastikan di production:
- `NODE_ENV=production`
- `AIRWALLET_SECRET_KEY` diisi dengan key rahasia yang panjang dan acak.
- `JWT_SECRET` diganti dengan string acak yang kuat.
