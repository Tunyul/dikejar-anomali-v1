## Masalah
- Loading mencapai 100% namun tidak beralih ke ENTRY; player tidak muncul.
- Ambang progres terlalu ketat dan kurang logging, sehingga sulit melacak alur.

## Solusi Teknis
1) Perkuat Syarat Selesai Loading
- Di `scripts/simple_game_manager.gd:on_generation_progress` ubah syarat ke toleransi float:
  - Gunakan `(min(load_progress_a, load_progress_b) >= 0.999 or avg_pct >= 0.999)` dan `elapsed >= min_loading_ms`.
- Tambahkan fallback waktu: jika `elapsed > 2000` ms dan `avg_pct >= 0.9`, tetap lanjut ENTRY.

2) Tandai Sumber Progres
- Lacak `done_a` dan `done_b` saat menerima `pct >= 0.999`.
- Lanjut ENTRY jika `done_a && done_b` atau fallback waktu terpenuhi.

3) Logging Fase & Progres
- Cetak log pada:
  - Tombol MULAI ditekan → masuk LOADING.
  - Phase TITLE/LOADING/ENTRY/PLAYING/GAME_OVER.
  - Progres A/B, rata-rata, elapsed.
  - Saat syarat terpenuhi → cetak “Loading complete → ENTRY”.
  - Saat memicu player entry → cetak posisi target.

4) Perbaikan LoadingScreen
- Pastikan overlay `ColorRect` memiliki `mouse_filter=Ignore` agar tidak menahan input yang tak perlu.
- Konsolidasikan teks agar hanya satu label “Loading X%”.
- Pastikan `finish_transition()` di ENTRY memanggil `hide_screen()` setelah tween selesai.

5) Jamin Player ENTRY
- Di `set_entry_phase` panggil `player.start_appearance_from_left(Vector2(280, 444))` setelah overlay fade-out, dan set `player.visible=true` untuk berjaga-jaga.
- Verifikasi state player berubah: APPEARING → RUNNING_IN_PLACE → FULL_MOVEMENT.

## Verifikasi
- Observasi log fase dan progres di output.
- Saat 100% atau 99.9% + ≥0.5s, loading hilang dan player masuk dari kiri.
- Jika salah satu `Ground` tidak emit final, fallback waktu memastikan tidak tersangkut.

Konfirmasi untuk saya terapkan perubahan di atas (menambah logging, toleransi progres, fallback, dan penguatan ENTRY).