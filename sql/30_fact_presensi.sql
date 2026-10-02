-- ============================================================
-- TUGAS TIM (D2 / UTS item 1.1, 1.2, 1.4) — fact table
-- Satu fact saja. Grain ditulis lengkap di komentar, bukan singkatan.
-- ============================================================

-- GRAIN: Satu baris = satu mahasiswa pada satu mata kuliah pada satu tanggal pertemuan.
--   Kunci alami: (nim, kode_mk, tanggal). pertemuan_ke = degenerate dimension, BUKAN bagian kunci
--   (kosong di 781 baris sumber).
-- Aturan status: 'H' = hadir (singkatan). '-' tidak punya arti terdokumentasi DIPETAKAN KE ALPA sebagai
--   ASUMSI (jam_masuk kosong seperti ALPA). Pada data ini empat flag saling lepas dan lengkap (jumlah = 1).
-- Aditivitas: is_hadir/is_izin/is_sakit/is_alpa = ADDITIVE (flag 0/1, boleh di-SUM lintas dimensi).
--   jam_masuk = NON-ADDITIVE (teks 'H:MM', tidak bermakna dijumlah terisi juga untuk izin/sakit,
--   jadi bukan penanda kehadiran).

CREATE OR REPLACE TABLE fact_presensi AS
SELECT
  d.date_sk AS date_key,                    -- FK ke dim_date (converted from 10_dim_date.sql)
  m.mahasiswa_key,                          -- FK ke dim_mahasiswa
  mk.matakuliah_key,                        -- FK ke dim_matakuliah
  p.pertemuan_ke,                           -- degenerate dimension
  CASE WHEN UPPER(TRIM(p.status)) IN ('HADIR','H') THEN 1 ELSE 0 END AS is_hadir,
  CASE WHEN UPPER(TRIM(p.status)) = 'IZIN'  THEN 1 ELSE 0 END AS is_izin,
  CASE WHEN UPPER(TRIM(p.status)) = 'SAKIT' THEN 1 ELSE 0 END AS is_sakit,
  CASE WHEN COALESCE(UPPER(TRIM(p.status)), '-') IN ('ALPA', '-') THEN 1 ELSE 0 END AS is_alpa,
  p.jam_masuk                               -- measure - NON-ADDITIVE (time)
FROM (
  SELECT * EXCLUDE (rn) FROM (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY nim, kode_mk,
          CASE WHEN tanggal LIKE '__/__/____' THEN strptime(tanggal, '%d/%m/%Y')::DATE
               ELSE TRY_CAST(tanggal AS DATE) END
        ORDER BY pertemuan_ke NULLS LAST
      ) AS rn
    FROM read_csv_auto('data/raw/t1_kampus/presensi.csv')
  ) WHERE rn = 1
) p
JOIN (
  SELECT mahasiswa_key, nim
  FROM dim_mahasiswa
  WHERE angkatan = 2023  -- Pastikan hanya data anggkatan 2023 (slice k5)
) m ON p.nim = m.nim
JOIN dim_matakuliah mk ON p.kode_mk = mk.kode_mk
JOIN dim_date d ON
  CASE
    WHEN p.tanggal LIKE '__/__/____' THEN strptime(p.tanggal, '%d/%m/%Y')
    WHEN p.tanggal LIKE '____-__-__' THEN strptime(p.tanggal, '%Y-%m-%d')
    ELSE NULL
  END = d.full_date
WHERE p.nim IS NOT NULL
  AND p.nim != ''
  AND p.kode_mk IS NOT NULL
  AND p.kode_mk != ''
  AND p.tanggal IS NOT NULL;