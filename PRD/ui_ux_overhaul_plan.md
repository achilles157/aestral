# PRD: Rencana Perombakan Total UI/UX Aestral (Nebula Glassmorphism)

Dokumen ini mendokumentasikan spesifikasi kebutuhan desain dan rencana implementasi teknis untuk merombak total visual dan pengalaman pengguna (UI/UX) pada frontend Flutter aplikasi Aestral.

---

## 🌌 1. Visi Desain: Nebula Glassmorphism & Sacred Geometry
Tujuan utama dari perombakan ini adalah mengganti antarmuka Material standar yang kaku menjadi pengalaman kosmis yang premium, misterius, dan imersif. 

### Elemen Visual Utama:
*   **Frosted Glass (Glassmorphism):** Menggunakan efek kaca buram semi-transparan dengan ketebalan border tipis berpendar (*neon outer glow*) untuk semua kartu, ubin kalender, dan bottom sheet.
*   **Sacred Geometry:** Ornamen geometris bernuansa emas (mandala, rasi bintang, arah mata angin Jawa Asapon) yang berputar halus sebagai elemen latar belakang dan transisi.
*   **Radial Glowing Backgrounds:** Pendaran cahaya dinamis yang memancar di belakang komponen untuk menunjukkan status energi, bukan sekadar indikator titik warna standar.

---

## 🛠️ 2. Detail Redesign Komponen & Layar

### A. Dashboard Utama (`dashboard_screen.dart`)
*   **Tampilan Lama:** Daftar kartu vertikal sederhana dengan ikon dan chevron standar.
*   **Tampilan Baru:**
    *   **Celestial Carousel Deck:** Fitur navigasi utama dikemas menjadi *carousel* kartu tarot melayang yang interaktif. Pengguna dapat menggeser (*swipe*) kartu-kartu kosmis (Weton, Tarot, Astrological Planner).
    *   **Rotating Mandala Background:** Menambahkan roda mandala emas di latar belakang logo Aestral yang berputar sangat lambat (dekoratif).
    *   **Pulsing Glows:** Setiap kartu memiliki efek glow berpendar halus sesuai dengan warna tema fitur tersebut (Pink untuk Tarot, Ungu untuk Weton, Emas untuk Planner).

### B. Astrological Planner (`astrological_planner_screen.dart`)
*   **Tampilan Lama:** Ubin kalender standard dengan garis kisi kaku dan indikator bulatan kecil Pancasuda.
*   **Tampilan Baru:**
    *   **Frosted Glass Grid:** Sel kalender berupa ubin kaca frosted semi-transparan melengkung (`BorderRadius.circular(12)`).
    *   **Pancasuda Radial Glow:** Mengganti bulatan kecil Pancasuda dengan radial gradient halus di latar belakang ubin tanggal yang aktif memancar sesuai getaran energi hari itu (Emas = *Gedhong*, Hijau = *Sandang*, Merah Lembut = *Pati*).
    *   **Unified Timeline Sheet (BottomSheet):**
        *   Menghilangkan TabBar Material default.
        *   Insight harian dan Jadwal Saat Pitu digabung menjadi satu halaman *scrollable timeline* vertikal yang terpadu.
        *   Tiap kartu jam Saat Pitu dilengkapi dengan tombol interaktif **"Tanya AI Astrolog" (Consult AI)** yang memanfaatkan field `ai_hook` dari dataset.

### C. Weton Calculator (`weton_calculator_screen.dart`)
*   **Tampilan Lama:** Pengisian input form manual (koordinat, dropdown) yang memusingkan, serta teks hasil analisis yang sangat panjang.
*   **Tampilan Baru:**
    *   **Onboarding Wizard (Ritual Angka):** Input tanggal dan jam lahir dibuat dengan roda pemutar astrologi bundar (*dial timepiece*) yang interaktif.
    *   **Mandala Reveal:** Hasil analisis weton dibuka dengan animasi memudar melingkar (*fade-in circular*).
    *   **Technical Detail Collapse:** Sesuai aturan arsitektur, parameter teknis (Neptu, Wuku, Pancasuda) disembunyikan di dalam *collapsible tile* berlabel **"Lihat Detail Perhitungan Teknis"**.
    *   **Premium Call to Action (CTA):** Tombol tanya AI yang mencolok bertuliskan *"💬 Diskusikan Sisi Gelap Weton Anda dengan AI"* menggunakan field `ai_hook` dari database.

---

## 🛠️ 3. Panduan Implementasi Flutter (Type-Safe & Layout-Safe)

1.  **Bottom Overflow Prevention:**
    Setiap layar input/output yang berpotensi memiliki tinggi dinamis wajib dibungkus menggunakan arsitektur berikut untuk mencegah bug overflow pixel merah:
    ```dart
    LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(...),
            ),
          ),
        );
      }
    )
    ```
2.  **BackdropFilter Utility:**
    Gunakan komponen kustom untuk mempermudah implementasi glassmorphism di seluruh layar:
    ```dart
    ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white10),
          ),
          child: child,
        ),
      ),
    )
    ```

---

## 📐 4. Rencana Verifikasi Visual
*   **Static Audit:** Memastikan semua warna mematuhi token kontras tinggi di `AppTheme` dan tidak merusak keterbacaan teks utama.
*   **Animation Smoothness:** Pengujian transisi halaman dan gesture geser carousel pada simulator minimal 60fps.
