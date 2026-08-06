# PRD & Arsitektur: Best Practice Integrasi Pra-Barnum & AI Astrologer

Dokumen ini merancang arsitektur terbaik (*best practice*) untuk mengintegrasikan dataset Primbon statis (**Pra-Barnum**) dengan sistem konsultasi interaktif menggunakan **Google Gemini API** (AI Astrologer) berbasis **Zero-Budget & High-Performance**.

---

## 🧭 1. Pilihan Model AI Terbaik
Untuk kebutuhan chatbot astrologi interaktif, model yang paling cocok adalah **Gemini 3.1 Flash Lite**.

### Mengapa Gemini 3.1 Flash Lite?
1.  **Latency Sangat Rendah (Near Zero-Latency):** Model Flash Lite dioptimalkan secara ekstrem untuk kecepatan respons chat real-time.
2.  **Context Window Raksasa & Fleksibilitas:** Mampu menampung seluruh riwayat obrolan pengguna dan instruksi sistem tebal dengan andal.
3.  **Kuota Free Tier Lebih Aman:**
    *   **15 RPM** (Requests Per Minute)
    *   **250K TPM** (Tokens Per Minute)
    *   **500 RPD** (Requests Per Day)
    Ini adalah batas kuota gratis yang sangat aman untuk menangani lonjakan sesi percakapan pengguna Aestral tanpa risiko kegagalan 429 (Too Many Requests).

---

## 🧠 2. Strategi Data: RAG vs Context Injection (Direct Context)
Untuk aplikasi Aestral, arsitektur terbaik adalah **Context Injection (Direct Context)**, **bukan RAG (Vector Database)**.

### Mengapa RAG Kurang Cocok di Sini?
*   **Overengineering:** RAG membutuhkan Vector Database (seperti Pinecone, Qdrant) untuk mencari dokumen. Ini melanggar batasan arsitektur *Zero-Budget* (menambah biaya infrastruktur).
*   **Ukuran Data yang Kecil:** Seluruh data astrologi satu pengguna (Weton lahir, Wuku berjalan, Pranata Mangsa, dan 3 kartu tarot yang ditarik) berukuran sangat kecil (kurang dari **4 KB**). 
*   **Risiko Halusinasi:** Jika menggunakan RAG, ada risiko AI "salah ambil" dokumen profil Weton orang lain.

### Solusi Terbaik: In-Context Astrological Modeling
Setiap kali pengguna memulai sesi obrolan dengan AI, aplikasi akan mengirimkan **identitas kosmis lengkap beserta teks deskripsi statis dari JSON** langsung ke dalam instruksi sistem (*System Instruction*) API Gemini. 

---

## 🛠️ 3. Alur Kerja Integrasi (Sistem ke AI)

```
[Flutter Client] 
   │ (Menghitung Weton/Tarot secara offline-first)
   ▼
[JSON Lokal] ──► Ambil Deskripsi Pra-Barnum (Statis)
   │
   ▼ (Kirim payload Weton + Deskripsi Statis + Prompt User)
[Cloudflare Worker]
   │
   ├─► 1. Ambil API Key dari Environment (.env)
   ├─► 2. Susun Master System Instruction (Memasukkan Riset & Aturan Barnum)
   │
   ▼ (Kirim Request POST)
[Gemini API] ──► Menghasilkan respon chat yang sangat personal & empatik
```

---

## 📝 4. Implementasi Master Prompt (System Instruction)
Berikut adalah draf *System Instruction* terbaik untuk disuntikkan ke Gemini API:

```markdown
# SYSTEM INSTRUCTION: AESTRAL COSMIC ASTROLOGER

Anda adalah seorang Senior Javanese Spiritual Astrologer (Ahli Primbon Jawa) sekaligus Psikolog Analitis Carl Jung. Tugas Anda adalah memberikan konsultasi astrologi yang empatik, mendalam, dan modern kepada pengguna berdasarkan identitas kosmis mereka.

## 👥 IDENTITAS KOSMIS PENGGUNA (DATA WAJIB DIACU)
Gunakan data statis berikut sebagai kebenaran mutlak profil pengguna:
- **Weton Kelahiran:** {{weton_name}} (headline: "{{weton_headline}}")
- **Wuku Berjalan:** {{wuku_name}} (dewa: {{wuku_dewa}})
- **Musim Berjalan (Pranata Mangsa):** {{mangsa_name}} (arketipe: {{mangsa_arketipe}})
- **Tebaran 3 Kartu Tarot:**
  - Masa Lalu: {{tarot_past_name}} (posisi: {{tarot_past_position}})
  - Masa Kini: {{tarot_present_name}} (posisi: {{tarot_present_position}})
  - Masa Depan: {{tarot_future_name}} (posisi: {{tarot_future_position}})

## 📜 ATURAN SALINAN & NADA BAHASA (BARNUM EFFECT)
1. Terapkan Dual-Trait Paradox: Selalu benturkan topeng luar pengguna (yang terlihat kuat/ambisius) dengan kerentanan batin mereka (takut gagal, lelah batin, rasa kesepian).
2. Esoteric Anchoring: Hubungkan istilah primbon (Pancasuda, Weton, Neptu) dengan konsep kesehatan mental modern (burnout, imposter syndrome, boundaries, people-pleaser).
3. Gaya Bahasa: Hangat, misterius, mendukung, menggunakan panggilan "Anda" atau "Kamu" secara kasual layaknya teman diskusi batin yang bijak.
4. DILARANG KERAS menggunakan ramalan nasib buruk mutlak (kematian, kecelakaan, kebangkrutan). Ubah peringatan bahaya menjadi saran preventif dan mitigasi energi (misal: "Hari ini energi vital Anda melemah, hindari keputusan impulsif").
```

---

## 💰 5. Trik Monetisasi & Pembatasan Kuota (Rate Limiting)
Karena kita menggunakan Free Tier API, lindungi endpoint Worker Anda dengan aturan ini:
1.  **Client-Side Caching:** Obrolan chat disimpan di database lokal (SQLite/Isar/Hive di Flutter) agar pengguna tidak melakukan hit API berulang kali untuk membaca riwayat chat yang sama.
2.  **IP Rate Limiting:** Cloudflare Workers dapat membatasi hit ke endpoint `/api/chat` maksimal 5 kali per menit per alamat IP pengguna untuk mencegah eksploitasi kuota API Key gratisan Anda.
