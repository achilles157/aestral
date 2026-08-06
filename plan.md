# `plan.md` - Master Plan Kalkulator Astrologi & Tarot (Zero-Budget Architecture)

## 1. Visi Proyek & Stack Teknologi

Membangun platform pembacaan nasib, personalisasi elemen, dan gamifikasi harian dengan antarmuka yang *aesthetic*, *cute*, dan trendi. Arsitektur dirancang khusus untuk eksekusi *solo-developer* tanpa biaya *server* bulanan, dengan memaksimalkan pemrosesan lokal dan komputasi di jaringan *edge*.

* **Frontend:** Flutter (Dart) untuk UI/UX yang mulus dan animasi interaktif (misal: 3D *card flip*).
* **Database & Autentikasi:** Firebase Spark Plan / Free Tier (Firestore NoSQL, Firebase Auth).
* **Backend Komputasi:** Cloudflare Workers (TypeScript / Node.js) - Eksekusi *serverless* di jaringan *edge* tanpa kartu kredit (kuota 100k *request*/hari).
* **AI Engine:** Gemini API (Google AI Studio - Free Tier) untuk sintesis narasi *copywriting* dan *hyper-personalization*.
* **Monetisasi (Micro-transactions):** Integrasi *payment gateway* lokal (mendukung QRIS, GoPay, ShopeePay, blu by BCA Digital, dll.) serta iklan *rewarded* (Google AdMob).

---

## 2. Fase 1: MVP - Profiling Lokal & Kamus Data Statis

**Tujuan:** Membangun fondasi aplikasi dengan *zero-latency* menggunakan pemrosesan murni di sisi klien (*client-side*) dan pembacaan data *offline-first*.

### 2.1. Manajemen Data Statis (Assets Bundle)
* Semua "Kamus Interpretasi" tidak disimpan di Firestore untuk menghemat kuota *read* dan mempercepat *loading*.
* File `tarot.json`, `kamus-weton.json` (35 kombinasi), dan `bazi-pillars.json` (60 kombinasi Liushijiazi) di-*bundle* langsung ke dalam folder `assets/` di proyek Flutter.
* Aplikasi memuat JSON ke dalam memori saat *startup* menggunakan `rootBundle`.

### 2.2. Modul Primbon Weton (Client-Side)
* **Logic (Dart):** Membuat *utility class* untuk mengonversi kalender Masehi ke *Julian Day Number* (JDN) tanpa memanggil *backend*.
* **Algoritma:** Menghitung modulo untuk *Pancawara* (5 hari) dan *Saptawara* (7 hari) yang disinkronisasi dengan konstanta *Epoch Asapon*.
* **Render UI:** Aplikasi mengambil `weton_name` hasil perhitungan, lalu melakukan *lookup* ke `kamus-weton.json` lokal untuk merender UI 3-Kartu (Karier, Asmara, Peringatan) secara instan.

### 2.3. UI/UX & Autentikasi Dasar
* **Desain:** Palet warna yang memanjakan mata, menyembunyikan data teknis astrologi yang kaku (seperti nilai Neptu/Wuku) ke dalam komponen *dropdown* atau *accordion*.
* **Autentikasi:** Menggunakan Firebase Auth (Google Sign-In). Menyimpan profil tanggal lahir di Firestore (skema *flattening*).

---

## 3. Fase 2: Ekosistem Ba Zi/Saju & Tarot Dinamis (Komputasi Cloudflare)

**Tujuan:** Memindahkan kalkulasi astronomis yang berat dan logika sinkretisme probabilitas ke *backend edge*.

### 3.1. Engine Kalkulasi Ba Zi & Saju
* **Environment:** TypeScript di Cloudflare Workers.
* **Logika Universal:** Ba Zi (Tiongkok) dan Saju (Korea) menggunakan satu *engine* kalkulasi yang sama (menggunakan *library* seperti `@openfate/bazi-engine`).
* **Keamanan:** Memverifikasi token JWT Firebase sebelum mengeksekusi kalkulasi.

### 3.2. Tarot "Weighted RNG" (Sinkretisme Astrologi)
* Penarikan kartu Tarot **TIDAK** dilakukan secara lokal dengan RNG murni, melainkan menggunakan algoritma pembobotan di Cloudflare.
* **Tarot Lahir (Birth Tarot — Semua User):** Kartu deterministik berdasarkan tanggal lahir dan pangarasan. Bersifat statis seumur hidup — blueprint jiwa.
* **Tarot Kosmis (Cosmic Tarot — User Terdaftar):** Sistem menggunakan siklus **Pranata Mangsa** (12 musim) yang sedang berjalan dan membenturkannya dengan elemen Weton pengguna untuk membiaskan probabilitas kartu. Berubah setiap pergantian mangsa (~mingguan).
* **Tarot Mingguan (Weekly Tarot — User Terdaftar):** Menggunakan siklus **Wuku** (30 wuku, berganti setiap 7 hari) sebagai pembobot.
* **Alur Backend:**
  1. Cloudflare menerima *request* penarikan Tarot dari *user*.
  2. Worker mengevaluasi parameter waktu (Mangsa untuk Kosmis, atau Wuku untuk Mingguan) dan profil lahir pengguna.
  3. Worker menerapkan logika *Weighted Random Selection* (Kompensasi & Resonansi elemen).
  4. Worker mengembalikan hasil kartu terpilih beserta *metadata* alasannya ke Flutter.

---

## 4. Fase 3: Integrasi AI (Premium Barnum Effect)

**Tujuan:** Menggunakan LLM untuk menyatukan data astrologi mentah menjadi narasi *copywriting* layaknya sesi konseling privat.

### 4.1. Alur Interaksi AI di Cloudflare
1. Flutter mengirimkan *payload* berisi ID Weton/BaZi pengguna dan konteks waktu (Hari/Minggu) ke *endpoint* Cloudflare.
2. Cloudflare Worker mengeksekusi logika penarikan kartu (Weighted RNG).
3. Cloudflare Worker merakit *System Prompt* komprehensif yang berisi: *Profil Kelahiran (Weton/BaZi)* + *Kartu Tarot Terpilih* + *Alasan Pembobotan Elemen*.
4. Worker meneruskan *prompt* tersebut ke Gemini API.
5. Gemini menyintesis informasi tersebut menjadi *copywriting* yang sangat empatik, kasual, dan relevan, lalu dikembalikan ke UI Flutter.

---

## 5. Strategi Monetisasi (Freemium 3-Tier) — FUTURE SCOPE

> ⚠️ **Status: BELUM DIIMPLEMENTASI.** Fokus saat ini adalah penyempurnaan produk dan UX. Monetisasi akan dikerjakan setelah produk stabil dan mendapatkan traksi pengguna awal.

**Tujuan:** Mengonversi pengguna gratis menjadi pengguna berbayar melalui pemisahan fitur berdasarkan periode waktu.

* **Tier 1: Gratis (The Hook)**
  * Cek Karakter Dasar Weton/Ba Zi secara statis.
  * **Tarot Lahir (Birth Tarot):** Kartu jiwa deterministik seumur hidup.
  * **AI Oracle Chat** dengan kuota harian (Gemini daily quota).
  * *Tujuan:* Akuisisi pengguna dan membangun retensi dasar.

* **Tier 2: Premium / Berlangganan (Subscription)**
  * **Fitur Utama:** Akses penuh tanpa batas ke semua fitur.
  * **Tarot Kosmis & Mingguan:** Variasi draw yang mengikuti siklus alam.
  * **AI Oracle Chat** tanpa batas kuota.
  * **Weton Planner Pro:** Analisis benturan harian mendalam.
  * *Target Harga:* TBD setelah riset pasar.

* **Integrasi Payment:**
  * QRIS, GoPay, ShopeePay, Blu by BCA Digital
  * Google AdMob (rewarded ads untuk tier gratis)

---

## 6. Fase 4: Ekspansi Jangka Panjang (Weda/Jyotish) *COMING SOON*

*(Peringatan: Jangan dieksekusi sebelum Fase 1-3 stabil dan menghasilkan traksi pengguna).*

* Menggunakan Cloudflare Workers dengan integrasi WebAssembly (WASM) atau Golang.
* Mengeksekusi *Swiss Ephemeris* secara ringan untuk kalkulasi Jyotish.
* Menyimpan titik koordinat *ephemeris* ke Firestore sebagai *cache* untuk efisiensi komputasi *serverless*.