-- ============================================================
-- 50_metrics/harian_absensi_rate.sql — METRIK HARIAN ABSENSI RATE
-- Persentase mahasiswa aktif angkatan 2023 yang hadir ke kampus setiap hari.
-- ============================================================

SELECT
    d.full_date AS tanggal,
    ROUND(100.0 * SUM(CASE WHEN f.is_hadir = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT f.mahasiswa_key), 2) AS absensi_rate
FROM fact_presensi f
JOIN dim_mahasiswa m ON f.mahasiswa_key = m.mahasiswa_key
JOIN dim_date d ON f.date_key = d.date_sk
WHERE m.angkatan = 2023
  AND m.is_current = TRUE
GROUP BY d.full_date
ORDER BY d.full_date;