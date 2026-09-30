-- ============================================================
-- 40_analytics/q02.sql — ANALITIK UNTUK TOPIK T1 KAMPUS, SLICE K5 (ANGKATAN 2023)
-- Jawaban yang diharapkan (tulis ini di Brief, bukan hanya SQL-nya):
--   "The ranking shows which students in each study program have the highest attendance, helping identify highly engaged students."
-- ============================================================

WITH student_attendance AS (
  SELECT
    m.nim,
    m.nama,
    m.prodi,
    SUM(f.is_hadir) AS total_hadir
  FROM fact_presensi f
  JOIN dim_mahasiswa m ON f.mahasiswa_key = m.mahasiswa_key
  WHERE m.angkatan = 2023
  GROUP BY m.nim, m.nama, m.prodi
)
SELECT
  nim,
  nama,
  prodi,
  total_hadir,
  RANK() OVER (PARTITION BY prodi ORDER BY total_hadir DESC) AS attendance_rank
FROM student_attendance
ORDER BY prodi, attendance_rank;