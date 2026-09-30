-- ============================================================
-- TUGAS TIM (D2 / UTS item 1.1, 1.2, 1.4) — fact table
-- Satu fact saja. Grain ditulis lengkap di komentar, bukan singkatan.
-- ============================================================

-- GRAIN: Satu baris = satu mahasiswa dalam satu mata kuliah pada satu pertemuan ke- tertentu pada suatu tanggal.
-- Setiap measure diberi label aditivitas + alasan:
--   ADDITIVE      : boleh di-SUM lintas semua dimensi (contoh: jumlah kehadiran, izin, sakit, alpha)
--   NON-ADDITIVE  : jangan di-SUM, pakai min/max/avg (contoh: jam masuk karena tidak dapat dijumlahkan across different meaning)

CREATE OR REPLACE TABLE fact_presensi AS
SELECT
  d.date_sk AS date_key,                    -- FK ke dim_date (converted from 10_dim_date.sql)
  m.mahasiswa_key,                          -- FK ke dim_mahasiswa
  mk.matakuliah_key,                        -- FK ke dim_matakuliah
  p.pertemuan_ke,                           -- degenerate dimension
  CASE
    WHEN UPPER(p.status) IN ('HADIR', 'Hadir', 'hadir') THEN 1
    ELSE 0
  END AS is_hadir,                          -- measure - ADDITIVE
  CASE
    WHEN UPPER(p.status) IN ('IZIN', 'izin') THEN 1
    ELSE 0
  END AS is_izin,                           -- measure - ADDITIVE
  CASE
    WHEN UPPER(p.status) IN ('SAKIT', 'Sakit', 'sakit') THEN 1
    ELSE 0
  END AS is_sakit,                          -- measure - ADDITIVE
  CASE
    WHEN UPPER(p.status) IN ('ALPA', 'Alpa', 'alpa') THEN 1
    ELSE 0
  END AS is_alpa,                           -- measure - ADDITIVE
  p.jam_masuk                               -- measure - NON-ADDITIVE (time)
FROM read_csv_auto('data/raw/t1_kampus/presensi.csv') p
JOIN (
  SELECT mahasiswa_key, nim
  FROM dim_mahasiswa
  WHERE angkatan = 2023  -- Pastikan hanya data anggkatan 2023 (slice k5)
) m ON p.nim = m.nim
JOIN dim_matakuliah mk ON p.kode_mk = mk.kode_mk
JOIN dim_date d ON p.tanggal = d.full_date
WHERE p.nim IS NOT NULL
  AND p.nim != ''
  AND p.kode_mk IS NOT NULL
  AND p.kode_mk != ''
  AND p.tanggal IS NOT NULL;