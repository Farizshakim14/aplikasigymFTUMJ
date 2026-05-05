# Dokumen Use Case - Sistem Manajemen Gym Fakultas Teknik UMJ

Dokumen ini merupakan panduan Use Case terpadu yang mendeskripsikan fungsionalitas dan interaksi dari seluruh aktor pada Sistem Manajemen Gym FT-UMJ, yang mencakup aplikasi *Mobile* (Flutter) dan *Web Dashboard*.

## 1. Daftar Aktor (Actors)

Sistem ini memiliki 3 aktor utama dengan hak akses dan *platform* yang berbeda:

| Aktor | Platform | Deskripsi |
|---|---|---|
| **Member** | Aplikasi HP (Flutter) | Mahasiswa/pengguna biasa yang menggunakan aplikasi untuk mendaftar, memesan jadwal latihan, dan melakukan absensi (Scan QR). |
| **Admin Gym** | Website | Pengelola operasional gym yang mengatur jadwal slot latihan, menyetujui *booking*, menghapus *user* secara permanen, dan membuat laporan. |
| **Wadek II** | Website | Eksekutif/Pimpinan (Wakil Dekan II) yang bertugas memantau seluruh aktivitas gym secara *read-only* dan memverifikasi laporan dari Admin. |

---

## 2. Use Case Diagram Terpadu

Di dalam sistem berorientasi objek (UML), Aktor tidak terhubung langsung dengan Aktor lain, melainkan mereka **bertemu pada proses (Use Case) yang saling berkaitan**. Berikut adalah visualisasi interaksinya:

```mermaid
usecaseDiagram
    actor Member as "Member (Aplikasi)"
    actor Admin as "Admin Gym (Website)"
    actor Wadek2 as "Wadek II (Website)"

    package "Sistem Manajemen Gym FT-UMJ" {
        %% Use Case Member %%
        usecase UC1 as "Registrasi & Kelola Profil"
        usecase UC2 as "Melihat & Memilih Slot Latihan"
        usecase UC3 as "Melakukan Booking (Status Pending)"
        usecase UC4 as "Melakukan Absensi (Scan QR)"
        usecase UC5 as "Melihat Riwayat Aktivitas"
        usecase UC6 as "Melihat Rekomendasi Nutrisi & Latihan"
        usecase UC7 as "Melihat Panduan Gerakan Gym"
        
        %% Use Case Admin %%
        usecase UC8 as "Kelola Data User (Termasuk Hapus)"
        usecase UC9 as "Kelola Slot Latihan (Kapasitas & Gender)"
        usecase UC10 as "Validasi Booking (ACC/Tolak)"
        usecase UC11 as "Kelola Absensi & Buat Laporan"
        
        %% Use Case Wadek II %%
        usecase UC12 as "Monitoring Data Operasional (Read-Only)"
        usecase UC13 as "Verifikasi Laporan (Setujui/Tolak)"
    }

    %% Tarikan Garis Member %%
    Member --> UC1
    Member --> UC2
    Member --> UC3
    Member --> UC4
    Member --> UC5
    Member --> UC6
    Member --> UC7

    %% Tarikan Garis Admin %%
    Admin --> UC8
    Admin --> UC9
    Admin --> UC10
    Admin --> UC11

    %% Tarikan Garis Wadek II %%
    Wadek2 --> UC12
    Wadek2 --> UC13
    
    %% RELASI ANTAR PROSES (MENGHUBUNGKAN AKTOR SECARA TIDAK LANGSUNG) %%
    UC3 ..> UC2 : <<includes>>
    
    %% Relasi User -> Admin %%
    UC1 <.. UC8 : <<manages>>
    UC3 <.. UC10 : <<verifies>>
    UC4 <.. UC11 : <<recapitulates>>
    
    %% Relasi Admin -> Wadek II %%
    UC11 <.. UC13 : <<approves>>
```

---

## 3. Deskripsi Skenario & Relasi Antar Aktor

### A. Aktor: Member (Aplikasi Mobile)
1. **Registrasi & Kelola Profil Pribadi**: Member membuat akun dan melengkapi profil. *(Berelasi dengan UC8: Data ini nantinya dipantau dan bisa dihapus oleh Admin).*
2. **Melihat & Memilih Slot Latihan**: Member melihat jadwal yang tersedia yang sebelumnya **telah dibuat oleh Admin** pada (UC9).
3. **Melakukan Booking**: Member mengirimkan permintaan *booking* berstatus **Pending**. *(Berelasi kuat dengan UC10: Permintaan ini akan masuk ke dashboard Admin untuk di-ACC atau Ditolak).*
4. **Melakukan Absensi (Scan QR)**: Member melakukan *Check-In* dan *Check-Out*. *(Berelasi dengan UC11: Data absensi ini direkap oleh Admin untuk dijadikan laporan bulanan).*
5. **Melihat Riwayat Aktivitas**: Member melihat catatan historis *booking* dan absensi.
6. **Melihat Rekomendasi Nutrisi & Latihan**: Sistem menampilkan rencana aktivitas fisik dan anjuran asupan nutrisi yang dipersonalisasi.
7. **Melihat Panduan Gerakan Gym**: Member mengakses tutorial teknik gerakan yang benar.

### B. Aktor: Admin Gym (Web Dashboard)
1. **Kelola Data User (CRUD)**: Admin memantau, mengedit, atau menghapus permanen data akun yang **didaftarkan oleh Member** (UC1).
2. **Kelola Slot Latihan**: Admin mengatur slot (waktu, kuota, gender) yang nantinya **akan di-booking oleh Member** (UC2).
3. **Validasi Booking (ACC/Tolak)**: Mengelola permintaan *booking* (UC3) dari Member. Saat di-ACC, sisa kapasitas slot akan berkurang.
4. **Kelola Absensi & Buat Laporan**: Admin menarik data absensi (UC4) yang dilakukan Member, menyusunnya menjadi draf laporan, lalu mengirimkannya kepada Wadek II. *(Berelasi dengan UC13: Laporan menunggu persetujuan Wadek II).*

### C. Aktor: Wakil Dekan II (Web Dashboard)
1. **Monitoring Data Operasional**: Memantau ringkasan statistik (jumlah member, sesi aktif, grafik absensi) dari aktivitas yang dilakukan Member dan Admin secara *read-only*.
2. **Memverifikasi Laporan**: Menerima laporan dari Admin (UC11). Wadek II memverifikasinya (UC13) menjadi **Disetujui** (bisa diunduh sebagai PDF/Excel) atau **Ditolak** untuk direvisi kembali oleh Admin.

---

## 4. Aturan Bisnis Penting (Business Rules)

1. **Validasi Kesesuaian Gender**: Aplikasi aktif memblokir member perempuan yang mencoba mem-*booking* slot khusus laki-laki, begitu pula sebaliknya.
2. **Logika Pengurangan Kapasitas Slot (Sinkronisasi)**: Tindakan *booking* dari HP tidak langsung memotong kuota slot. Pemotongan murni terjadi dari sisi Web ketika Admin melakukan ACC (UC10), mencegah penyalahgunaan slot.
3. **Penghapusan Akun Aman**: Penghapusan akun member dari Web Admin dieksekusi melewati *backend* terpusat (Node.js) sehingga kredensial Firebase Authentication ikut terhapus bersih.
