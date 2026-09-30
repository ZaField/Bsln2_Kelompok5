# D7 — Batas lingkap capstone (ditandatangani di Sesi 8)

> Diisi tim **sebelum** menghadap dosen. Dosen hanya mencoret dan tanda tangan.
> Form ini yang jadi acuan rubrik di Sesi 15–16: yang kamu potong tidak dihitung sebagai kekurangan.

Tim: Kelompok 5  Topik / slice: T1 Kampus / k5 (Angkatan 2023)  Tanggal: 2026-09-30

## AKAN DIBANGUN (maksimal 1 fact table + 1 conformed dimension per RPS butir 8)

| # | Artefak | Ukuran selesai | Deadline |
|---|---|---|---|
| 1 | fact: fact_presensi | Grain satu mahasiswa per mata kuliah per pertemuan; 0 baris duplikat grain setelah dedup; jumlah baris direkonsiliasi dengan sumber yang sudah dedup; setiap measure berlabel aditivitas + alasan | Selesai |
| 2 | conformed dim: dim_mahasiswa (SCD Type 2) | Surrogate key, natural key nim, valid_from/valid_to/is_current benar, status dinormalisasi, fact join point-in-time (tanggal BETWEEN valid_from AND valid_to) | Selesai |
| 3 | metrik di kamus: 1 dari 3 (Harian Absensi Rate) | Entri kamus lengkap (semua field, risiko gaming, guard test); SQL sesuai definisi | Selesai |
| 4 | dashboard: 0 tile | 3 query analitik selesai: moving average 7 hari, peringkat kehadiran per prodi, perubahan bulan-ke-bulan | Selesai |

## TIDAK LAGI DIBANGUN (sebut namanya, jangan "kalau ada waktu")

| # | Yang dicabut | Alasan |
|---|---|---|
| 1 | fact_nilai dan seluruh analisis berbasis nilai.csv | Lingkup dibatasi 1 fact; data nilai juga punya masalah kualitas (nilai_angka dan nilai_huruf tidak konsisten, ada nilai di luar rentang) yang butuh pekerjaan pembersihan tersendiri |
| 2 | Analisis hubungan kehadiran dan nilai | Bergantung pada fact_nilai yang dicabut; ini batas desain pada butir 6 |
| 3 | Riwayat SCD2 yang sebenarnya (perubahan prodi/status dari waktu ke waktu) | mahasiswa.csv hanya satu snapshot sehingga tiap mahasiswa hanya punya satu versi; butuh change log atau snapshot berkala |
| 4 | Metrik ke-2 dan ke-3 di kamus metrik | Hanya 1 metrik yang didokumentasikan penuh beserta guard test-nya |
| 5 | Angkatan selain 2023 | Proyek dibatasi pada slice k5 (Grup 5, angkatan 2023) |

## Tanda tangan

| Tim | Dosen |
|---|---|
| Kelompok 5 |  |
| [tanda tangan] | [tanda tangan] |