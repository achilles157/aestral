# Aestral Development Workflow

Proses standar untuk setiap issue, fitur, atau perubahan di proyek Aestral. Semua agent wajib mengikuti workflow ini — tidak ada shortcut.

---

## Golden Rule

> **Test dulu, baru kode. Backend dulu, baru Flutter. Document sambil jalan, bukan di akhir.**

---

## Workflow 6 Fase

```
ANALYZE → DESIGN → PROOF → DOCUMENT → DEVELOP → TEST
  ↓         ↓        ↓         ↓          ↓        ↓
PRD      Spec    Test      CHANGELOG   Kode    Coverage
Plan     Model   Cases     PRD update  API     Lint
Files    UI      (RED)     Skill upd   Widgets Format
```

### 1. ANALYZE — Pahami Masalah

- Baca dokumen PRD terkait di `PRD/`
- Baca plan terkait di `docs/plans/` atau `docs/specs/`
- Identifikasi user story dan data flow
- List semua file yang akan diubah atau dibuat

### 2. DESIGN — Rancang Solusi

- Jika butuh endpoint API baru: tulis spec di `docs/specs/YYYY-MM-DD-nama-fitur.md`
- Definisikan TypeScript interface atau Dart model class
- Sketsa UI layout — widget apa di mana
- Tentukan caching strategy dan rate limit

### 3. PROOF — Tulis Test Dulu (RED)

- Tulis test cases SEBELUM kode implementasi
- Backend: `aestral-backend/test/` dengan vitest
- Flutter: `test/` dengan flutter test
- **Pastikan test FAIL dulu** — bukti bahwa test benar-benar menguji sesuatu

### 4. DOCUMENT — Dokumentasi Sambil Jalan

- Update `CHANGELOG.md` — tambah di `[Unreleased]`
- Update PRD jika ada perubahan signifikan
- Update skill `aestral-project-guide` jika arsitektur berubah

### 5. DEVELOP — Implementasi

**Urutan:** Backend dulu → Flutter kemudian

- Backend: logic module → handler di router.ts
- Flutter: API method → provider → service → screen → widget
- Gunakan `CacheService.generateKey()` untuk caching
- Gunakan `_withRetry()` dari `api_service.dart`

### 6. TEST — Verifikasi End-to-End

1. `cd aestral-backend && npx vitest run`
2. `flutter test --coverage`
3. `flutter analyze` — **nol error, nol warning**
4. `dart format .` — clean
5. Manual check di emulator/device

---

## Branching & Commit Rules

### Branch Strategy
```
main       ← HANYA merge dari develop saat rilis (tagged)
develop    ← Development utama, selalu stabil
feature/*  ← Satu fitur per branch, dari develop, merge ke develop
fix/*      ← Bug fix
```

### Commit Format
```
type(scope): deskripsi singkat dalam Bahasa Indonesia

Valid types: feat, fix, refactor, perf, docs, style, test, ci, chore, build, revert
Scope opsional: weton, bazi, tarot, backend, ui, auth, planner
```

---

## Checklist Per Fitur

Sebelum merge PR:

- [ ] Test ditulis dan PASS
- [ ] Coverage ≥60%
- [ ] `flutter analyze` — nol error/warning
- [ ] `dart format .` — clean
- [ ] `npx vitest run` — PASS
- [ ] CHANGELOG.md di-update
- [ ] Tidak hardcode API key atau secret
- [ ] Error messages dalam Bahasa Indonesia
- [ ] Guest mode tetap berfungsi
- [ ] Commit message conventional format
- [ ] Branch dari `develop`, PR ke `develop`

---

## File Yang WAJIB Dicek Sebelum Commit

| Cek | Command |
|-----|---------|
| Backend test | `cd aestral-backend && npx vitest run` |
| Flutter test | `flutter test --coverage` |
| Static analysis | `flutter analyze` |
| Format | `dart format .` |
| Git status | `git status` |

---

## Anti-Patterns (JANGAN)

- ❌ Commit langsung ke `main`
- ❌ Push tanpa test pass
- ❌ Skip test dengan alasan "perubahan kecil"
- ❌ Hardcode string yang sama di 3+ tempat
- ❌ Comment out test yang fail
- ❌ `print()` di production code (pakai `debugPrint()`)
- ❌ Widget >300 baris tanpa dipecah
- ❌ Mixed language dalam satu file
