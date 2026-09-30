# D6 — Kamus metrik (12 field)

> UTS item 5 menilai **satu** metrik lengkap; UAS menilai tiga. Setiap metrik wajib punya berkas SQL
> di `sql/50_metrics/` — definisi yang tidak bisa dijalankan belum tentu benar.

## Metrik 1 — Harian Absensi Rate (Persentase Mahasiswa yang Hadir Setiap Hari)

| # | Field | Isi |
|---|---|---|
| 1 | Nama metrik | Harian Absensi Rate |
| 2 | Definisi (satu kalimat, tanpa jargon) | Persentase mahasiswa aktif angkatan 2023 yang hadir ke kampus setiap hari. |
| 3 | Rumus (SQL-nya, bukan bahasa manusia) | SELECT d.full_date AS tanggal, ROUND(100.0 * SUM(CASE WHEN f.is_hadir = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT f.mahasiswa_key), 2) AS absensi_rate FROM fact_presensi f JOIN dim_mahasiswa m ON f.mahasiswa_key = m.mahasiswa_key JOIN dim_date d ON f.date_key = d.date_sk WHERE m.angkatan = 2023 AND m.is_current = TRUE GROUP BY d.full_date ORDER BY d.full_date; |
| 4 | Grain | Satu baris per hari |
| 5 | Tabel sumber | fact_presensi, dim_mahasiswa, dim_date |
| 6 | Owner (jabatan bernama) | Kepala Bidang Akademik |
| 7 | Time basis | per hari kalender WIB |
| 8 | Satuan | persen (%) |
| 9 | Dimensi yang boleh dipotong | prodi, status_mahasiswa, kota_asal |
| 10 | Filter default | angkatan = 2023 dan is_current = TRUE |
| 11 | Arti nilai kosong | tidak ada data (hari tanpa rekaman presensi whatsoever) |
| 12 | Versi | v1, 2026-09-30 |

### Cara metrik ini di-gaming
Petugas bisa menambah rekaman presensi fiktif dengan status 'hadir' untuk mahasiswa yang tidak actually hadir, sehingga meningkatkan rasio kehadiran secara buatan.

### Guard test-nya
Satu test yang menghitung jumlah mahasiswa yang memiliki lebih dari satu rekaman presensi dengan status 'hadir' pada hari yang sama, duplicate entri untuk sama mahasiswa pada sama hari yang tidak logis karena seorang mahasiswa hanya bisa hadir sekali per hari.