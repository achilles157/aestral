# Aestral — Development Roadmap
**Dibuat:** 2026-07-27  
**Tujuan:** Rencana implementasi spesifik hasil diskusi sesi panjang. Baca dokumen ini di awal session implementasi sebagai konteks penuh.

---

## Konteks: Apa yang Sudah Ada

### Fitur yang sudah berjalan
- Weton Calculator + Astrological Planner
- Ba Zi Calculator (4 pilar, Ten Gods, Luck Pillars dengan AI synthesis, dll)
- Tarot Reading + AI Oracle panel
- Weton Compatibility
- AI Oracle: 4 persona (Ki Sabdo, Suhu Wang, Madame Sophia, Sesepuh Kosmis)
- Ba Zi chart caching via `BaziCacheService` (SharedPreferences)

### Stack teknis
- Flutter + Riverpod + Firebase Auth
- Cloudflare Workers (TypeScript) sebagai backend
- Gemini 3.1 Flash Lite — **free tier: 15 RPM, 500 RPD** (constraint utama)
- SharedPreferences untuk local cache
- Firestore subcollections: `tarot_history`, `weton_history`, `bazi_history`

### File referensi penting
```
lib/features/bazi/presentation/bazi_calculator_screen.dart   — pola _calculate() + AI call
lib/features/bazi/presentation/widgets/bazi_luck_pillars_widget.dart  — pola AI synthesis on-demand
lib/features/bazi/services/bazi_cache_service.dart           — pola SharedPreferences caching
lib/features/home/presentation/dashboard_screen.dart         — dashboard utama
lib/features/ai/presentation/oracle_chat_screen.dart         — pola oracle chat
lib/features/ai/providers/oracle_chat_provider.dart          — pola Riverpod + local storage
lib/core/services/api_service.dart                           — pola API call + error handling
aestral-backend/src/router.ts                                — semua endpoint backend
aestral-backend/src/oracle_prompts.ts                        — system instructions oracle
aestral-backend/src/gemini.ts                                — callGemini + callGeminiStructured
```

---

## Arsitektur AI — Tiga Layer

```
Layer 1: Static Synthesis (on-demand, per section)
  └── Ba Zi Annual Pillar, Branch Relations, Wu Xing — muncul saat user tap tombol

Layer 2: Conversational Oracle (multi-turn dialog)
  └── Ki Sabdo, Suhu Wang, Madame Sophia, Sesepuh Kosmis — sudah ada

Layer 3: Cross-tradition Synthesis
  ├── Daily Synthesis Card (pasif, auto, dashboard) — BELUM ADA
  └── Sesepuh Kosmis (aktif, on-demand) — sudah ada
```

---

## Prioritas Implementasi

```
P1 — Daily Synthesis Card (dashboard)     ← USP terdistinktif
P2 — Ba Zi Annual Pillar AI synthesis     ← recurrence value, time-sensitive
P3 — History screen                        ← melengkapi conversion loop login
P4 — Ba Zi Branch Relations AI synthesis  ← data paling teknis, butuh narasi
P5 — Weton Compatibility synthesis card   ← nice-to-have
P6 — Gemini quota management              ← preventif, sebelum scaling
P7 — Wu Xing implication narrative        ← enhancement visual yang sudah ada
```

---

## P1 — Seasonal Synthesis Card (Dashboard)

> **[DIIMPLEMENTASIKAN — revisi dari spec awal]**  
> Granularitas diubah dari harian ke Pranata Mangsa (~30 hari) setelah diskusi arsitektur.  
> Commit: `606d600`, `e43f1ee`

### Tujuan
Card pasif di halaman dashboard yang auto-generate per Pranata Mangsa — menenun Ba Zi musim + Pranata Mangsa + Tarot Kosmis menjadi satu narasi 4-5 kalimat. **Fitur terdistinktif Aestral** — tidak dimiliki kompetitor.

### Arsitektur 3-Layer yang Diimplementasikan
```
Ba Zi 4 Musim      (~90 hari) → babak besar / gambaran makro
  └── Pranata Mangsa (~30 hari) → sub-chapter personal & relatable
       └── Tarot Kosmis          → focal point (hanya jika draw mangsa-mode)
```

**Contoh output (State B — dengan Tarot Kosmis):**
> *"Di Pranata Mangsa Kasa ini, elemen Logam mendominasi Ba Zi musim — selaras dengan Da Yun aktifmu yang meminta konsolidasi. The Tower hadir bukan sebagai kehancuran, tapi sebagai sinyal untuk melepas struktur lama yang tidak lagi relevan bagi Day Master Kayumu."*

### Implementasi Aktual

**Tidak ada backend endpoint baru** — menggunakan `/api/chat` existing dengan prompt yang dibangun client-side.

**State A (tanpa Tarot Kosmis):**  
Synthesis dari Ba Zi musim + Pranata Mangsa theme + Da Yun aktif + Annual Pillar.  
CTA: "✨ Draw Tarot Kosmis untuk sintesis yang lebih personal →"

**State B (dengan Tarot Kosmis):**  
Full synthesis, Tarot menjadi focal point narasi.  
Aktif setelah user draw di mangsa-mode (dideteksi via SharedPreferences `last_tarot_draw_type`).

### File yang Dibuat
- `lib/core/services/daily_synthesis_service.dart` — cache per Pranata Mangsa
  - Cache key: `seasonal_synthesis_pranata_<id>_<year>_<with/no_tarot>`
  - **12 API calls/tahun max** per user
- `lib/features/home/presentation/widgets/seasonal_synthesis_card.dart` — widget utama
- `lib/features/bazi/providers/bazi_chart_provider.dart` — global Ba Zi state provider

### Variabel yang ditenun ke narasi
| Variabel | Source | Update frequency |
|----------|--------|-----------------|
| Ba Zi musim (Kayu/Api/Logam/Air) | `BaziUtils` offline | ~90 hari |
| Status Yong/Ji musim | `baziChartProvider` | ~90 hari |
| Da Yun aktif | `BaziUtils.calculateLuckPillars()` | 10 tahun |
| Annual Pillar | `BaziUtils.getCurrentAnnualPillar()` | 1 tahun |
| Pranata Mangsa theme | `pranataMangsaListProvider` (local JSON) | ~30 hari |
| Tarot Kosmis | `drawnCardProvider` (mangsa-mode only) | Per sesi |

### Yang Belum dari Spec Awal
- [ ] Tap card → buka Sesepuh Kosmis dengan pre-filled context (hanya `setTab(0)` saat ini)

---

## P2 — Ba Zi Annual Pillar AI Synthesis

### Tujuan
Tombol "Analisis AI" di dalam `BaziAnnualPillarCard` yang menghasilkan narasi tentang apa yang dibawa pilar tahun berjalan untuk chart natal user.

### Pola referensi
Ikuti pola yang sama dengan Luck Pillars Ba Zi di `bazi_luck_pillars_widget.dart` — tombol on-demand, loading state, hasil muncul di bawah data.

### Backend
Bisa menggunakan endpoint `/api/bazi/insight` yang sudah ada, **atau** tambahkan endpoint spesifik:

```typescript
POST /api/bazi/annual-synthesis

// Request
{
  natalPillars: {
    year: string,   // "Geng Chen"
    month: string,
    day: string,
    hour?: string,
  },
  annualPillar: {
    stemNameId: string,
    branchZodiacId: string,
    element: string,
  },
  annualRelations: {
    clashes: Array<{ pillarA: string, pillarB: string }>,
    harmonies: Array<{ pillarA: string, pillarB: string, result: string }>,
  },
  dayMasterId: string,
  year: number,
}

// Response
{
  message: string,  // narasi 3-4 paragraf
  card?: OracleCard
}
```

**Prompt guidance:** AI harus menghasilkan dua bagian — (1) apa "cuaca kosmis" tahun ini bagi user secara umum, (2) jika ada clash, apa yang perlu diwaspadai; jika ada harmony, apa yang bisa dimanfaatkan. Gunakan Barnum: *"Bagi Day Master sepertimu..."*

### Flutter

**File modifikasi:** `lib/features/bazi/presentation/widgets/bazi_annual_pillar_card.dart`
- Tambahkan state: `String? _aiNarrative`, `bool _isLoadingAi`
- Tombol "✦ Analisis AI Tahun Ini" di bagian bawah card
- Hasil muncul sebagai expandable section di bawah tombol
- Cache key: `bazi_annual_{cacheKey}_{year}` (gunakan `BaziCacheService.cacheKey()` untuk base key)

---

## P3 — History Screen

### Tujuan
Layar yang menampilkan riwayat reading user dari Firestore. Melengkapi conversion loop login — user yang sudah register punya tempat melihat nilai dari akun mereka.

### Data Source
Firestore subcollections yang sudah ada:
- `users/{uid}/tarot_history/{id}` — tarot draws
- `users/{uid}/weton_history/{id}` — weton readings
- `users/{uid}/bazi_history/{id}` — ba zi charts

### Flutter

**File baru:** `lib/features/history/presentation/history_screen.dart`
- TabBar: Tarot | Weton | Ba Zi
- Per tab: ListView dengan card ringkas per entry
- Card menampilkan: tanggal, highlight utama (nama kartu / nama weton / day master)
- Tap → buka detail (bisa re-render hasil tanpa API call baru karena data tersimpan)

**File baru:** `lib/features/history/providers/history_provider.dart`
- `AsyncNotifierProvider` per tipe
- Pagination dengan `limit(20)` per query
- Hanya tersedia untuk authenticated user (bukan guest)

**Entry point di Dashboard:**
- Tambahkan tombol/icon riwayat di AppBar atau section tersendiri di dashboard
- Untuk guest: tombol visible tapi disabled dengan label "Login untuk simpan riwayat"

---

## P4 — Ba Zi Branch Relations Psychological Narrative

> **[DIIMPLEMENTASIKAN — revisi dari spec awal]**  
> Diimplementasikan sebagai deterministic pre-written maps (offline) alih-alih AI endpoint.  
> Commit: `5e3bda3`

### Tujuan
Mengubah daftar clash/harmony teknis menjadi narasi psikologis konkret per kombinasi pilar — mudah dimengerti tanpa jargon Ba Zi.

### Keputusan Arsitektur: Offline Maps vs AI Endpoint
**Spec awal:** AI endpoint baru + Gemini call  
**Implementasi aktual:** Const maps per kombinasi pilar (offline, zero API cost)

**Alasan:**
- Narasi per kombinasi pilar bersifat **deterministik** — "Clash Bulan vs Hari" selalu berarti ketegangan karier vs identitas, tidak peduli siapa usernya
- Pre-written maps jauh lebih cepat (zero latency), tidak memakan quota Gemini, dan 100% konsisten
- Barnum effect masih terjaga karena narasi ditulis dengan framing psikologis yang relatable

### Implementasi Aktual

**File:** `lib/features/bazi/presentation/widgets/bazi_relations_card.dart`

10 pasang clash narratives + 10 pasang harmony narratives sebagai `const Map<String, String>`:
- Key: `'indexA_indexB'` (smaller index first)
- Indeks: 0=Tahun, 1=Bulan, 2=Hari, 3=Jam, 4=流年

**Contoh:**
```dart
'1_2': 'Tuntutan karier & lingkungan (Pilar Bulan) berbenturan dengan '
       'identitas inti & hubungan intim (Pilar Hari). '
       'Ketegangan klasik antara peran profesional dan jati diri sejati.',
```

Narasi muncul di bawah setiap badge row — 11px, subtle, tidak overwhelming.

### Yang Tidak Diimplementasikan dari Spec
- Backend endpoint `POST /api/bazi/relations-synthesis` — tidak diperlukan
- Tombol on-demand — tidak diperlukan (narasi langsung inline)
- Cache — tidak diperlukan (offline computation)

---

## P5 — Weton Compatibility Synthesis Card

### Tujuan
Auto-generate narasi kohesif setelah kalkulasi kompatibilitas — bukan menggantikan section yang ada, tapi merajutnya menjadi satu "pembacaan pasangan".

### Flutter
**File modifikasi:** `lib/features/weton/presentation/weton_compatibility_screen.dart`

Setelah `_result` tersedia, tampilkan `CompatibilitySynthesisCard` di atas tombol "Tanya Orakel AI". Card ini auto-generate (bukan on-demand) dengan data kompatibilitas sebagai input.

**Backend:** Bisa menggunakan `/api/oracle/chat` dengan `oracleType: 'weton'` dan satu prompt yang sudah diformat, atau endpoint baru `/api/weton/compatibility-synthesis`.

**Input ke AI:**
```
namaFase, arketipeRelasi, neptu1, neptu2, sisaBagi,
dinamikaPsikologis, potensiGesekan, saranKomunikasi
```

**Cache key:** `weton_compat_{date1}_{date2}` — deterministik untuk pasangan yang sama.

---

## P6 — Gemini Quota Management

### Tujuan
Mencegah degradasi silent saat 500 RPD tercapai. User harus mendapat pesan yang manusiawi, bukan generic error.

### Backend — `aestral-backend/src/router.ts`

Tambahkan KV counter per hari:
```typescript
// Key: `gemini_daily_{YYYY-MM-DD}`
// Increment setiap Gemini call berhasil
// Jika count >= 480 (buffer 20): return 503 dengan pesan khusus
const dailyCount = await env.RATE_LIMIT_KV.get(`gemini_daily_${today}`);
if (parseInt(dailyCount ?? '0') >= 480) {
  return json({
    error: 'Oracle sedang beristirahat — kapasitas kosmis hari ini sudah penuh. Kembali besok.',
    retryAfterSeconds: secondsUntilMidnight(),
  }, 503);
}
```

### Flutter — `lib/core/services/api_service.dart`

Tambahkan handling untuk 503 dengan pesan yang on-brand:
```dart
if (response.statusCode == 503) {
  throw Exception('ORACLE_REST:${data['retryAfterSeconds']}');
}
```

Di setiap screen yang memanggil AI, handle `ORACLE_REST:` exception dengan SnackBar atau dialog yang sesuai tone mystical app.

---

## P7 — Wu Xing Implication Narrative

### Tujuan
Menambahkan satu section kecil di bawah radar chart yang menjelaskan implikasi praktis dari elemen dominan/defisien.

### Implementasi
**File modifikasi:** `lib/features/bazi/presentation/widgets/bazi_element_balance_card.dart`

Tidak butuh API call — ini bisa dikerjakan **dengan logic lokal + teks pre-written per kombinasi**:

```dart
// Deteksi elemen paling dominan dan paling defisien dari wuXingBalance
// Lookup ke Map<String, String> yang berisi narasi per kombinasi
// Tampilkan sebagai ExpansionTile "Apa Artinya Untukmu?"
```

Pre-written narratives per elemen defisien (5 kemungkinan × nuance = ~10 teks):
- Defisien Air → *"Kamu cenderung berjuang dengan fleksibilitas dan mengalir mengikuti perubahan..."*
- Defisien Api → *"Motivasi dan semangat bisa datang-pergi dalam gelombang yang tidak konsisten..."*
- dst.

**Tidak perlu Gemini call** — ini satu-satunya fitur di daftar yang bisa dikerjakan sepenuhnya offline.

---

## Catatan Teknis Lintas Fitur

### Pola caching yang konsisten
Semua AI synthesis features harus menggunakan pola yang sama:
1. Generate cache key dari input deterministik
2. Cek SharedPreferences sebelum API call
3. Simpan ke SharedPreferences setelah API sukses
4. Gagal simpan = non-fatal, tetap lanjut

Referensi: `lib/features/bazi/services/bazi_cache_service.dart`

### On-demand vs Auto-generate
| Fitur | Strategy | Alasan |
|:---|:---|:---|
| Daily Synthesis Card | Auto (cached) | UX — user tidak perlu action |
| Ba Zi Annual Pillar | On-demand | Hemat quota, user yang tertarik yang load |
| Ba Zi Branch Relations | On-demand | Hemat quota |
| Weton Compatibility | Auto (cached) | Deterministik per pasangan, aman |
| Wu Xing Narrative | Local logic | Tidak butuh Gemini sama sekali |

### Guest access
- Daily Synthesis Card: tampilkan preview dengan blur + CTA login
- History screen: tombol visible, disabled, label "Login untuk simpan riwayat"
- Ba Zi AI synthesis: tersedia (tidak di-gate, pakai guest rate limit yang sama)

---

## Checklist Implementasi

### P1 — Seasonal Synthesis Card ✅ SELESAI
- [x] Flutter: `daily_synthesis_service.dart` (Pranata-based cache)
- [x] Flutter: `seasonal_synthesis_card.dart` widget
- [x] Flutter: `bazi_chart_provider.dart` (global Ba Zi state)
- [x] Flutter: Integrasi di `dashboard_screen.dart`
- [x] Flutter: Tarot Kosmis detection via SharedPreferences
- [ ] Flutter: Tap card → buka Sesepuh Kosmis dengan pre-filled context

### P2 — Ba Zi Annual Pillar Synthesis ✅ SELESAI
- [x] Flutter: `_AnnualAiInsightSection` di `bazi_annual_pillar_card.dart`
- [x] Flutter: tombol tap-to-generate + loading state + hasil render
- [x] Flutter: caching via SharedPreferences (`annual_ai_insight_<year>_<dmId>`)

### P3 — History Screen ✅ SUDAH ADA
- [x] Flutter: `history_screen.dart` dengan TabBar
- [x] Flutter: Entry point di dashboard
- [x] Flutter: `reading_history_service.dart`

### P4 — Ba Zi Branch Relations ✅ SELESAI (revisi approach)
- [x] Flutter: pre-written psychological maps per pillar-pair (offline)
- [x] Flutter: narasi inline di `bazi_relations_card.dart`
- [x] Tidak perlu backend endpoint atau caching (deterministik offline)

### P5 — Weton Compatibility Synthesis ⏳ BELUM
- [ ] Flutter: auto-generate synthesis card setelah kalkulasi
- [ ] Flutter: caching per pasangan
- [ ] Backend: reuse `/api/chat` (tidak perlu endpoint baru)

### P6 — Gemini Quota Management ⏳ BELUM
- [ ] Backend: KV counter per hari di Cloudflare Workers
- [ ] Backend: 503 response dengan pesan on-brand
- [ ] Flutter: handling `ORACLE_REST:` di `api_service.dart`
- [ ] Flutter: UX pesan di semua AI screens

### P7 — Wu Xing Narrative ⏳ BELUM
- [ ] Flutter: pre-written narratives per elemen (Map, offline)
- [ ] Flutter: logic deteksi dominan/defisien dari `WuXingBalance`
- [ ] Flutter: ExpansionTile di `bazi_element_balance_card.dart`
