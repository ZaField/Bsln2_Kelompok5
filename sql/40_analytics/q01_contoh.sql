-- ============================================================
-- 40_analytics/q01_contoh.sql — ANALITIK UNTUK TOPIK T1 KAMPUS, SLICE K5 (ANGKATAN 2023)
-- Jawaban yang diharapkan (tulis ini di Brief, bukan hanya SQL-nya):
--   "The moving average smooths out daily fluctuations to show trends in course attendance over time for the 2023 cohort."
-- ============================================================

WITH daily_attendance AS (
  SELECT
    d.full_date AS tanggal,
    mk.kode_mk,
    mk.nama_mk,
    AVG(f.is_hadir) AS attendance_rate   -- average of is_hadir (0/1) gives proportion present
  FROM fact_presensi f
  JOIN dim_mahasiswa m ON f.mahasiswa_key = m.mahasiswa_key
  JOIN dim_matakuliah mk ON f.matakuliah_key = mk.matakuliah_key
  JOIN dim_date d ON f.date_key = d.date_sk -- possibly error d.date_sk should be d.date_key
  WHERE m.angkatan = 2023   -- slice k5
  GROUP BY d.full_date, mk.kode_mk, mk.nama_mk
)
SELECT
  tanggal,
  kode_mk,
  nama_mk,
  attendance_rate,
  AVG(attendance_rate) OVER (
    PARTITION BY kode_mk
    ORDER BY tanggal
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS attendance_rate_7day_moving_avg
FROM daily_attendance
ORDER BY tanggal, kode_mk;
