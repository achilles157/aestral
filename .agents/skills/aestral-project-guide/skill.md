# Aestral Project Guide

Panduan menyeluruh untuk agent yang bekerja di proyek Aestral. Load skill ini setiap kali mulai bekerja di workspace ini.

---

## Stack & Arsitektur

```
Flutter (Dart)     → Frontend UI (iOS, Android, Web)
Riverpod 3.3+      → State management
Cloudflare Workers  → Backend serverless (TypeScript, free tier)
Firebase           → Auth + Firestore + Crashlytics + Analytics
Gemini 3.1 Flash   → AI Oracle (free tier: 15 RPM, 500 RPD)
SharedPreferences  → Local cache/fallback
```

**Alur data:** Flutter ↔ Cloudflare Workers ↔ Gemini API / Firebase

---

## Non-Negotiables (JANGAN PERNAH DILANGGAR)

### Arsitektur
1. **Zero-budget** — tidak boleh pakai layanan berbayar. Firebase Spark Plan, Cloudflare Free Tier, Gemini Free Tier.
2. **Offline-first untuk Weton** — kalkulasi weton (JDN, Pancawara, Saptawara) HARUS client-side Dart, bukan API call. JSON lookup dari `assets/` via `rootBundle`.
3. **Ba Zi & Tarot kalkulasi di backend** — Ba Zi chart, Luck Pillars, Weighted RNG Tarot di Cloudflare Workers, bukan di Flutter.
4. **AI call selalu lewat Workers** — Flutter tidak boleh langsung panggil Gemini API. Semua lewat `/api/chat`, `/api/oracle/chat`, `/api/bazi/insight`, `/api/tarot/reading`.
5. **Tidak boleh hardcode API key** di Flutter — semua key di environment variable Workers (`wrangler secret`).

### Kode
6. **Feature-based architecture** — setiap fitur di `lib/features/<nama>/` dengan struktur: `data/`, `domain/`, `presentation/`, `providers/`, `services/`.
7. **Riverpod untuk semua state** — tidak boleh pakai `setState` untuk business logic. `setState` hanya untuk UI-local state (animasi, hover).
8. **Indonesian untuk semua UI** — user-facing text, error messages, snackbar, dialog, semua dalam Bahasa Indonesia.
9. **Testing wajib** — fitur baru HARUS ada test. Target coverage 60%+. Backend test pakai vitest, Flutter pakai flutter test.

### Git & CI
10. **Conventional Commits** — format `type(scope): description`. CI akan reject PR yang tidak comply.
11. **Develop branch workflow** — fitur baru dari `develop`, merge ke `main` hanya saat rilis.
12. **Jangan commit tanpa test pass** — `flutter test --coverage` + `flutter analyze` harus clean.

### AI & UX
13. **Barnum Effect di semua teks** — teks statis (JSON kamus) dan AI output harus pakai Dual-Trait Paradox + Esoteric Anchoring + Curiosity Gap.
14. **Tidak boleh klaim absolut** — AI tidak boleh bilang "kamu akan mati", "kamu akan bangkrut". Selalu framing sebagai "kecenderungan energi".
15. **AI tidak boleh menyebut dirinya AI** — "saya adalah AI", "sebagai model bahasa", dll dilarang dalam system instruction.

---

## Development Workflow (Analyze → Design → Proof → Document → Develop → Test)

### 1. Analyze
- Baca PRD terkait di `PRD/` dan plan di `docs/plans/`
- Pahami user story dan data flow
- Identifikasi file yang perlu diubah/dibuat

### 2. Design
- Tentukan endpoint baru (jika perlu) — tulis spec di `docs/specs/`
- Tentukan model data (Dart class / TypeScript interface)
- Tentukan UI layout dan widget yang diperlukan

### 3. Proof
- Tulis test cases dulu SEBELUM implementasi
- Backend: `aestral-backend/test/` dengan vitest
- Flutter: `test/` dengan flutter test
- Pastikan test FAIL dulu (red), baru implementasi (green)

### 4. Document
- Update PRD jika ada perubahan signifikan
- Update `CHANGELOG.md` (Unreleased section)
- Update skill ini jika ada perubahan arsitektur/konvensi

### 5. Develop
- **Backend dulu, Flutter kemudian** — jangan paralel kalau Flutter bergantung pada API baru
- Implementasi dengan pola: provider → service → screen → widget
- Gunakan `CacheService.generateKey()` untuk caching
- Gunakan `_withRetry()` dari `api_service.dart` untuk network calls

### 6. Test (E2E)
- `cd aestral-backend && npx vitest run`
- `flutter test --coverage`
- `flutter analyze` — harus nol error/warning
- `dart format .` — harus clean
- Cek manual di emulator/device untuk UI changes

---

## Menambah Fitur Baru — Langkah Konkret

### Backend (Cloudflare Workers)

1. **Logic module** — tambah fungsi di `aestral-backend/src/<module>.ts`
2. **Router** — tambah handler di `aestral-backend/src/router.ts`
3. **Type interface** — definisikan body type di dekat handler
4. **Rate limiting** — gunakan `isRateLimited()` dengan konstanta limit
5. **Auth** — panggil `requireAuth()`; untuk feature khusus registered, tolak guest dengan 403
6. **Test** — tambah di `aestral-backend/test/`

### Flutter

1. **API method** — tambah static method di `lib/core/services/api_service.dart`
2. **Provider** — buat di `lib/features/<fitur>/providers/`
3. **Service** — buat di `lib/features/<fitur>/services/` jika ada caching/logic
4. **Screen** — buat di `lib/features/<fitur>/presentation/`
5. **Widgets** — pecah screen besar menjadi widget files di `presentation/widgets/`
6. **Test** — tambah di `test/features/<fitur>/`

---

## File Yang Sering Diubah

| Task | File Utama |
|------|-----------|
| Tambah endpoint API | `aestral-backend/src/router.ts` |
| Logic weton | `aestral-backend/src/weton.ts` |
| Logic bazi | `aestral-backend/src/bazi.ts` |
| Logic tarot | `aestral-backend/src/tarot.ts` |
| AI prompt builder | `aestral-backend/src/system_prompt.ts` |
| Oracle personas | `aestral-backend/src/oracle_prompts.ts` |
| Flutter API calls | `lib/core/services/api_service.dart` |
| Caching | `lib/core/services/cache_service.dart` |
| Theme/styling | `lib/core/theme/app_theme.dart` |
| Navigation tabs | `lib/features/home/presentation/main_shell.dart` |

---

## Reading Order Untuk Agent Baru

1. `README.md` — gambaran project
2. `plan.md` — visi proyek dan 4 fase
3. `PRD/development_roadmap.md` — status implementasi P1-P7
4. `docs/specs/2026-06-30-cloudflare-workers-backend-design.md` — desain backend
5. `aestral-backend/src/router.ts` — semua endpoint
6. `lib/features/home/presentation/main_shell.dart` — struktur navigasi
7. `lib/core/services/api_service.dart` — semua API call
8. `CHANGELOG.md` — riwayat perubahan
9. `.github/workflows/` — CI/CD pipeline
