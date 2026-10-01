-- ============================================================
-- TUGAS TIM (D2 / UTS item 1.2–1.3) — dimensi entitas utama
-- Ganti nama berkas ini dengan entitasmu: 20_dim_mahasiswa.sql | 20_dim_product.sql | 20_dim_wilayah.sql
-- Ganti pula nama tabelnya. Yang WAJIB ada:
--   * surrogate key  : <entitas>_sk  (INTEGER, hasil row_number() — bukan ID dari sumber)
--   * natural key    : ID bisnis dari sumber (nim | product_id | kode wilayah) disimpan, tapi bukan PK
--   * SCD type       : satu tipe per dimensi + alasan satu baris
--   * Type 2         : valid_from, valid_to, is_current
-- ============================================================

-- DIM_MAHASISWA: Type 2 (histori) karena prodi dan status dapat berubah selama studi mahasiswa,
-- serta mungkin perubahan status (aktif->lulus, cuti->aktif, etc). Dengan Type 2 kita dapat
-- menyimpan histori perubahan status dan prodi mahasiswa.

CREATE OR REPLACE TABLE dim_mahasiswa AS
SELECT
  ROW_NUMBER() OVER (ORDER BY nim) AS mahasiswa_key,   -- surrogate key
  CAST(nim AS VARCHAR) AS nim,                                                 -- natural key
  nama,
  angkatan,
  prodi,
  LOWER(TRIM(status)) AS status,
  kota_asal,
  tanggal_masuk,
  tanggal_masuk AS valid_from,                         -- Type 2: mulai dari tanggal masuk
  DATE '9999-12-31' AS valid_to,                       -- Type 2: selamanya jika masih aktif
  TRUE AS is_current                                   -- Type 2: satu snapshot = satu versi per mahasiswa, jadi semua baris adalah versi terkini
FROM (
  SELECT
    nim,
    nama,
    angkatan,
    prodi,
    status,
    kota_asal,
    tanggal_masuk
  FROM read_csv_auto('data/raw/t1_kampus/mahasiswa.csv')
  WHERE angkatan = 2023  -- Slice k5 untuk Grup 5 (Angkatan 2023)
    AND nim IS NOT NULL
    AND CAST(p.nim AS VARCHAR) != 
);