# Aplikasi Rekomendasi Gym Berbasis AI

Sebuah aplikasi mobile cerdas berbasis **Flutter** yang dirancang untuk memberikan rekomendasi program kebugaran secara personal. Aplikasi ini secara unik mengimplementasikan algoritma **Kecerdasan Buatan (Machine Learning)** murni di sisi perangkat genggam (tanpa server AI eksternal).

Aplikasi ini dapat membantu pengguna untuk memprediksi kebutuhan kalori harian, menyusun jadwal latihan yang tepat, serta memberikan rekomendasi menu diet nutrisi berdasarkan tujuan akhir pengguna, baik untuk **Bulking**, **Cutting**, maupun **Maintain**.

---

## 🚀 Fitur Utama

- **Autentikasi Aman:** Sistem pendaftaran, login, dan lupa password menggunakan *Firebase Authentication*.
- **Rekomendasi Cerdas:** Memberikan saran menu diet dan pola latihan fisik berdasarkan Kategori BMI dan Tujuan (*Goal*).
- **Kalkulasi Makronutrisi Otomatis:** Perhitungan presisi kebutuhan asupan Karbohidrat, Protein, Lemak, dan Total Kalori Harian.
- **Penyimpanan Riwayat Terekam:** Data metrik tubuh dan histori rekomendasi pengguna disimpan secara aman di *Firebase Realtime Database*.

---

## 🧠 Algoritma Machine Learning Terapan

Aplikasi ini adalah bentuk implementasi nyata dari penerapan metode AI pada aplikasi mobile. Berikut adalah dua algoritma utama yang bekerja di dalam sistem:

### 1. Decision Tree Regression (Pohon Keputusan)
Metode *Rule-Extraction* ini digunakan untuk **Memprediksi Target Kalori Harian (BMR)**. 
Pohon keputusan diekstrak dari dataset (*Data-driven*) menggunakan kalkulasi *Information Gain* pada fitur utamanya (Berat Badan, Tinggi Badan, Jenis Kelamin). Hasilnya berupa titik potong (*Split Points*) berupa logika if-else bertingkat yang sangat akurat dan terkalibrasi untuk memprediksi baseline kalori (*lihat implementasi detail pada `lib/pages/rekomendasi_page.dart`*).

### 2. K-Nearest Neighbor (K-NN)
Metode *Pencarian Jarak Terdekat* digunakan untuk **Memprediksi Kalori yang Terbakar Secara Aktual**. 
Alih-alih menebak, sistem akan melakukan iterasi pencarian kemiripan terhadap ribuan histori riwayat anggota gym terdahulu. Sistem akan menghitung selisih metrik terkecil (BMI dan Gender) untuk memprediksi kalori yang akan dihabiskan pengguna jika ia mengikuti program latihan yang disarankan.

---

## 📁 Penggunaan Dataset

Sistem ini didukung oleh *knowledge-base* (basis pengetahuan) dan dataset pendukung berikut:
- **`assets/dataset_gym.csv`**: File dataset mentah yang menjadi referensi parameter model regresi pada Decision Tree.
- **`assets/GYM.json`**: Dataset berstruktur tinggi (telah dioptimasi dan diringkas) yang berperan sebagai basis pengetahuan rekomendasi latihan dan pola makan.
- **`assets/gym_members_exercise_tracking.json`**: Dataset histori jejak durasi latihan dan pencatatan detak jantung *member gym* untuk logika algoritma K-NN.

---

## 🛠️ Stack Teknologi

- **Frontend & UI:** Flutter (Dart)
- **Backend Service:** Google Firebase (Realtime DB & Auth)
- **AI Core:** Decision Tree & K-NN (Native Dart Implementation)

---

## 💻 Panduan Instalasi (Untuk Pengembang)

1. Pastikan mesin Anda sudah terpasang **Flutter SDK**.
2. *Clone* atau unduh repositori ini ke folder lokal Anda.
3. Buka terminal di direktori proyek (`aplikasigym`) lalu sinkronkan *dependencies*:
   ```bash
   flutter pub get
   ```
4. Mengingat aplikasi ini menggunakan Firebase, pastikan konfigurasi koneksi (`google-services.json` atau `firebase_options.dart`) sudah terhubung sempurna.
5. Jalankan aplikasi pada *Emulator* atau *Device* Anda:
   ```bash
   flutter run
   ```
