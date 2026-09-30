-- ============================================================
-- sql/load.sql — URUTAN EKSEKUSI MILIK TIM (TUGAS D3)
-- Isi dengan perintah yang membangun warehouse dari nol, dalam urutan yang benar.
-- Jalankan:  python -m pipeline.load --topic t1 --slice k5 --twice
--
-- Aturan urutan: dimensi dulu (kecuali dim_date), fact terakhir.
-- Setiap tabel ditulis dengan CREATE OR REPLACE ... AS SELECT (idempoten secara konstruksi).
-- Kalau memilih strategi lain (upsert / DELETE partisi), tulis di pipeline/DESIGN_load.md
-- dan jelaskan kenapa dan kapan strategi itu bisa menggandakan baris.
--
-- Placeholder di bawah ini SENGAJA bertanda TODO supaya loader menolak jalan sampai kamu isi.
-- ============================================================

-- TODO: salin/tulis DDL dimensi + fact kamu di sql/20_*.sql dan sql/30_*.sql,
--       lalu satukan di sini dalam urutan yang benar. Contoh bentuk:

SOURCE sql/10_dim_date.sql;
SOURCE sql/20_dim_date.sql;
SOURCE sql/20_dim_mahasiswa.sql;
SOURCE sql/20_dim_matakuliah.sql;
SOURCE sql/30_fact_presensi.sql;