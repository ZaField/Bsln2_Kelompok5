# DESIGN_load — strategi load (UTS item 2)

> Diisi tim. Tiga hal wajib ada. Kalau ada satu yang kosong, desainnya belum bisa dieksekusi
> orang lain — dan itu kriteria penilaian pertama rubrik.

## Alur: sumber → staging → dim → fact

`sql/load.sql` membangun semua tabel dari nol dalam satu run. Setiap tabel memakai
`CREATE OR REPLACE TABLE ... AS SELECT`, jadi idempoten secara konstruksi. Tidak ada tabel
staging fisik: tahap staging adalah subquery di dalam SQL fact (baca CSV → dedup → parse tanggal).
Alternatif yang ditolak: (a) tabel staging fisik, karena menambah objek tanpa manfaat untuk 38 ribu
baris; (b) upsert/MERGE, karena butuh change log perubahan mahasiswa yang tidak ada di sumber.

| # | Tabel | Sumber | Strategi | Kapan menggandakan baris |
|---|---|---|---|---|
| 1 | `dim_date` | generator (rentang 2022-01-01 s.d. 2027-12-31) | `CREATE OR REPLACE` (full) | Tidak bisa: dibangun dari rentang tanggal, bukan dari data. Satu baris Unknown (`date_sk = -1`) ditambahkan. |
| 2 | `dim_mahasiswa` | `mahasiswa.csv`, filter `angkatan = 2023` | `CREATE OR REPLACE` (full); SCD Type 2 | Kalau diganti `INSERT` tanpa mengosongkan tabel: 881 baris jadi 1.762. Kalau diganti upsert SCD2 yang tidak membandingkan atribut: tiap run menambah versi baru untuk nim yang sama. Nim di sumber unik (0 duplikat), jadi full rebuild aman. |
| 3 | `dim_matakuliah` | `matakuliah.csv` | `CREATE OR REPLACE` (full); Type 0 | `INSERT` polos: 12 baris jadi 24. `kode_mk` unik di sumber. |
| 4 | `fact_presensi` | `presensi.csv` | `CREATE OR REPLACE` (full); dedup `ROW_NUMBER()` per `(nim, kode_mk, tanggal terparse)`, simpan `rn = 1` | `INSERT` polos: tiap run menambah 37.002 baris. Tanpa dedup: 1.451 baris kembar persis ikut masuk (38.453 vs 37.002). Upsert dengan kunci yang memuat `pertemuan_ke`: baris kosong (781) tidak pernah cocok sehingga disisipkan ulang tiap run. |

## Tiga pertanyaan wajib

1. **Natural key**
   - `dim_mahasiswa`: `nim`
   - `dim_matakuliah`: `kode_mk`
   - `fact_presensi`: `(nim, kode_mk, tanggal)`. `pertemuan_ke` tidak dipakai karena kosong di 781 baris.
2. **Kolom partisi / window incremental**: tidak dipakai, karena full rebuild dan volumenya kecil
   (37.002 baris, 14 tanggal pertemuan). Jika nanti incremental, kolomnya `tanggal`.
3. **Kapan menggandakan baris jika dijalankan dua kali**: lihat kolom terakhir tabel di atas.
   Dengan strategi yang dipilih, `--twice` menghasilkan jumlah baris sama:
   dim_date 2.192, dim_mahasiswa 881, dim_matakuliah 12, fact_presensi 37.002.
   Surrogate key (`ROW_NUMBER()`) dibuat ulang tiap run, tetapi semua tabel dibangun ulang dalam run
   yang sama, sehingga fact selalu konsisten dengan dimensinya.

## Urutan dependency

1. `10_dim_date.sql`: pertama, karena fact bergabung ke dim_date.
2. `20_dim_date.sql`: menambah kolom `academic_semester` pada tabel yang sudah ada.
3. `20_dim_mahasiswa.sql`: tidak bergantung pada tabel lain.
4. `20_dim_matakuliah.sql`: tidak bergantung pada tabel lain. (Poin 3–4 boleh dibalik.)
5. `30_fact_presensi.sql`: terakhir, karena bergabung ke ketiga dimensi.