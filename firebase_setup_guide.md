# Panduan Integrasi Firebase (Aestral)

Dokumen ini berisi panduan langkah-demi-langkah bagi Anda untuk menyiapkan Firebase Console dan menghubungkannya dengan aplikasi **Aestral** Anda. 

Karena aplikasi Aestral dilengkapi dengan sistem **Local Fallback (Luring)**, aplikasi akan tetap berfungsi secara lokal menggunakan `SharedPreferences` jika Firebase belum dikonfigurasi. Namun, untuk mengaktifkan sinkronisasi Cloud (Google Sign-In & Firestore), ikuti langkah di bawah ini.

---

## Langkah 1: Membuat Proyek Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/) di peramban Anda.
2. Klik tombol **Add Project** (Tambah Proyek).
3. Masukkan nama proyek: `aestral` (atau nama lain yang Anda sukai).
4. Di bagian Google Analytics, Anda bisa mengaktifkan atau menonaktifkannya (disarankan dinonaktifkan untuk mempercepat inisialisasi).
5. Klik **Create Project** dan tunggu hingga proyek siap, lalu klik **Continue**.

---

## Langkah 2: Mengaktifkan Layanan Firestore Database

Firestore digunakan untuk menyimpan profil kelahiran Weton/astrologi pengguna.

1. Pada menu sebelah kiri di Firebase Console, pilih **Build** > **Firestore Database**.
2. Klik tombol **Create Database**.
3. Pilih lokasi database terdekat (misalnya: `asia-southeast2` untuk Jakarta, atau `asia-southeast1` untuk Singapura). Klik **Next**.
4. Pilih opsi **Start in test mode** (Mode Pengujian) untuk mempermudah pengerjaan awal tanpa aturan keamanan yang rumit. Klik **Create**.
5. Database Firestore Anda sekarang aktif dan siap digunakan.

---

## Langkah 3: Mengaktifkan Google Sign-In di Firebase Auth

1. Pada menu sebelah kiri di Firebase Console, pilih **Build** > **Authentication**.
2. Klik tombol **Get Started**.
3. Di tab **Sign-in method**, pilih **Google** dari daftar penyedia (*Sign-in providers*).
4. Klik tombol *toggle* **Enable**.
5. Masukkan **Project public-facing name** (misal: `Aestral`) dan pilih **Project support email** (email Anda).
6. Klik **Save**.
7. *(Khusus Android)*: Di bagian bawah setelan Google, Anda akan melihat informasi mengenai SHA-1 fingerprint. Ini diperlukan agar Google Sign-In berfungsi di Android asli (lihat Langkah 4).

---

## Langkah 4: Menghubungkan Aplikasi Flutter dengan Firebase

Cara termudah dan paling modern untuk mengonfigurasi Firebase pada aplikasi Flutter adalah menggunakan CLI **FlutterFire**.

### Metode A: Menggunakan FlutterFire CLI (Direkomendasikan & Otomatis)

1. Buka terminal (CMD / PowerShell) di komputer Anda.
2. Pasang Firebase CLI secara global jika belum ada:
   ```bash
   npm install -g firebase-tools
   ```
3. Lakukan login ke akun Google Firebase Anda lewat CLI:
   ```bash
   firebase login
   ```
4. Aktifkan FlutterFire CLI secara global:
   ```bash
   dart pub global activate flutterfire_cli
   ```
5. Jalankan perintah konfigurasi otomatis di dalam direktori proyek Anda (`c:\Users\Falah\Documents\aestral`):
   ```bash
   flutterfire configure
   ```
6. Ikuti panduan di layar: pilih proyek Firebase `aestral` yang baru dibuat, lalu pilih platform yang Anda inginkan (Android, iOS, Web). Perintah ini akan otomatis membuat berkas `lib/firebase_options.dart` dan menyisipkan berkas konfigurasi native.

---

### Metode B: Konfigurasi Manual per Platform

Jika tidak ingin menggunakan CLI, Anda bisa mendaftarkan aplikasi secara manual di Firebase Console:

#### 1. Untuk Web (Chrome / Edge)
1. Di halaman ringkasan Firebase Console, klik ikon **Web** (tanda `</>`).
2. Masukkan nama aplikasi (misal: `Aestral Web`) dan klik **Register App**.
3. Firebase akan menampilkan objek konfigurasi berisi kunci API (`apiKey`, `authDomain`, dll.). Anda tidak perlu menyalinnya ke HTML; FlutterFire CLI di Metode A akan menyimpannya dengan rapi di `lib/firebase_options.dart`.

#### 2. Untuk Android
1. Di halaman ringkasan Firebase Console, klik **Add App** > pilih ikon **Android**.
2. Masukkan Android Package Name: `com.aestral.aestral` (sesuai package name proyek kita).
3. Masukkan sertifikat SHA-1 (diperlukan untuk Google Sign-In di Android):
   * Jalankan perintah ini di terminal proyek untuk mendapatkan SHA-1 komputer Anda:
     ```bash
     keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore
     ```
     *(Password bawaan keystore debug adalah: `android`)*. Salin kode SHA-1 yang muncul ke kolom di Firebase Console.
4. Klik **Register App**, lalu unduh berkas **`google-services.json`**.
5. Letakkan berkas `google-services.json` tersebut ke direktori proyek Anda di:
   `c:\Users\Falah\Documents\aestral\android\app\google-services.json`
6. Selesai!

---

## Dukungan Windows Desktop (Offline Fallback)
Firebase Auth dan Firestore belum mendukung platform **Windows Desktop** secara native secara penuh tanpa plugin C++ khusus yang kompleks. Oleh karena itu, jika Anda menjalankan aplikasi Aestral sebagai **Windows Desktop App**, aplikasi akan secara otomatis masuk ke **Local Fallback Mode** (menggunakan SharedPreferences lokal untuk menyimpan data tamu), yang dirancang untuk kenyamanan pengujian instan Anda.
