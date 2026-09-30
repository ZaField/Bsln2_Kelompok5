-- ============================================================
-- TUGAS TIM (D2 / UTS item 1) — dimensi ketiga (referensi/kamus)
-- Sering terlupakan, dan justru tempat paling banyak kasus "Unknown".
-- ============================================================

-- DIM_MATAKULIAH: Type 0 (tidak berubah) karena kode mata kuliah, nama, sks, semester,
-- dan dosen dianggap tetap untuk periode waktu yang relevan di data historis ini.
-- Surrogate key: matakuliah_key

CREATE OR REPLACE TABLE dim_matakuliah AS
SELECT
  ROW_NUMBER() OVER (ORDER BY kode_mk) AS matakuliah_key,   -- surrogate key
  kode_mk,                                                   -- natural key
  nama_mk,
  sks,
  semester,
  dosen
FROM read_csv_auto('data/raw/t1_kampus/matakuliah.csv')
WHERE kode_mk IS NOT NULL
  AND kode_mk != '';