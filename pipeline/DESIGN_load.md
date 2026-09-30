# DESIGN_load — strategi load (UTS item 2)

> Diisi tim. Tiga hal wajib ada. Kalau ada satu yang kosong, desainnya belum bisa dieksekusi
> orang lain — dan itu kriteria penilaian pertama rubrik.

## Alur: sumber → staging → dim → fact

| # | Tabel | Sumber | Strategi | Kapan menggandakan baris kalau dianggap benar |
|---|---|---|---|---|
| 1 | `dim_date` | generator (diberikan) | `CREATE OR REPLACE` (full) | — tidak bisa: dibangun dari rentang tanggal, bukan dari data |
| 2 | `dim_mahasiswa` | `data/raw/t1_kampus/mahasiswa.csv` | Upsert by `nim` with SCD Type 2 (track `valid_from`/`valid_to`) | Jika data sumber memiliki perubahan pada `prodi` atau `status` untuk sama `nim` dan dijalankan dua kali tanpa deteksi perubahan, maka akan membuat baris baru yang tidak diperlukan (duplikasi histori) |
| 3 | `dim_matakuliah` | `data/raw/t1_kampus/matakuliah.csv` | Upsert by `kode_mk` (Type 0 - overwrite) | Tidak boleh: karena ada satu baris per `kode_mk`, upsert dengan kunci alami akan mengganti, tidak menambahkan |
| 4 | `fact_presensi` | `data/raw/t1_kampus/presensi.csv` | Append-only dengan deduplikasi pada kunci alami `(nim, kode_mk, tanggal, pertemuan_ke)` | Jika baris sumber memiliki kombinasi sama `(nim, kode_mk, tanggal, pertemuan_ke)` dan nilai yang berbeda (misal `status` berubah), maka akan membuat duplikasi fakta yang tidak boleh ada karena satu pertemuan hanya boleh satu status kehadiran |

## Tiga pertanyaan wajib

1. **Natural key** yang dipakai untuk upsert/incremental: 
   - `dim_mahasiswa`: `nim`
   - `dim_matakuliah`: `kode_mk`
   - `fact_presensi`: `(nim, kode_mk, tanggal, pertemuan_ke)`

2. **Kolom partisi atau window** kalau incremental (mis. `tanggal`):
   - `dim_mahasiswa`: Tidak menggunakan partisi (ukuran kecil), tetapi window incremental bisa menggunakan `tanggal_masuk` atau `updated_at` jika ada
   - `dim_matakuliah`: Tidak menggunakan partisi (referensi kecil, tetap di-refresh seluruhnya)
   - `fact_presensi`: Partisi oleh `tanggal` (bulanan atau tahunan) untuk optimasi query historical data

3. **Kapan strategi ini menggandakan baris kalau dijalankan dua kali** — nyatakan sendiri:
   - `dim_mahasiswa`: Jika menjalankan dua kali tanpa mendeteksi perubahan pada data sumber (misal: tidak memeriksa checksum atau timestamp), maka akan membuat dua baris SCD Type 2 yang identik untuk sama `nim` dan periode waktu yang sama, yang merupakan duplikasi yang tidak sah.
   - `dim_matakuliah`: Tidak akan menggandakan baris karena menggunakan kunci alami `kode_mk` sebagai kondisi dalam `MERGE` atau `UPSERT` — baris dengan `kode_mk` yang sama akan diupdate, tidak disisipkan.
   - `fact_presensi`: Jika tidak melakukan deduplikasi pada kunci alami `(nim, kode_mk, tanggal, pertemuan_ke)` sebelum menyisipkan, maka menjalankan dua kali dengan data sumber yang sama akan membuat dua baris fakta yangidentik untuk kejadian presensi yang sama, yang melanggar biji fakta (satu baris per kejadian).

## Urutan dependency

Tulis urutan eksekusi yang benar dan alasannya (tabel mana harus ada sebelum yang lain):
1. `10_dim_date.sql` — harus terlebih dahulu karena merupakan dimensi konform yang digunakan oleh semua fact dan dimensi lain sebagai referensi waktu.
2. `20_dim_date.sql` — mengkolom `academic_semester` ke tabel tanggal yang sudah ada, tetap tidak menghambat karena hanya menambahkan kolom.
3. `20_dim_mahasiswa.sql` — bergantung hanya pada dimensi tanggal (untuk validasi tanggal, meskipun tidak langsung di-JOIN dalam definisi tabelnya, namun baik untuk konsistensi).
4. `20_dim_matakuliah.sql` — independen dari dimensi lain, hanya mengandung data kursus mentah.
5. `30_fact_presensi.sql` — harus terakhir karena bergantung pada ketiga dimensi: tanggal (untuk waktu), mahasiswa (untuk identitas siswa), dan matakuliah (untuk mata kuliah). Fact tidak boleh dimuat sebelum dimensi terkait karena akan gagal melakukan JOIN atau menghasilkan kunci asing yang tidak terdefinisi.