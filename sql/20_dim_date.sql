-- ============================================================
-- 20_dim_date.sql — DIMENSI TANGGAL (PERBAIKAN UNTUK STAR SCHEMA)
-- File ini mengubah tabel dim_date yang dibuat oleh 10_dim_date.sql
-- untuk menambahkan kolom academic_semester sesuai spesifikasi star schema.
-- ============================================================

-- Tambahkan kolom academic_semester ke tabel dim_date yang sudah ada
-- 1 = Semester 1 (Januari - Juni)
-- 2 = Semester 2 (Juli - Desember)
ALTER TABLE dim_date
ADD COLUMN IF NOT EXISTS academic_semester INT64;

-- Update nilai academic_semester berdasarkan bulan
UPDATE dim_date
SET academic_semester = CASE
    WHEN bulan BETWEEN 1 AND 6 THEN 1
    ELSE 2
END
WHERE academic_semester IS NULL;