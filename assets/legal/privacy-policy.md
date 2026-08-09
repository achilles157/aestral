# Kebijakan Privasi Aestral

**Efektif sejak:** 7 Agustus 2026
**Versi:** 1.0

---

## 1. Pengantar

Selamat datang di **Aestral** ("kami", "aplikasi"). Aestral adalah platform astrologi budaya yang menyajikan interpretasi Weton Jawa, Ba Zi Tionghoa, Tarot, dan ramalan kosmis lainnya sebagai sarana **hiburan, refleksi diri, dan pelestarian warisan budaya**.

Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, melindungi, dan menghapus data pribadi Anda saat menggunakan aplikasi Aestral, sesuai dengan **Undang-Undang Nomor 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP)** dan praktik perlindungan data yang berlaku di Indonesia.

Dengan menggunakan Aestral, Anda menyatakan telah membaca, memahami, dan menyetujui kebijakan ini.

---

## 2. Data yang Kami Kumpulkan

### 2.1 Data yang Anda berikan secara langsung

| Jenis Data | Contoh | Tujuan |
|---|---|---|
| Data akun | Nama, alamat email (melalui login Google) | Membuat & mengelola akun, menyinkronkan data antar perangkat |
| Data kelahiran | Tanggal lahir, dan bila Anda isi: jam lahir, tempat lahir | Menghitung Weton, Ba Zi, dan ramalan yang dipersonalisasi |
| Data preferensi & jawaban | Pilihan topik (karir, asmara, keuangan, dll.), hasil tarik kartu | Menghasilkan bacaan yang relevan |
| Riwayat bacaan | Hasil tarikan kartu tarot, perhitungan weton, bagan Ba Zi | Menyimpan riwayat agar Anda dapat melihat kembali bacaan sebelumnya |
| Jurnal kosmis | Catatan pribadi yang Anda tulis di fitur jurnal | Menyimpan refleksi pribadi Anda |

### 2.2 Data yang dikumpulkan otomatis

| Jenis Data | Tujuan |
|---|---|
| Data penggunaan & analitik (Firebase Analytics) | Memahami fitur apa yang paling digunakan, memperbaiki pengalaman aplikasi |
| Data perangkat & teknis (jenis perangkat, versi OS, versi aplikasi) | Kompatibilitas dan pemecahan masalah |
| Alamat IP (diproses oleh Cloudflare Workers) | Pembatasan laju (rate limiting) untuk mencegah penyalahgunaan |

### 2.3 Data yang TIDAK kami kumpulkan

- Kami **tidak** mengumpulkan data kesehatan, data biometrik, atau data keuangan Anda.
- Kami **tidak menjual** data pribadi Anda kepada pihak mana pun.
- Kami **tidak menggunakan** data Anda untuk iklan bertarget lintas-situs.

---

## 3. Dasar Hukum Pemrosesan (UU PDP)

Kami memproses data pribadi Anda berdasarkan:

1. **Persetujuan (consent)** — Anda memberikan persetujuan saat mendaftar dan saat mengisi data kelahiran;
2. **Pelaksanaan perjanjian** — data diproses untuk menjalankan layanan yang Anda minta;
3. **Kepentingan sah** — misalnya analitik penggunaan untuk perbaikan layanan, dengan dampak minimal pada Anda.

---

## 4. Bagaimana Kami Menggunakan Data Anda

Data Anda digunakan untuk:

- Menghitung dan menampilkan Weton, Ba Zi, Tarot, dan bacaan kosmis;
- Membuat konten AI (sintesis bacaan) yang dipersonalisasi;
- Menyimpan riwayat bacaan dan profil kelahiran Anda;
- Mengirimkan notifikasi yang Anda pilih (jika ada);
- Meningkatkan kualitas dan keamanan aplikasi;
- Memenuhi kewajiban hukum.

Kami **tidak** menggunakan data kelahiran Anda untuk tujuan lain di luar layanan Aestral tanpa persetujuan terpisah.

---

## 5. Pihak Ketiga & Pemroses Data

Aestral menggunakan layanan pihak ketiga yang tepercaya:

| Layanan | Peran | Data yang Diproses |
|---|---|---|
| **Google Firebase** (Authentication, Firestore, Analytics, Hosting) | Autentikasi, penyimpanan data, analitik, hosting aplikasi | Akun, profil, riwayat, data analitik |
| **Google Gemini API** (melalui Cloudflare Workers) | Menghasilkan narasi sintesis bacaan AI | Data kelahiran & konteks kartu yang dikirim untuk bacaan (tidak disimpan sebagai riwayat percakapan) |
| **Cloudflare Workers** | Backend API, cache, rate limiting | Alamat IP, key cache internal |

Masing-masing pihak ketiga memiliki kebijakan privasinya sendiri:
- Kebijakan Privasi Google: <https://policies.google.com/privacy>
- Kebijakan Privasi Cloudflare: <https://www.cloudflare.com/privacypolicy/>

Konten yang Anda kirim ke Gemini API untuk menghasilkan bacaan AI diproses sesuai kebijakan Google dan **tidak digunakan untuk melatih model** sesuai pengaturan default Google AI API untuk data pengguna.

---

## 6. Penyimpanan & Keamanan Data

- Data Anda disimpan di infrastruktur **Google Cloud / Firebase** dengan enkripsi saat transit (TLS) dan saat istirahat (at-rest).
- Akses ke data Anda dibatasi oleh **aturan keamanan Firestore** yang hanya mengizinkan pemilik akun (dan layanan backend yang sah) membaca/menulis datanya sendiri.
- **Mode tamu (guest):** jika Anda menggunakan aplikasi tanpa login, data tersimpan lokal di perangkat dan **tidak** disinkronkan ke server. Data tamu akan hilang jika aplikasi dihapus atau cache dibersihkan.
- Kami menerapkan praktik keamanan yang wajar, namun **tidak ada sistem yang 100% aman**. Kami tidak dapat menjamin keamanan mutlak data Anda.

---

## 7. Retensi & Penghapusan Data

- Data akun Anda disimpan selama akun aktif.
- Anda dapat menghapus data kapan saja:
  - **Hapus data dalam aplikasi:** melalui menu pengaturan akun (jika tersedia);
  - **Hapus akun:** kirim permintaan ke alamat kontak di bawah, atau gunakan fitur hapus akun bila tersedia.
- Permintaan penghapusan akan diproses paling lambat **14 hari kerja** sesuai UU PDP.
- Cache teknis di Cloudflare KV memiliki masa berlaku otomatis (TTL) dan terhapus dengan sendirinya.

---

## 8. Hak Anda (UU PDP)

Sesuai UU PDP, Anda berhak untuk:

1. **Mengakses** — meminta salinan data pribadi Anda;
2. **Memperbaiki** — meminta koreksi data yang tidak akurat;
3. **Menghapus** — meminta penghapusan data Anda;
4. **Menarik persetujuan** — menarik persetujuan pemrosesan kapan saja;
5. **Membatasi/keberatan** — meminta pembatasan atau keberatan atas pemrosesan tertentu;
6. **Portabilitas** — meminta data dalam format yang dapat dibaca;
7. **Mengajukan keluhan** — kepada kami dan/atau otoritas pengawas (sesuai ketentuan UU PDP).

Untuk menggunakan hak-hak tersebut, hubungi kami melalui kontak di Bagian 12.

---

## 9. Privasi Anak

Aestral ditujukan untuk pengguna **berusia 17 tahun ke atas**. Sesuai UU PDP, anak di bawah usia 18 tahun memerlukan persetujuan orang tua/wali yang sah untuk pemrosesan data pribadi. Jika kami mengetahui data anak di bawah umur dikumpulkan tanpa persetujuan orang tua, kami akan menghapusnya sesegera mungkin.

---

## 10. Mode Tamu & Data Lokal

Jika Anda menggunakan Aestral **tanpa masuk akun (mode tamu)**:

- Data profil kelahiran dan riwayat disimpan **lokal di perangkat Anda**;
- Beberapa fitur (misalnya sinkronisasi lintas perangkat) mungkin tidak tersedia;
- Kami tetap memproses data yang diperlukan untuk menghasilkan bacaan (misalnya tanggal lahir yang Anda masukkan) secara sementara, dan data tersebut tidak ditautkan ke identitas Anda.

---

## 11. Perubahan Kebijakan

Kami dapat memperbarui Kebijakan Privasi ini sewaktu-waktu. Perubahan signifikan akan kami beri tahu melalui aplikasi (notifikasi/banner) atau email. Tanggal "Efektif sejak" di bagian atas menunjukkan versi terbaru. Penggunaan aplikasi setelah perubahan berlaku berarti Anda menyetujui kebijakan yang diperbarui.

---

## 12. Hubungi Kami

Untuk pertanyaan, permintaan data, atau keluhan privasi:

- **Email:** privasi@aestral.app
- **Subjek email:** "Permintaan Data Pribadi" / "Keluhan Privasi" / "Hapus Akun"

Kami akan merespons dalam **14 hari kerja**.

---

## 13. Pernyataan Penting

Aestral adalah platform **hiburan dan refleksi budaya**. Seluruh bacaan, ramalan, dan interpretasi — termasuk Weton, Ba Zi, Tarot, dan konten AI — bersifat **indikatif, simbolis, dan tidak ilmiah**. Informasi ini **bukan** pengganti nasihat profesional di bidang medis, psikologis, hukum, keuangan, atau keputusan hidup penting lainnya. Keputusan apa pun yang Anda ambil berdasarkan konten Aestral sepenuhnya merupakan tanggung jawab Anda. Lihat **Perjanjian Pengguna** untuk ketentuan lengkap.
