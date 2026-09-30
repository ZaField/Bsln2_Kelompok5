# D6 — Batas Desain — Pertanyaan yang Tidak Terjawab

## Pertanyaan yang Tidak Terjawab

Bagaimana perubahan dalam program studi (prodi) atau status mahasiswa memengaruhi kehadiran mereka?

## Mengapa Desain Tidak Mampu Menjawabnya

Desain saat ini tidak dapat menjawab pertanyaan ini karena sumber data `mahasiswa.csv` hanya menyediakan **satu kali snapshot** tanpa riwayat perubahan. Dalam data ini:

- Setiap mahasiswa memiliki tepatnya **satu rekaman SCD2**
- `valid_from` diatur` diatur ke `tanggal_masuk` (tanggal mulai kuliah)
- `valid_to` diatur ke `'9999-12-31'` (masa depan abadi)
- `is_current` disetel ke `TRUE` untuk semua mahasiswa yang aktif

Ini berarti tidak ada **variasi temporal** yang direkam dalam data - semua mahasiswa tampak seperti telah berada dalam program/status mereka sejak waktu pendaftaran. Meskipun kerangka SCD2 ada, ia tidak mengandung perubahan sebenarnya yang dapat dianalisis.

## Apa yang Diperlukan untuk Menjawab Pertanyaan Ini

Untuk menganalisis bagaimana perubahan dalam program (`prodi`) atau status memengaruhi kehadiran, kita perlu salah satu dari berikut:

### 1. **Catatan Perubahan (Change Log)**
Sebuah tabel yang menangkap pembaruan ke rekaman mahasiswa (dengan cap waktu kapan `prodi` atau `status` berubah), dengan struktur seperti:
- `nim`
- `field_ubah` (`prodi` atau `status`)
- `nilai_lama`
- `nilai_baru`
- `timestamp_perubahan`

### 2. **Snapshot Periodik**
Ekspor periodik dari data `mahasiswa` (misalnya, ekspor bulanan) yang menunjukkan kapan mahasiswa berganti program atau mengubah status.

Dengan data seperti ini, tabel dimensi `dim_mahasiswa` SCD2 akan dapat dengan benar mencerminkan perubahan temporal, memungkinkan analisis seperti:

- Apakah tingkat kehadiran berubah setelah siswa berpindah dari suatu program studi ke program lain?
- Bagaimana perbedaan kehadiran ketika mahasiswa berada pada status `cuti` (cuti) vs `aktif` (aktif)?
- Apakah mahasiswa yang berpindah program menunjukkan pola kehadiran yang berbeda sebelum dan sesudah perpindahan?
- Apakah ada korelasi antara frequensi perubahan status dan tingkat kehadiran secara keseluruhan?

## Dampak pada Analisis

Tanpa variasi historis dalam data sumber, model dimensi SCD2 tidak dapat memberikan wawasan mengenai bagaimana perubahan program/status memengaruhi perilaku kehadiran. Analisis yang mungkin kita lakukan hanya terbatas pada:
- Kehadiran berdasarkan program/status **saat ini** saja
- Pola kehadiran seperti biasa tanpa konteks perubahan historis