# Implementation Plan - Integrasi Pranata Mangsa (Seasonal Cycle)

Rencana ini merinci langkah-langkah teknis untuk mengintegrasikan siklus musiman **Pranata Mangsa** ke dalam sistem Cloudflare Workers (Backend) dan aplikasi Flutter (Frontend), lengkap dengan pengujian.

---

## Proposed Changes

### 1. Data Assets & Config (Client-Side)

#### [NEW] [pranata_mangsa.json](file:///c:/Users/Falah/Documents/aestral/assets/weton/pranata_mangsa.json)
*   Membuat file database statis JSON yang bersumber dari hasil merge riset master. File ini akan di-bundle di folder `assets/weton/` untuk pembacaan offline-first.

#### [MODIFY] [pubspec.yaml](file:///c:/Users/Falah/Documents/aestral/pubspec.yaml)
*   Memasukkan `assets/weton/pranata_mangsa.json` ke dalam konfigurasi aset agar bisa dimuat oleh `rootBundle` saat startup aplikasi.

---

### 2. Backend Cloudflare Workers (TypeScript)

#### [MODIFY] [weton.ts](file:///c:/Users/Falah/Documents/aestral/aestral-backend/src/weton.ts)
*   Menambahkan fungsi helper `getPranataMangsaId(date: Date): number` untuk menghitung ID Mangsa (1 s.d. 12) berdasarkan input tanggal, lengkap dengan penanganan tahun kabisat (*wastu*) untuk bulan Februari (Mangsa Kawolu).
*   Menambahkan interface `PranataMangsaInsight` pada respons data weton.
*   Mengintegrasikan data ID Mangsa ke dalam fungsi utama `getWetonInsight`.

#### [MODIFY] [router.ts](file:///c:/Users/Falah/Documents/aestral/aestral-backend/src/router.ts)
*   Memperbarui payload response pada endpoint `POST /api/weton/daily` agar menyertakan ID Pranata Mangsa yang aktif untuk hari target tersebut.

---

### 3. Frontend Flutter Integration (Dart)

#### [NEW] `lib/features/weton/domain/pranata_mangsa.dart`
*   Membuat model data Dart `PranataMangsaModel` dengan fungsi serialisasi `fromJson` untuk memetakan isi `pranata_mangsa.json`.

#### [NEW] `lib/features/weton/data/pranata_mangsa_repository.dart`
*   Membuat repositori lokal menggunakan Riverpod untuk memuat berkas JSON statis saat startup aplikasi dan menyediakan fungsi pencarian Mangsa berdasarkan tanggal.

#### [NEW] `lib/features/weton/presentation/widgets/seasonal_banner.dart`
*   Membuat komponen UI widget `SeasonalBanner` yang menampilkan visual dan narasi Pranata Mangsa berjalan secara dinamis (warna latar belakang menyesuaikan dengan arketipe mangsa berjalan).

---

## Verification Plan

### Automated Tests
1.  **Backend Unit Tests:**
    *   Membuat berkas `aestral-backend/test/pranata.test.ts` untuk menguji keakuratan penentuan Mangsa dari berbagai tanggal uji coba (termasuk tanggal kabisat 29 Februari dan solstis 22 Juni).
    *   Menjalankan pengujian backend menggunakan:
        ```bash
        cd aestral-backend
        npx vitest run test/pranata.test.ts
        ```
2.  **Frontend Widget Tests:**
    *   Menguji komponen `SeasonalBanner` dengan menyimulasikan tanggal yang berbeda untuk memastikan skema warna latar belakang dan teks berubah secara dinamis.
    *   Menjalankan:
        ```bash
        flutter test test/features/weton/presentation/seasonal_banner_test.dart
        ```

### Manual Verification
*   Menjalankan aplikasi lokal Flutter, membuka halaman Planner/Insight harian, dan memastikan info mangsa bulanan terkesan menyatu dengan grid kalender.
