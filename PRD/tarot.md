# Product Requirement Document (PRD) - Daily & Weekly Tarot Draw

## 1. Pendahuluan & Objective
* **Objective:** Menyediakan refleksi Tarot yang dinamis, mendalam, dan terpersonalisasi untuk meningkatkan keterikatan harian (*Daily Active Users*) menggunakan komputasi backend di edge.
* **Target Audience:** Pengguna gratis (akses mingguan terkalibrasi Wuku) dan pengguna berbayar/premium (akses harian terkalibrasi energi harian).
* **Arsitektur Constraints:** *Zero-Budget*. Penarikan kartu Tarot dilakukan di Cloudflare Workers (Free Tier) menggunakan pembobotan probabilitas (*Weighted RNG*) berbasis elemen astrologi pengguna, bukan RNG lokal murni.

---

## 2. Fitur & Spesifikasi Fungsional (User Stories)

### 2.1. Penarikan Tarot Mingguan (Gratis - Hook Tier)
* **User Story:** "Sebagai pengguna gratis, saya ingin melakukan penarikan kartu Tarot mingguan yang dipengaruhi oleh energi Wuku saat ini agar saya mendapatkan panduan mingguan yang relevan."
* **Alur Backend (Cloudflare Workers):**
  1. Aplikasi mengirim request draw ke Cloudflare Workers dengan JWT token Firebase Auth.
  2. Worker mendeteksi siklus **Wuku** saat ini (berubah setiap 7 hari).
  3. Worker mencocokkan elemen Wuku saat ini dengan elemen Weton lahir pengguna, lalu menerapkan pembobotan probabilitas (*Weighted RNG*) pada Suit kartu Tarot.
  4. Worker mengembalikan ID kartu yang terpilih beserta penjelasannya ke aplikasi.

### 2.2. Penarikan Tarot Harian & Sintesis AI (Premium Tier)
* **User Story:** "Sebagai pengguna premium, saya ingin menarik kartu Tarot harian dan mendapatkan narasi penjelasan AI yang disintesis dari weton saya dan kartu tarot tersebut."
* **Alur Backend (Cloudflare Workers & Gemini):**
  1. Request harian dikirim oleh pengguna premium ke Cloudflare.
  2. Worker menghitung bobot kartu berdasarkan siklus energi harian (Petungan Hari).
  3. Worker melakukan draw kartu tertimbang.
  4. Worker merakit prompt: *Profil Kelahiran (Weton)* + *Kartu Tarot Terpilih* + *Logika Elemen*.
  5. Worker mengirim request ke Gemini API (Google AI Studio - Free Tier) untuk menyintesis narasi pembacaan yang personal, empatik, dan mudah dipahami.
  6. Worker mengembalikan narasi AI ke aplikasi Flutter.

---

## 3. Penyelarasan Elemen (Astrological Suit Mappings)

Pembobotan probabilitas Tarot memanfaatkan sinkretisme elemen astrolgi berikut:
- **Cups** $\rightarrow$ Elemen Air (Water)
- **Wands** $\rightarrow$ Elemen Api (Fire)
- **Pentacles** $\rightarrow$ Elemen Tanah (Earth)
- **Swords** $\rightarrow$ Elemen Logam (Metal)
- **Major Arcana** $\rightarrow$ Netral / Kayu / Spirit

*Contoh logika:* Jika siklus Wuku atau Petungan Hari beresonansi positif dengan elemen Air pengguna, probabilitas menarik kartu dari Suit **Cups** akan ditingkatkan secara proporsional.

---

## 4. Kebutuhan UI/UX (Flutter Client-Side)
* **Animasi Flip 3D:** Kartu tarot ditampilkan dalam bentuk tertutup (face-down), dan berputar secara interaktif (3D flip animation) saat diketuk pengguna untuk menampilkan gambar kartu.
* **Social Share:** Menyediakan tombol screenshot instan untuk membagikan kartu hasil pembacaan ke media sosial (Instagram Story/WhatsApp).