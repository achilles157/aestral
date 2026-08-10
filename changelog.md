# Changelog

Semua perubahan penting di proyek ini akan dicatat di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
dan proyek ini menggunakan [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (Fase 2 — Lintas Tradisi & Knowledge Hub)

- **P2-A: CrossContextBundle** — model agregat weton + BaZi + tarot (`cross_context_service.dart`), refactor `dashboard_sesepuh_card` & `_buildSesepuhHint` pakai bundle (hilangkan duplikasi Map manual)
- **P2-B: Cross-oracle systemsReady guard** — Sesepuh Kosmis hint hanya muncul jika ≥2 dari 3 sistem terisi data (`_getSystemsReadyCount` di `oracle_chat_screen`)
- **P2-C: Knowledge Hub** — halaman Pustaka Kosmis (`/knowledge-hub`) dengan 12 Pranata Mangsa detail, glosarium 30 Wuku, dan istilah kunci (Neptu, Pasaran, Pancasuda, Da Yun). Konten 100% offline dari `assets/` JSON. Deep-link edukasi dari seasonal card ("Pelajari mangsa ini")
- **P2-D: Audit narasi Barnum 3 pilar** — tambah instruksi konteks temporal + actionability di keempat oracle prompt

## [Unreleased] (sebelumnya)

### Added
- **P6 Gemini Quota Management disempurnakan (P1-A rencana 8 Agu)** — modul `gemini_quota.ts` terpisah (KV counter harian, fail-open saat KV error, TTL tengah malam UTC, limit via env `GEMINI_DAILY_LIMIT` default 480), respons 503 terstandar `code: ORACLE_REST` + `retryAfterSeconds` di 4 endpoint AI (`/api/chat`, `/api/tarot/reading`, `/api/bazi/insight`, `/api/oracle/chat`).
- **`OracleRestException` + parser `parseServiceError`** (frontend) — pengganti deteksi string `GEMINI_QUOTA:` yang rapuh; 503 quota **tidak lagi masuk retry loop** `_withRetry` (retry boros kuota); `retryAfterSeconds` dipakai untuk hitung mundur.
- **`OracleRestDialog` on-brand** — modal mystical (tema kosmis) dengan pesan "Sesepuh Sedang Beristirahat" + hitung mundur, terpasang di 9 screen AI (oracle chat, BaZi ×5, weton ×3, tarot, seasonal).
- **Test baru** — backend `test/gemini_quota.test.ts` (12 kasus: limit, exhausted, fail-open, reset harian); Flutter test parser 503, `OracleRestException` (countdown label), widget dialog.

### Fixed
- **Tarot Tematik: narasi sintesis duplikat konklusi untuk semua kartu** — label tematik (potensi/tantangan/arah, daya_tarik/bayangan/langkah, dst.) tidak dikenali map narasi sehingga semua kartu mendapat teks konklusi yang sama. Sekarang: prompt Gemini label-aware (narasi per label asli), parser baru `parseSynthesisResponse`, dan mapping per-kartu dengan fallback hanya untuk label yang tak dijawab. Cache KV di-bump `v2→v3` agar hasil salah yang ter-cache 24 jam langsung invalid.
- **Test integrasi backend menggantung/timeout saat kuota Gemini harian habis** — `GEMINI_API_KEY` kini di-override jadi placeholder di vitest.config sehingga handler balas 503 cepat tanpa menyentuh jaringan (flaky pre-existing dihilangkan).

### Added
- Regression test spread tematik: `parseSynthesisResponse` (5 kasus), `buildSynthesisSystemInstruction` label-aware (2 kasus), `labelDisplayName` (2 kasus) — total 8 test baru di `test/tarot-thematic-synthesis.test.ts`.

### Changed
- **ToS: tambah Seksi 2.3 "Metodologi: Terukur, Bukan Hasil Acak"** — menegaskan bahwa seluruh kalkulasi Aestral (neptu, sisa bagi, Pranata Mangsa, pangarasan/pancasuda, pilar Ba Zi, Wu Xing, Day Master Strength, dek Tarot) berbasis data & aturan tradisional terdokumentasi dengan logika deterministik yang dapat diaudit, diuji otomatis di tiap rilis, lalu diinterpretasi personal oleh Oracle AI. Disclaimer hiburan tetap berlaku (hasil akhir bukan ramalan pasti). Sinkron ke `assets/legal/`.
- `TarotCardInput.label` diperluas dari union `past|present|future` menjadi `string` (mendukung label tematik & mangsa).

### Added
- **Halaman Kebijakan Privasi & Syarat Layanan di dalam aplikasi** — `LegalScreen` baru di `lib/features/legal/` merender markdown dari `assets/legal/` (satu sumber dengan `docs/legal/`), dengan link di `DashboardFooter`. Dokumen berbahasa Indonesia, sadar UU PDP, dan disclaimer tegas bahwa Aestral adalah layanan hiburan/warisan budaya (bukan nasihat profesional, hasil tidak 100% akurat).
- **Font Cinzel & Outfit di-bundle sebagai asset** (`assets/fonts/`) — web app tidak lagi fetch font dari Google saat runtime (loading lebih cepat, offline-friendly, tidak ada flicker teks).
- Seasonal Synthesis Card dengan granularitas Pranata Mangsa
- Ba Zi Annual Pillar AI narrative — tap-to-generate
- Ba Zi Branch Relations psychological narrative per pillar-pair (offline)
- Wu Xing Implication Narrative (offline)
- Weton Compatibility Synthesis Card
- Gemini Daily Quota Management — KV counter + graceful 503
- Cosmic Calibration & Micro-Journal daily check-in
- Ba Zi Canvas enhancements
- `develop` branch untuk isolation development

### Changed
- Pindah dari Daily ke Pranata Mangsa sebagai basis Seasonal Synthesis
- Refactor Ba Zi Branch Relations dari AI endpoint ke pre-written offline maps
- Reframe synthesis prompts — lebih konkret, kurang abstrak
- Soften guest conversion copywriting

### Fixed
- Calendar grid null safety
- Compatibility reset state
- Luck pillars stale cache
- Dual element tie-breaking di weton
- Berbagai audit warning: godId lookup, cache keys, prompt length, a11y labels

## [0.7.0] - 2026-07-28

### Added
- P5, P6, P7 dari Development Roadmap
- Auto-deploy workflow ke Firebase Hosting
- Seasonal Synthesis personalisation dengan weton birth data
- Daily Synthesis Card — 3-tradisi daily briefing
- Ten Gods Archetype summary card
- Annual Pillar Roadmap — Peta Kosmis Tahunan
- Cosmic Calibration & Micro-Journal
- Quick Action / Event Checker — extend Hari Baik Finder
- Top 3 Jam Emas banner di Astrological Planner

### Changed
- Replace deploy.yml dengan Firebase-generated hosting workflows
- Flip compatibility header hierarchy — empathy-first display

### Fixed
- CI build & lint errors
- Dashboard morning forecast offline fallback
- Oracle soft gate teaser — honest preview
- Weton save button UX confusion
- Dino Was → Hari Refleksi Batin (softer UX)

## [0.6.0] - 2026-07-14

### Added
- CI/CD pipeline — test, lint, build, deploy workflows
- Intelligent caching strategy (CacheService + SharedPreferences)
- Intelligent BackdropFilter blur reduction
- Widget & unit tests — coverage foundation
- Firebase Analytics events
- Rounded favicon (SVG)
- Screenshot-based sharing (Weton & Ba Zi)

### Changed
- SavedProfilesScreen: StatefulWidget → ConsumerStatefulWidget
- Remove audit & temp MD files

### Fixed
- CI analyzer warnings resolved
- Test failures & ref.mounted bug
- Production bugs from audit

## [0.5.0] - 2026-07-11

### Added
- Ba Zi clash/harmony indicators di kalender kosmis
- Ba Zi compatibility analysis di /api/weton/compatibility
- Firebase Crashlytics integration
- Shi Chen sirkadian overlay
- Morning forecast
- Ten Gods rebrand

### Fixed
- 3 flutter bug kritis dari audit
- 4 backend bug kritis dari audit security
- 4 backend bug medium dari audit security
- void async tanpa try/catch
- Wuku urgency calculation pindah dari build()

## [0.4.0] - 2026-07-10

### Added
- Guest gating + oracle auto-greeting
- CosmicAuthBottomSheet
- Astrological Planner enhancements
- Onboarding wizard improvements

### Changed
- Refactor: extract login helper classes
- Refactor: extract tarot empty card row builder
- Refactor: Ba Zi 11 result fields → _BaziResultData

### Fixed
- IP fallback + error sanitization
- Model env var injection
- Riverpod idiomatic state management (M8+M9)

## [0.3.0] - 2026-07-09

### Added
- Oracle Chat system — 4 persona
- Weton Compatibility Calculator
- Ba Zi chart AI insights

### Changed
- api_service.dart 454 → 245 baris via shared _post()
- Modularize: weton (605→6 widget), dashboard (1162→174), tarot, bazi (1139→447)
- Centralize auth header building

### Fixed
- K1-K4 security: fake-jwt gate, dynamic CORS, silent catches
- M1-M12 medium issues: birthDate validation, rate limiting, async void, a11y labels
- Riverpod FamilyNotifier → Notifier pattern
- Bearer ID Token di weton & planner oracle buttons

## [0.2.0] - 2026-07-07

### Added
- RS256 JWT signature verification
- UI polish Phase 1-6: type scale, animations, semantics, tooltips
- Dedicated backgrounds per feature
- On-brand SnackBar system
- Directional tab transitions

### Changed
- Externalize hardcoded lookup data ke JSON files
- Rename technical labels → mystical tone
- Untrack .agents/ + firebase_setup_guide

### Fixed
- Security audit: JWT auth, guest UID, Firestore rules

## [0.1.0] - 2026-07-02

### Added
- Weton calculator — offline-first JDN conversion
- Ba Zi Four Pillars engine — Cloudflare Workers
- Tarot drawing — deterministic + weighted RNG
- Wuku-based resonance weighting
- Pranata Mangsa seasonal cycle integration
- Astrological Planner — monthly calendar + Saat Pitu timetable
- Three-Card Tarot Spread (Past, Present, Future)
- Flutter ↔ Cloudflare Workers full integration
- Guest mode with SharedPreferences fallback

### Fixed
- Astrological Planner black screen crash
- Wuku JSON key mapping
- Three-card layout overflow
