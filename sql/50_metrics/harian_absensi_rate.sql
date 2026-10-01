-- ============================================================
-- 50_metrics/harian_absensi_rate.sql — METRIK HARIAN ABSENSI RATE
-- Persentase mahasiswa aktif angkatan 2023 yang hadir ke kampus setiap hari.
-- ============================================================

SELECT
    d.full_date AS tanggal,
    ROUND(100.0 * AVG(f.is_hadir), 2) AS absensi_rate
FROM fact_presensi f
JOIN dim_date d ON f.date_key = d.date_sk
GROUP BY d.full_date
ORDER BY d.full_date;