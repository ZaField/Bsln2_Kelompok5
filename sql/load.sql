-- ============================================================
-- sql/load.sql — URUTAN EKSEKUSI MILIK TIM (TUGAS D3)
-- Isi dengan perintah yang membangun warehouse dari nol, dalam urutan yang benar.
-- Jalankan:  python -m pipeline.load --topic t1 --slice k5 --twice
--
-- Aturan urutan: dimensi dulu (kecuali dim_date), fact terakhir.
-- Setiap tabel ditulis dengan CREATE OR REPLACE ... AS SELECT (idempoten secara konstruksi).
-- Kalau memilih strategi lain (upsert / DELETE partisi), tulis di pipeline/DESIGN_load.md
-- dan jelaskan kenapa dan kapan strategi itu bisa menggandakan baris.
-- ============================================================

-- ============================================================
-- 10_dim_date.sql — DIBERIKAN LENGKAP. Ini bukan checkpoint, ini alat.
-- Konformed dimension: SEMUA fact di warehouse ini menunjuk ke sini.
-- ============================================================

CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(strftime(d, '%Y%m%d') AS INTEGER) AS date_sk,   -- kunci: YYYYMMDD, bukan urutan
       d AS full_date,
       CAST(year(d)  AS INTEGER) AS tahun,
       CAST(quarter(d) AS INTEGER) AS triwulan,
       CAST(month(d) AS INTEGER) AS bulan,
       strftime(d, '%B') AS nama_bulan,
       CAST(week(d)  AS INTEGER) AS pekan_iso,
       CAST(day(d)   AS INTEGER) AS hari,
       CAST(dayofweek(d) AS INTEGER) AS hari_ke,            -- 0 = Minggu
       strftime(d, '%A') AS nama_hari,
       CAST(dayofweek(d) IN (0, 6) AS BOOLEAN) AS akhir_pekan
FROM (SELECT unnest(generate_series(DATE '2022-01-01', DATE '2027-12-31', INTERVAL 1 DAY)) AS d);

-- Anggota Unknown: banyak pipeline gagal bukan karena datanya salah, tapi karena ada baris
-- yang tidak punya tanggal. Baris seperti itu tetap harus punya tempat.
INSERT INTO dim_date
SELECT -1, DATE '1900-01-01', 1900, 0, 0, 'TIDAK DIKETAHUI', 0, 0, -1, 'TIDAK DIKETAHUI', FALSE;


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
  TRUE AS is_current   -- Type 2: satu snapshot = satu versi per mahasiswa, jadi semua baris adalah versi terkini
FROM (
  SELECT
    CAST(nim AS VARCHAR) AS nim,
    nama,
    angkatan,
    prodi,
    status,
    kota_asal,
    tanggal_masuk
  FROM read_csv_auto('data/raw/t1_kampus/mahasiswa.csv')
  WHERE angkatan = 2023  -- Slice k5 untuk Grup 5 (Angkatan 2023)
    AND nim IS NOT NULL
    AND TRIM(CAST(nim AS VARCHAR)) <> ''
);


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


-- ============================================================
-- TUGAS TIM (D2 / UTS item 1.1, 1.2, 1.4) — fact table
-- Satu fact saja. Grain ditulis lengkap di komentar, bukan singkatan.
-- ============================================================

-- GRAIN: Satu baris = satu mahasiswa pada satu mata kuliah pada satu tanggal pertemuan.
--   Kunci alami: (nim, kode_mk, tanggal). pertemuan_ke = degenerate dimension, BUKAN bagian kunci
--   (kosong di 781 baris sumber).
-- Aturan status: 'H' = hadir (singkatan). '-' tidak punya arti terdokumentasi; DIPETAKAN KE ALPA sebagai
--   ASUMSI (jam_masuk kosong seperti ALPA). Pada data ini empat flag saling lepas dan lengkap (jumlah = 1).
-- Aditivitas: is_hadir/is_izin/is_sakit/is_alpa = ADDITIVE (flag 0/1, boleh di-SUM lintas dimensi).
--   jam_masuk = NON-ADDITIVE (teks 'H:MM', tidak bermakna dijumlah; terisi juga untuk izin/sakit,
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
  AND CAST(p.nim AS VARCHAR) != ''
  AND p.kode_mk IS NOT NULL
  AND p.kode_mk != ''
  AND p.tanggal IS NOT NULL;
