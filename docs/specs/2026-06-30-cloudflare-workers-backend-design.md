# Spesifikasi Desain: Backend Cloudflare Workers Aestral (Fokus Tarot & Weton)

Dokumen ini mendefinisikan arsitektur, rute API, alur autentikasi, serta pembatasan akses Tamu (Guest) vs Pengguna Terdaftar untuk sistem Tarot dan Weton berbasis Cloudflare Workers.

---

## 1. Arsitektur Umum & Batasan
* **Teknologi**: Cloudflare Workers (TypeScript)
* **Hosting**: Cloudflare Free Tier (Batas: 50ms CPU execution time, 1MB script size).
* **Autentikasi**:
  * **Pengguna Terdaftar**: Wajib menyertakan token Firebase Auth JWT asli di header `Authorization: Bearer <JWT_TOKEN>`.
  * **Pengguna Tamu (Guest)**: Mengirimkan identitas tamu di header `Authorization: Guest <DEVICE_ID_OR_ANON_UID>`.
* **CORS**: Mengizinkan akses origin Flutter Web (`http://localhost:*` untuk dev) serta aplikasi mobile.

---

## 2. Struktur Akses & Logika Determinisme: Tamu vs Terdaftar

### Alur Masuk Akun Tamu (Guest):
1. Saat pertama kali masuk aplikasi, Tamu ditanyakan **Tanggal Lahir**-nya.
2. Aplikasi menghitung Weton Lahir secara lokal/statis.
3. Untuk penarikan Tarot dan Weton Harian/Mingguan:
   * **Tarot**: Penarikan dihitung secara deterministik menggunakan **Tanggal Lahir / Weton Lahir** sebagai *seed*. Hasilnya adalah **"Kartu Tarot Lahir / Kartu Jiwa"** yang 100% statis (tidak berubah jika diulang).
   * **Weton Harian & Mingguan**: Terkunci pada analisis statis weton/wuku lahir pengguna saja.

### Perbandingan Akses:

| Fitur | Pengguna Tamu (Guest) | Pengguna Terdaftar |
| :--- | :--- | :--- |
| **Input Awal** | Mengisi Tanggal Lahir saat masuk. | Profil Tanggal Lahir tersimpan di Cloud. |
| **Karakter Weton Lahir** | Tersedia (Statis berdasarkan tanggal lahir). | Tersedia + Sinkronisasi Lintas Perangkat. |
| **Tarot Draw** | **Statis (Soul Card)**: Dihitung secara deterministik berbasis Tanggal Lahir pengguna. Kartu yang sama akan selalu muncul jika diulang. | **Dinamis (Daily Draw)**: Weighted RNG aktif menggunakan kombinasi Weton lahir + Wuku/Neptu hari berjalan. Kartu berubah setiap hari. |
| **Weton Harian & Mingguan**| **Statis**: Hanya menampilkan analisis Wuku lahir pengguna. Hasil sisa bagi harian dikunci (tidak berubah). | **Dinamis**: Berubah harian/mingguan berdasarkan tanggal berjalan (`targetDate`) + Checklist 3 Aktivitas Harian. |

---

## 3. Desain Rute API

### A. Penarikan Tarot (`POST /api/tarot/draw`)
Menggambar kartu Tarot dengan logika adaptif berdasarkan status autentikasi pengguna.

* **Payload Request (JSON)**:
  ```json
  {
    "birthDate": "1995-10-25",
    "pangarasan": "Lakuning Geni",
    "wukuHariIni": "Dhukut"
  }
  ```
* **Logika Backend**:
  1. Periksa header `Authorization`.
  2. **Kasus A: Pengguna Tamu (`Guest <GUEST_ID>`)**:
     * Gunakan string `birthDate` pengguna sebagai benih acak deterministik (*deterministic seed*):
       `seed = stringToHash(birthDate)`
       `cardIndex = seed % 78`
     * Ambil kartu Tarot pada indeks tersebut.
     * Kembalikan respons dengan flag `"isDynamic": false` dan pesan petunjuk bahwa ini adalah **"Kartu Jiwa (Soul Card)"** statis mereka yang mewakili energi kelahiran mereka. Untuk menarik ramalan harian dinamis, mereka harus mendaftar.
  3. **Kasus B: Pengguna Terdaftar (`Bearer <JWT_TOKEN>`)**:
     * Verifikasi JWT Token. Jika tidak valid, kembalikan `401 Unauthorized`.
     * Ambil UID terverifikasi dari JWT payload.
     * Terapkan algoritma *Weighted RNG* (pembobotan probabilitas +15% pada elemen penyeimbang berdasarkan pangarasan Weton lahir dan Wuku hari ini).
     * Lakukan penarikan kartu secara acak dinamis.
     * Kembalikan respons dengan flag `"isDynamic": true` dan detail kartu.

### B. Insight Weton Harian & Mingguan (`POST /api/weton/daily`)
Menghitung kecocokan weton hari berjalan dengan weton lahir pengguna.

* **Payload Request (JSON)**:
  ```json
  {
    "birthDate": "1995-10-25",
    "targetDate": "2026-06-30" // Tanggal berjalan yang ingin dicek
  }
  ```
* **Logika Backend**:
  1. Periksa status autentikasi di header `Authorization`.
  2. **Kasus A: Pengguna Tamu**:
     * Abaikan parameter `targetDate`.
     * Hitung sisa bagi dan wuku secara statis murni berdasarkan `birthDate` saja.
     * Kembalikan respons dengan flag `"isDynamic": false`.
  3. **Kasus B: Pengguna Terdaftar**:
     * Verifikasi token JWT.
     * Hitung weton lahir dan weton hari berjalan (`targetDate`).
     * Hitung sisa bagi harian `(Neptu Lahir + Neptu Hari Ini) % 5` dan Wuku mingguan hari berjalan.
     * Ambil data dari `sisabagi.json` dan `wuku.json`.
     * Kembalikan respons detail beserta checklist aktivitas harian dengan flag `"isDynamic": true`.

---

## 4. Alur Autentikasi JWT Firebase (Edge-side Verification)
Kita menggunakan **Web Crypto API** bawaan Cloudflare Workers untuk memvalidasi tanda tangan RS256 token JWT:
1. Ekstrak token dari header `Authorization: Bearer <JWT_TOKEN>`.
2. Dekode bagian Header & Payload JWT.
3. Ambil kunci publik (JWK) dari endpoint Google Public Keys. Hasil fetch JWK akan di-cache di memori Worker selama 1 jam agar respons cepat.
4. Cocokkan Key ID (`kid`) dan verifikasi tanda tangan RS256.
5. Validasi klaim `iss` (Google Firebase Issuer) dan `aud` (Firebase Project ID).
6. Teruskan UID pengguna ke controller logika.

---

## 5. Rencana Verifikasi
* **Unit Testing**: Menggunakan `vitest` dengan `@cloudflare/vitest-pool-workers`.
  * Test 1: Verifikasi bahwa penarikan Tarot oleh Tamu dengan `birthDate` yang sama selalu menghasilkan kartu yang sama (statis).
  * Test 2: Verifikasi bahwa penarikan Tarot oleh Pengguna Terdaftar bervariasi setiap hari/wuku.
  * Test 3: Verifikasi kegagalan token JWT yang tidak valid atau palsu.
