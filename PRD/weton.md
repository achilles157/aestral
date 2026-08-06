# Product Requirement Document (PRD) - Weton Profiling & Daily Insight (MVP)

## 1. Pendahuluan & Objective
* **Objective:** Menyediakan analisis kepribadian Javanese Astrology instan secara *offline-first* dan panduan aktivitas harian dinamis (Petungan Hari) untuk meningkatkan retensi harian pengguna (*Daily Retention*).
* **Target Audience:** Gen-Z dan Milenial yang tertarik pada astrologi modern, kesehatan batin (*mindfulness*), dan personalisasi kepribadian yang trendi.
* **Arsitektur Constraints:** *Zero-Budget*. Pemrosesan konversi kalender dan pencarian deskripsi weton wajib dilakukan murni di sisi klien (*client-side*/lokal) untuk menghemat biaya server dan mengurangi latensi pembacaan database.

---

## 2. Fitur & Alur Kerja Pengguna (User Stories)

### 2.1. Profiling Weton Kelahiran (Offline-First)
* **User Story:** "Sebagai pengguna baru, saya ingin memasukkan tanggal lahir saya dan melihat weton kelahiran beserta analisis kepribadian saya secara instan."
* **Alur Teknis:**
  1. Pengguna memilih tanggal lahir (Masehi) melalui Date Picker UI.
  2. Aplikasi Flutter menjalankan algoritma konversi berbasis *Julian Day Number* (JDN) untuk menghitung:
     - **Saptawara** (Minggu, Senin, Selasa, Rabu, Kamis, Jumat, Sabtu)
     - **Pancawara** (Legi, Pahing, Pon, Wage, Kliwon)
  3. Aplikasi mencocokkan hasil weton ke file [kamus-weton.json](file:///c:/Users/Falah/Documents/aestral/assets/weton/kamus-weton.json) di local assets.
  4. UI merender data profil: `headline`, `karir_rezeki`, `asmara_hubungan`, `sisi_gelap_peringatan`, `career_tendency` (sebagai Chips visual), dan `tags` (sebagai Chips visual).

### 2.2. Petungan Harian / Daily Insight (Tier Premium - Berlangganan)
* **User Story:** "Sebagai pengguna premium, saya ingin mengetahui benturan energi kelahiran saya dengan energi hari ini agar saya bisa merencanakan prioritas harian saya."
* **Alur Teknis:**
  1. Aplikasi mendapatkan total neptu kelahiran pengguna dari profil lokal (contoh: Minggu Legi = 10).
  2. Aplikasi menghitung neptu hari ini (contoh: Rabu Kliwon = 7 + 8 = 15).
  3. Menghitung modulo Petungan Hari menggunakan rumus:
     $$\text{Sisa Bagi} = (\text{Total Neptu Kelahiran} + \text{Total Neptu Hari Ini}) \pmod 5$$
  4. Aplikasi mencocokkan sisa bagi ($0, 1, 2, 3, 4$) ke file [sisabagi.json](file:///c:/Users/Falah/Documents/aestral/assets/weton/sisabagi.json).
  5. UI menampilkan `nama_fase` (Sandang, Pangan, Gedhong, Loro, Pati), `tingkat_energi`, `interpretasi_harian` bernuansa kesehatan mental modern, dan 3 `saran_aktivitas` yang praktis.

---

## 3. Spesifikasi UI/UX & Layout Safety

Untuk mencegah kegagalan visual di berbagai resolusi layar perangkat seluler, tata letak UI wajib mematuhi aturan berikut:
1. **No Rigid Spacers:** Dilarang menggunakan widget `Spacer` secara kaku di dalam `Column` tanpa pembungkus yang scroll-safe.
2. **Scroll Overflow Safety:** Halaman profil weton dinamis wajib dibungkus dengan kombinasi layout Flutter berikut:
   ```dart
   LayoutBuilder(
     builder: (context, constraints) {
       return SingleChildScrollView(
         child: ConstrainedBox(
           constraints: BoxConstraints(
             minHeight: constraints.maxHeight,
           ),
           child: IntrinsicHeight(
             child: Column(
               children: [
                 // Konten Profil Weton...
               ],
             ),
           ),
         ),
       );
     }
   )
   ```
3. **Estetika Data Astrologi:** Menyembunyikan parameter neptu teknis (seperti nilai angka neptu 10, 12, dll.) di dalam panel accordion/dropdown opsional untuk menjaga antarmuka tetap bersih, minimalis, dan terfokus pada konten narasi.

---

## 4. Metrik Keberhasilan
* **Aktivasi Profil:** >90% pengguna melengkapi input tanggal lahir dalam 3 hari pertama instalasi.
* **Engagement Insight Harian:** Rata-rata pengguna premium membuka halaman Insight Harian minimal 4 kali dalam seminggu.
