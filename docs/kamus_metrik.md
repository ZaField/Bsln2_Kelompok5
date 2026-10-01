# D6 — Kamus metrik (12 field)

> UTS item 5 menilai **satu** metrik lengkap; UAS menilai tiga. Setiap metrik wajib punya berkas SQL
> di `sql/50_metrics/` — definisi yang tidak bisa dijalankan belum tentu benar.

## Metrik 1 — Harian Absensi Rate (Persentase Mahasiswa yang Hadir Setiap Hari)

| # | Field | Isi |
|---|---|---|
| 1 | Nama metrik | Harian Absensi Rate |
| 2 | Definisi (satu kalimat, tanpa jargon) | Persentase catatan presensi (satu mahasiswa di satu mata kuliah pada satu pertemuan) angkatan 2023 yang berstatus hadir, pada tanggal pertemuan tersebut. |
| 3 | Rumus (SQL-nya, bukan bahasa manusia) | SELECT d.full_date AS tanggal, ROUND(100.0 * AVG(f.is_hadir), 2) AS absensi_rate FROM fact_presensi f JOIN dim_date d ON f.date_key = d.date_sk GROUP BY d.full_date ORDER BY d.full_date; |
| 4 | Grain | Satu baris per tanggal pertemuan (14 tanggal, semuanya hari Jumat) |
| 5 | Tabel sumber | fact_presensi, dim_date |
| 6 | Owner (jabatan bernama) | Kepala Bidang Akademik |
| 7 | Time basis | per tanggal pertemuan (hari Jumat), WIB |
| 8 | Satuan | persen (%) |
| 9 | Dimensi yang boleh dipotong | prodi, status_mahasiswa, kota_asal |
| 10 | Filter default | Tidak ada filter tambahan: seluruh fact sudah berisi angkatan 2023 saja. |
| 11 | Arti nilai kosong | Tanggal tanpa pertemuan tidak muncul sama sekali |
| 12 | Versi | v2, 2026-10-01 |

### Cara metrik ini di-gaming
Petugas bisa menambah rekaman presensi fiktif dengan status 'hadir' untuk mahasiswa yang tidak actually hadir, sehingga meningkatkan rasio kehadiran secara buatan.

### Guard test-nya
Satu test menghitung kombinasi (mahasiswa, mata kuliah, tanggal) yang punya lebih dari satu rekaman
berstatus hadir. Seorang mahasiswa hanya bisa hadir sekali per mata kuliah per tanggal, jadi hasil harus 0:

    SELECT count(*) FROM (
      SELECT mahasiswa_key, matakuliah_key, date_key FROM fact_presensi
      WHERE is_hadir = 1 GROUP BY 1,2,3 HAVING count(*) > 1)

Kuncinya per mata kuliah, bukan per hari, karena satu mahasiswa punya 3 mata kuliah per hari.
Batas: test ini menangkap rekaman ganda/salinan, bukan satu rekaman hadir fiktif untuk mahasiswa yang absen.