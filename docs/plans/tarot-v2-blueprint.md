# Rencana Implementasi — Sistem Tarot Aestral v2

> **Status:** Blueprint — hasil brainstorming & validasi 2026-08-06
> **Fase target:** Fase 2→3 (post-MVP stabilization)
> **Dependensi:** Weton Utils, Ba Zi Utils, Cloudflare Workers, Gemini API

---

## 1. Visi Sistem Tarot Baru

Satu sistem tarot terpadu dengan **3 fitur utama + 1 trigger cerdas**, semua berbagi model pembobotan yang sama dan pipeline sintesis AI yang sama. Personalisasi sejati dicapai melalui kombinasi Weton + Ba Zi, bukan salah satunya.

### 1.1 Fitur yang Dipertahankan

| # | Fitur | Frekuensi | Kartu | Pembobotan |
|---|---|---|---|---|
| 1 | **Tarot Lahir** (Soul Blueprint) | Sekali seumur hidup | 1 kartu | Weton 50% + Ba Zi 50% |
| 2 | **Tarot Mangsa** (rebrand dari Kosmis) | Tiap pergantian Mangsa (~30 hari) | 2 kartu: Energi + Panduan | Weton 40% + Ba Zi 45% + Mangsa 15% |
| 3 | **Tarot Tematik** | On-demand (user pilih area) | 3 kartu tematik | Weton 40% + Ba Zi 45% + Area 15% |

### 1.2 Fitur Baru

| # | Fitur | Frekuensi | Kartu | Trigger |
|---|---|---|---|---|
| 4 | **Tarot Momen Kosmis** (Event-Driven) | 2-4x per bulan | 1 kartu | Otomatis saat hari astrologi spesial |

### 1.3 Fitur yang Ditolak

| Fitur | Alasan |
|---|---|
| Tarot Journey 7 Hari | Terlalu banyak ramalan → repetitif, kurang genuine |
| Tarot Harian (setiap hari) | Diganti event-driven — lebih bermakna, tidak spam |

---

## 2. Model Pembobotan Terpadu: "Trinitas Kosmis"

Semua fitur tarot menggunakan framework bobot yang sama dengan proporsi berbeda.

### 2.1 Kerangka

```
Bobot Kartu = Weton_Bobot + BaZi_Bobot + Konteks_Bobot
```

### 2.2 Dimensi Weton (bobot total bervariasi per fitur)

| Parameter | Tipe | Deskripsi |
|---|---|---|
| `pangarasan` | Enum (8 nilai) | Karakter bawaan — resonansi awal |
| `total_neptu` | Integer (7-18) | Intensitas energi — tinggi → kartu Major Arcana lebih mungkin |
| `wuku_aktif` | Enum (30 nilai) | Siklus mingguan — memengaruhi elemen dominan |
| `mangsa_aktif` | Integer (1-12) | Siklus musim — tema energi periode |

### 2.3 Dimensi Ba Zi (3 variabel untuk semua fitur)

| # | Parameter | Sumber | Dampak |
|---|---|---|---|
| 1 | `day_master_element` | `calculateBaziChart().dayMasterElement` | **Resonansi:** kartu dengan elemen yang sama atau yang dihasilkan DM → bobot +0.5 |
| 2 | `day_master_polarity` | `calculateBaziChart().dayPillar.stemIndex % 2` | **Yin/Yang:** memengaruhi upright/reversed tendency — Yin → reversed lebih mungkin |
| 3 | `wu_xing_dominant` | `calculateBaziChart().wuXingBalance` | **Kompensasi:** kartu dengan elemen yang mengontrol dominant → bobot +0.4 |

### 2.4 Siklus Wu Xing (untuk resonansi & kontrol)

```
Menghasilkan (Sheng):  Kayu → Api → Tanah → Logam → Air → Kayu
Mengontrol (Ke):       Kayu → Tanah → Air → Api → Logam → Kayu
```

### 2.5 Pemetaan Elemen Tarot

| Suit | Elemen | Wu Xing |
|---|---|---|
| Cups (Piala) | Air | 💧 Air |
| Wands (Tongkat) | Api | 🔥 Api |
| Pentacles (Koin) | Tanah | 🏔️ Tanah |
| Swords (Pedang) | Logam | ⚔️ Logam |
| Major Arcana | Spirit | 🌱 Kayu (netral) |

---

## 3. Spesifikasi Per Fitur

### 3.1 Tarot Lahir (Soul Blueprint)

**Tujuan:** Kartu jiwa seumur hidup — personal, unik, tidak berubah.

**Input:**
- `birthDate` (YYYY-MM-DD)
- `pangarasan` (dari Weton)
- `dayMasterElement` (dari Ba Zi)
- `dayMasterPolarity` (dari Ba Zi)
- `wuXingDominant` (dari Ba Zi)

**Algoritma:**
```
seed = hash(birthDate + pangarasan + dayMasterElement)
card = deterministicDraw(seed)
if dayMasterPolarity == Yin: card.orientation = reversed (50% chance)
```

**Output:** 1 kartu dengan upright/reversed.

**Prompt Assembly AI:**
```
[DATA KARTU dari JSON tarot-merged.json]
[DATA WETON: {weton_name}, Neptu {neptu}, Pangarasan {pangarasan}]
[DATA BA ZI: Day Master {element} {polarity}, Dominant {element}, Yong Shen {elements}]
[ALASAN: Kartu ini muncul karena {resonance_reason} + {compensation_reason}]

Tugas: Jahit menjadi 3-4 kalimat narasi personal yang menjelaskan
jiwa inti pengguna — bukan prediksi, tapi blueprint.
```

**Kompleksitas:** ~3,500 kemungkinan unik (35 weton × 10 DM × 2 polarity × 5 dominant).

### 3.2 Tarot Mangsa (Rebrand dari "Kosmis")

**Tujuan:** Energi periode berdasarkan siklus Pranata Mangsa — refleksi tiap ~30 hari.

**Perubahan dari yang sekarang:**
- Nama: "Tarot Kosmis" → "Tarot Mangsa"
- Format: 3 kartu Past/Present/Future → **2 kartu Energi + Panduan**
- Pembobotan: Weton only → Weton + Ba Zi + Mangsa

**Input:**
- `birthDate`, `pangarasan` (Weton)
- `dayMasterElement`, `wuXingDominant` (Ba Zi)
- `mangsaId` (1-12, Pranata Mangsa aktif)

**Algoritma:**
```
Energi seed = hash(birthDate + mangsaId + dayMasterElement)
Panduan seed = hash(birthDate + mangsaId + wuXingDominant + yongShen)
kartu_energi = seededDraw(Energi seed, bias: mangsa_theme)
kartu_panduan = seededDraw(Panduan seed, bias: yongShen_element)
```

**Label kartu:**
- Kartu 1: **"Energi {nama_mangsa}"** — apa yang sedang berputar di alam dan memengaruhimu
- Kartu 2: **"Panduan Pribadi"** — apa yang perlu kamu lakukan di periode ini

**Template AI (Layer 2 cache key):**
```
template_mangsa_{mangsaId}_{dayMasterElement}:
  "Dengan Mangsa {nama} yang bertema {tema}, dan Day Master {element}-mu,
   energi periode ini mengalir sebagai..."
```

**Cache template yang dibutuhkan:** 12 mangsa × 5 Day Master = 60 template (6,000-9,000 token total pre-generation)

### 3.3 Tarot Tematik

**Tujuan:** Tarot on-demand untuk area hidup spesifik — user yang menentukan konteks.

**Input:**
- Semua input standar (Weton + Ba Zi)
- `area` (enum: karir, asmara, keuangan, spiritual, kesehatan)
- Opsional: `user_question` (teks bebas, maks 200 karakter)

**Area → Elemen:**

| Area | Elemen Dominan | Elemen Pendukung |
|---|---|---|
| Karir & Ambisi | Api (Wands) | Logam (Swords) |
| Asmara & Relasi | Air (Cups) | Tanah (Pentacles) |
| Keuangan & Stabilitas | Tanah (Pentacles) | Logam (Swords) |
| Spiritual & Growth | Kayu (Major Arcana) | Air (Cups) |
| Kesehatan & Vitalitas | Kayu (Major Arcana) | Tanah (Pentacles) |

**Algoritma:**
```
area_bias = element_bonus(area.dominant, area.support)
for each of 3 slots:
  slot_seed = hash(birthDate + area + slot_index + timestamp_day)
  kartu = seededWeightedDraw(slot_seed, weton_bias + bazi_bias + area_bias)
```

**3 Kartu Tematik (konteks per area):**

| Posisi | Karir | Asmara | Keuangan | Spiritual | Kesehatan |
|---|---|---|---|---|---|
| Kartu 1 | Potensi | Daya Tarik | Sumber | Panggilan | Vitalitas |
| Kartu 2 | Tantangan | Bayangan | Kebocoran | Rintangan | Kelemahan |
| Kartu 3 | Arah | Langkah | Strategi | Pesan | Ritme |

**AI Assembly:**
```
[3 KARTU dari JSON + posisi]
[DATA LENGKAP ASTROLOGI]
[AREA: {area_name}, PERTANYAAN USER: {user_question}]
[ALASAN PEMBOBOTAN per kartu]

Tugas: Jahit narasi tematik 5-7 kalimat. Bukan horoskop generik —
spesifik ke area yang dipilih dan data astrologi user.
```

### 3.4 Tarot Momen Kosmis (Event-Driven)

**Tujuan:** Undangan personal saat hari astrologi spesial — bukan spam harian.

**Trigger Events:**

| Event | Frekuensi | Trigger Logic |
|---|---|---|
| Hari Weton | ~1x/35 hari | `birthWeton.saptawara == todayWeton.saptawara && birthWeton.pancawara == todayWeton.pancawara` |
| Dino Was | ~1x/35 hari | `checkIsDinoWas(birthDate, today)` |
| Ba Zi Clash | ~1x/12 hari | `abs(dayBranch - birthDayBranch) == 6` |
| Yong Shen Day | ~1x/10 hari | `yongShen.includes(dayStemElement) \|\| yongShen.includes(dayBranchElement)` |

**Mekanisme:**
- Backend cron atau client-side check saat user buka app
- Kalau hari ini ada event → tampilkan banner/notifikasi "Momen Kosmismu hari ini"
- User tap → tarik 1 kartu dengan bobot event tersebut

**Bobot per event:**

| Event | Bobot spesial |
|---|---|
| Hari Weton | Major Arcana +0.5 (hari sakral) |
| Dino Was | Kartu "reflektif" +0.6 (Hermit, High Priestess, Moon, Hanged Man) |
| Ba Zi Clash | Elemental opposite +0.4 (kartu yang elemennya mengontrol Day Master) |
| Yong Shen Day | Yong Shen element +0.7 (harmoni maksimal) |

**Output:** 1 kartu + narasi 2-3 kalimat + ajakan: "Mau tanya lebih lanjut ke Oracle?"

---

## 4. Arsitektur AI — 3-Layer Caching

### 4.1 Layer 1: Static Card Base (JSON Lokal)

**Sumber:** `assets/tarot/tarot-merged.json` (245KB, 78 kartu)

**Isi per kartu:**
```json
{
  "id": 0,
  "nameId": "The Fool",
  "nameEn": "The Fool",
  "uprightMeaningId": "Awal baru, potensi tak terbatas...",
  "reversedMeaningId": "Kecerobohan, kurang persiapan...",
  "elementalId": "Kayu",
  "archetypeId": "Sang Pemimpi",
  "keywordsId": "awal, petualangan, kebebasan, risiko",
  "aiHookId": "Langkah pertama tanpa mengetahui tujuan"
}
```

**Digunakan untuk:** Semua fitur tarot — makna dasar kartu tidak perlu Gemini.

### 4.2 Layer 2: Astrological Context Cache (Cloudflare KV)

**Pre-generate saat build:** 60 template untuk Tarot Mangsa + 20 template untuk Momen Kosmis + 20 template untuk Tarot Lahir.

**Format KV entry:**
```
Key:   "tarot_template_{fitur}_{kombinasi}"
Value: "Dengan Day Master Kayu Yang dan Mangsa Kawolu yang berenergi transisi
        panen, kartu ini muncul sebagai cerminan dari..."
TTL:   No expiration (invalidated manual saat data astrologi diupdate)
```

**Build script:** `aestral-backend/scripts/generate-tarot-templates.ts`
- Loop semua kombinasi
- Panggil Gemini 1x per template
- Simpan ke KV via Wrangler API
- Total: ~100 panggilan Gemini sekali di build time

### 4.3 Layer 3: Runtime Assembly (Gemini per Request)

**Prompt structure (standar untuk semua fitur):**
```
[MAKNA KARTU - dari Layer 1, 80-120 token]
[TEMPLATE KONTEKS - dari Layer 2, 100-150 token]
[DATA USER SPESIFIK - weton + ba zi + event/area, 50-80 token]
[ALASAN PEMBOBOTAN - 3 alasan kenapa kartu ini muncul, 40-60 token]
[INSTRUKSI - 2-3 kalimat, 30-50 token]

TOTAL PROMPT: ~350 token (vs ~1200 tanpa caching)
TARGET OUTPUT: 150-200 token (narasi 3-5 kalimat)
```

**Cache miss fallback:**
```
IF KV.get(templateKey) == null:
  response = Gemini(fullPrompt)  // prompt lebih panjang
  KV.put(templateKey, extractTemplate(response))
  return response
```

### 4.4 Estimasi Token & Biaya

| Skenario | Tanpa Cache | Dengan Cache | Hemat |
|---|---|---|---|
| 1 request | ~1,600 token | ~550 token | 65% |
| 100 user × 3/bulan | 480,000 token | 165,000 token | 65% |
| 1,000 user × 3/bulan | 4,800,000 token | 1,650,000 token | 65% |
| Build-time pregen | 0 | ~15,000 token (sekali) | — |

**Gemini free tier (1,500 RPD) → ~933 request/hari feasible dengan caching.**
Tanpa caching hanya ~234 request/hari.

---

## 5. Backend API Design

### 5.1 Endpoint Baru: `/api/tarot/synthesis`

```
POST /api/tarot/synthesis
Auth: Bearer <firebase_jwt>

Body:
{
  "feature": "birth" | "mangsa" | "thematic" | "moment",
  "birthDate": "1990-05-15",
  "pangarasan": "Lakuning Angin",
  "dayMasterElement": "kayu",
  "dayMasterPolarity": "yang",
  "wuXingDominant": "api",
  "yongShen": ["air", "tanah"],
  "mangsaId": 8,              // untuk feature=mangsa
  "area": "karir",            // untuk feature=thematic
  "userQuestion": "...",      // opsional untuk thematic
  "eventType": "hari_weton"   // untuk feature=moment
}

Response:
{
  "success": true,
  "cards": [
    {
      "cardIndex": 14,
      "nameId": "The Star",
      "isReversed": false,
      "element": "air",
      "archetype": "Sang Penerang",
      "position": "Energi Mangsa Kawolu",
      "reasoning": [
        "Day Master Kayu mencari keseimbangan — The Star berelemen Air menyejukkan",
        "Yong Shen Air memperkuat resonansi kartu ini",
        "Mangsa Kawolu bertema panen — The Star menandakan hasil dari benih yang ditanam"
      ]
    }
  ],
  "synthesis": "The Star muncul untukmu di Mangsa Kawolu...",
  "cached": true
}
```

### 5.2 Modifikasi Endpoint: `/api/tarot/draw`

Tambahkan parameter Ba Zi untuk backward compatibility:

```
Body tambahan (opsional):
{
  "dayMasterElement": "kayu",
  "dayMasterPolarity": "yang",
  "wuXingDominant": "api"
}
```

### 5.3 KV Namespace

```
Binding di wrangler.toml:
[[kv_namespaces]]
binding = "TAROT_CACHE"
id = "<kv_namespace_id>"
```

---

## 6. Rencana Implementasi — Fase & Timeline

### Fase 2A: Fondasi Bobot Ba Zi (Minggu 1-2)

| Task | File | Estimasi |
|---|---|---|
| Tambah `dayMasterElement` + `polarity` + `wuXingDominant` ke payload tarot draw | `lib/core/services/api_service.dart`, `lib/features/tarot/presentation/tarot_draw_screen.dart` | 2 jam |
| Modifikasi `handleTarotDraw` terima parameter Ba Zi | `aestral-backend/src/router.ts` | 1 jam |
| Update fungsi `getDeterministicThreeCards` & `getMangsaDeterministicThreeCards` terima Ba Zi params | `aestral-backend/src/tarot.ts` | 3 jam |
| Implementasi Wu Xing resonance & compensation logic | `aestral-backend/src/tarot.ts` | 4 jam |
| Test & verifikasi — pastikan 2 user weton sama + Ba Zi beda → hasil beda | Manual test | 1 jam |

### Fase 2B: Tarot Mangsa Rebrand (Minggu 3)

| Task | File | Estimasi |
|---|---|---|
| Ganti label "Kosmis" → "Mangsa" di UI | `tarot_draw_screen.dart`, `tarot_draw_type_toggle.dart` | 1 jam |
| Format 3 kartu → 2 kartu (Energi + Panduan) | `tarot_draw_screen.dart` | 3 jam |
| UI baru: 2 kartu side-by-side, layout vertical stack | Widget baru | 3 jam |
| Backend: endpoint baru atau flag `format: "mangsa_2card"` | `router.ts`, `tarot.ts` | 2 jam |
| Update seasonal synthesis card referensi | `seasonal_synthesis_card.dart` | 1 jam |

### Fase 2C: 3-Layer AI Caching (Minggu 3-4)

| Task | File | Estimasi |
|---|---|---|
| Buat Layer 1 resolver — fungsi ambil makna kartu dari JSON | `aestral-backend/src/tarot_reading_prompt.ts` | 2 jam |
| Buat build script untuk pre-generate template | `aestral-backend/scripts/generate-tarot-templates.ts` | 4 jam |
| Setup KV namespace di Cloudflare | `wrangler.toml` | 1 jam |
| Modifikasi `/api/tarot/reading` pakai 3-layer flow | `router.ts` | 3 jam |
| Implementasi cache-miss fallback | `router.ts` | 1 jam |
| Endpoint baru `/api/tarot/synthesis` untuk standarisasi | `router.ts` | 3 jam |

### Fase 3A: Tarot Momen Kosmis (Minggu 5)

| Task | File | Estimasi |
|---|---|---|
| Implementasi event detection logic (Hari Weton, Dino Was, Ba Zi Clash, Yong Shen) | `lib/core/services/cosmic_journal_service.dart` (extend) | 4 jam |
| Backend endpoint `/api/tarot/moment` | `router.ts`, `tarot.ts` | 2 jam |
| UI: Momen Kosmis card di dashboard (muncul hanya saat ada event) | `dashboard_screen.dart`, widget baru | 3 jam |
| Notifikasi push trigger (optional, deferred) | Firebase Cloud Messaging setup | Deferred |
| Single card draw + AI synthesis pendek | `tarot.ts`, `router.ts` | 2 jam |

### Fase 3B: Tarot Tematik (Minggu 6-7)

| Task | File | Estimasi |
|---|---|---|
| UI: Area selector (5 pilihan + "tulis pertanyaan sendiri") | Widget baru | 4 jam |
| Area→elemen mapping di backend | `tarot.ts` | 1 jam |
| 3 kartu tematik draw algorithm | `tarot.ts` | 3 jam |
| AI synthesis dengan area context | Prompt template | 2 jam |
| UI: 3 kartu hasil + narasi + "Tanya Madame Sophia" CTA | Widget baru | 4 jam |
| Simpan ke reading history dengan tag area | `tarot_draw_screen.dart` | 1 jam |

---

## 7. Dependensi & Prasyarat

### 7.1 Data yang Harus Tersedia

| Data | Sumber | Status |
|---|---|---|
| Weton (saptawara, pancawara, neptu, pangarasan) | `WetonUtils.calculateWeton()` | ✅ Sudah ada |
| Wuku aktif | `WetonUtils.calculateWeton().wuku` | ✅ Sudah ada |
| Pranata Mangsa | `WetonUtils.calculatePranataMangsaId()` | ✅ Sudah ada |
| Ba Zi chart (Day Master, polarity, Wu Xing) | `calculateBaziChart()` | ✅ Sudah ada |
| Yong Shen | `calculateBaziChart().dmStrength.yongShen` | ✅ Sudah ada |
| Tarot card meanings (78 kartu) | `assets/tarot/tarot-merged.json` | ✅ Sudah ada |

### 7.2 Infrastruktur

| Komponen | Status | Catatan |
|---|---|---|
| Cloudflare Workers | ✅ Deployed | `aestral-backend` |
| Cloudflare KV | ⚠️ Perlu setup | Namespace baru `TAROT_CACHE` |
| Gemini API | ✅ Active | Quota 1,500 RPD |
| Firebase Auth | ✅ Active | JWT verification ready |
| Firestore (reading history) | ✅ Active | Struktur existing cukup |

---

## 8. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Gemini daily quota habis | User tidak dapat synthesis | Fallback ke Layer 1-only (makna dasar tanpa personalisasi) — info di UI "Oracle sedang beristirahat" |
| KV cache miss di awal | Token usage naik sementara | Cache warming script saat deploy — isi template yang paling umum dulu |
| User belum isi Ba Zi (guest / jam lahir kosong) | Bobot tidak lengkap | Fallback: Weton-only dengan bobot 100%, beri info "isi jam lahir untuk personalisasi lebih dalam" |
| Mangsa/Wuku data tidak sync dengan frontend | Hasil tarot berbeda antara user yang seharusnya sama | Single source of truth di backend — semua kalkulasi di worker, frontend hanya display |
| User bingung "Tarot Mangsa" vs "Tarot Kosmis" lama | User ekspektasi salah | Migration notice di UI: "Tarot Kosmis kini hadir sebagai Tarot Mangsa — lebih selaras dengan siklus alam Nusantara" |

---

## 9. Sukses Metrics

| Metrik | Baseline | Target |
|---|---|---|
| Unique Soul Card combinations | ~35 (weton only) | 1,000+ (dengan Ba Zi) |
| Gemini token per tarot synthesis | ~1,600 | ≤550 |
| KV cache hit rate | 0% | ≥85% setelah 2 minggu |
| Tarot Mangsa DAU trigger | 0 (fitur baru) | ≥40% user aktif pakai tiap ganti mangsa |
| Tarot Momen Kosmis engagement | 0 (fitur baru) | ≥60% user buka saat trigger muncul |
| Tarot Tematik completion rate | 0 (fitur baru) | ≥70% user yang pilih area → baca synthesis → lanjut Oracle Chat |

---

## 10. Urutan Pengerjaan

```
Phase 2A: Bobot Ba Zi di semua tarot      [Minggu 1-2] ← FONDASI
    │
Phase 2B: Tarot Mangsa rebrand            [Minggu 3]   ← UI + rename
    │
Phase 2C: 3-Layer AI caching              [Minggu 3-4] ← INFRA
    │
Phase 3A: Tarot Momen Kosmis              [Minggu 5]   ← Engagement trigger
    │
Phase 3B: Tarot Tematik                   [Minggu 6-7] ← Flagship fitur baru
```

Selesai dalam **~7 minggu** dengan 1 developer. Bisa paralel jika ada tim.
