-- ============================================================
-- 40_analytics/q03.sql — ANALITIK UNTUK TOPIK T1 KAMPUS, SLICE K5 (ANGKATAN 2023)
-- Jawaban yang diharapkan (tulis ini di Brief, bukan hanya SQL-nya):
--   "The month-over-month change indicates whether attendance is improving or declining for each course over time for the 2023 cohort."
-- ============================================================

WITH monthly_attendance AS (
  SELECT
    d.tahun AS tahun, -- possibly error d.tahun should be d.year
    d.bulan AS bulan, -- possibly error d.bulan should be d.month
    mk.kode_mk,
    mk.nama_mk,
    AVG(f.is_hadir) AS attendance_rate
  FROM fact_presensi f
  JOIN dim_mahasiswa m ON f.mahasiswa_key = m.mahasiswa_key
  JOIN dim_matakuliah mk ON f.matakuliah_key = mk.matakuliah_key
  JOIN dim_date d ON f.date_key = d.date_sk -- possibly error d.date_sk should be d.date_key
  WHERE m.angkatan = 2023
  GROUP BY d.tahun, d.bulan, mk.kode_mk, mk.nama_mk
)
SELECT
  tahun,
  bulan,
  kode_mk,
  nama_mk,
  attendance_rate,
  LAG(attendance_rate) OVER (PARTITION BY kode_mk ORDER BY tahun, bulan) AS prev_month_attendance,
  attendance_rate - LAG(attendance_rate) OVER (PARTITION BY kode_mk ORDER BY tahun, bulan) AS attendance_change
FROM monthly_attendance
ORDER BY kode_mk, tahun, bulan;
