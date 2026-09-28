# Rencana Stabilisasi Aestral — v0.9.0 "Fondasi Kuat"

**Dibuat:** 2026-09-23
**Basis:** hasil evaluasi menyeluruh 23 Sep 2026 (branch `develop`, bersih)
**Tujuan:** menutup utang teknis di jalur kritis sebelum siklus fitur baru / monetisasi
**Status:** MENUNGGU PERSETUJUAN USER

---

## Ringkasan Kondisi Awal (baseline terverifikasi)

| Metrik | Nilai awal | Target v0.9.0 |
|---|---|---|
| Flutter test | 215 PASS | ≥250 PASS |
| Backend test | 162 PASS | ≥162 PASS (jangan turun) |
| Coverage Dart | **64.54%** (872/1351) | **≥70%** |
| `flutter analyze` | 0 error, 0 warning, **460 info** | **0 error, 0 warning, ≤50 info** |
| File >350 baris | **33 file** | ≤20 file |
| Fitur tanpa test | 6 (ai, tarot, home, learning, profiles, history) | 2 |
| README akurasi | stale parah (versi, coverage, kontak) | akurat |

**Aturan main (tidak bisa ditawar):**
- Setiap perubahan lewat branch `fix/*` / `refactor/*` / `test/*` dari `develop`, PR ke `develop`.
- Conventional Commits, deskripsi Bahasa Indonesia.
- Test dulu (RED) → implementasi (GREEN), sesuai workflow project.
- Gate wajib tiap PR: `flutter test --coverage` + `npx vitest run` + `flutter analyze` (0 error/warning) + `dart format .` clean.
- Jangan push sampel non-code-app (preferensi user).
- Cek CI + preview PR sebelum merge; `gh pr merge --merge` tanpa `--delete-branch`.

---

## PRIORITAS 1 — KRITIS (bug potensial, kerjakan lebih dulu)

### S1. Perbaiki 8× `use_build_context_synchronously` — risiko crash
**Kenapa kritis:** lint ini menandai penggunaan `context` setelah `await` yang dijaga oleh `mounted` **yang tidak relevan**. Pada widget yang memakai `StateNotifier`/provider, `mounted` bisa `true` padahal widget sudah di-deaktivasi → `setState`/`showDialog` setelah dispose = crash di production.

**File & lokasi (semua pola sama, baris ke-43 kolom pada blok catch):**

| File | Baris |
|---|---|
| `lib/features/bazi/presentation/widgets/bazi_annual_pillar_card.dart` | 386 |
| `lib/features/bazi/presentation/widgets/bazi_element_balance_card.dart` | 334 |
| `lib/features/bazi/presentation/widgets/bazi_four_pillars_chart.dart` | 467 |
| `lib/features/bazi/presentation/widgets/bazi_relations_card.dart` | 553 |
| `lib/features/home/presentation/widgets/seasonal_synthesis_card.dart` | 201 |
| `lib/features/weton/presentation/weton_compatibility_screen.dart` | 976 |
| `lib/features/weton/presentation/widgets/weton_ai_synthesis_section.dart` | 162 |
| `lib/features/weton/presentation/widgets/weton_birth_synthesis_section.dart` | 88 |

**Pola masalah (terkonfirmasi di `seasonal_synthesis_card.dart`):**
```dart
} catch (e) {
  debugPrint('... error: $e');
  if (context.mounted) {                       // ← guard di blok catch
    OracleRestDialog.showIfOracleRest(context, e);
  }
  if (mounted) setState(() => _error = true);  // ← 'mounted' di sini maksudnya
}                                              //   state widget, tapi analyzer
                                               //   menilai guard catch-nya
                                               //   "tidak berkorelasi"
```

**Perbaikan yang benar:** gunakan `if (!mounted) return;` **segera setelah setiap `await`** di dalam method `State` (bukan `context.mounted` yang di-scope sempit), lalu bebas pakai `context` sesudahnya. Untuk widget stateless/`ConsumerWidget`, ganti ke `StatefulWidget` atau pakai `ref.mounted` / ambil dependency sebelum `await`.

**Kriteria selesai:**
- [ ] 8 lint `use_build_context_synchronously` hilang
- [ ] Tidak ada penambahan lint baru
- [ ] Semua 215 test tetap PASS
- [ ] Manual check: buka layar seasonal card, Ba Zi ×4, weton ×2 → trigger error state, tidak crash

---

### S2. Audit & perbaiki 39× `unawaited_futures`
**Kenapa kritis:** `Future` yang tidak di-`await` bisa menyebabkan race condition (mis. tulis cache belum selesai, lalu dibaca) atau error yang hilang tanpa jejak.

**Sebaran (per file, dari analyze):**

| File | Jumlah | Baris |
|---|---|---|
| `lib/features/bazi/presentation/bazi_calculator_screen.dart` | 5 | 236, 306, 307, 323, 369 |
| `lib/features/home/presentation/dashboard_screen.dart` | 4 | 74, 77, 129, 165 |
| `lib/features/ai/providers/oracle_chat_provider.dart` | 2 | 253, 347 |
| `lib/core/widgets/ai_astrologer_dialog.dart` | 1 | 52 |
| `lib/features/ai/presentation/oracle_chat_screen.dart` | 1 | 88 |
| `lib/features/auth/presentation/login_screen.dart` | 1 | 115 |
| `lib/features/history/presentation/history_screen.dart` | 1 | 31 |
| + sisanya tersebar di file lain (total 39) | — | — |

**Cara kerja:** klasifikasikan tiap kasus jadi 3 golongan:
1. **Harus di-`await`** — kalau hasilnya memengaruhi langkah berikutnya (mis. cache write sebelum read).
2. **Sengaja fire-and-forget** — bungkus `unawaited(...)` dari `dart:async` (eksplisit, lint tetap bersih).
3. **Bug nyata** — perbaiki logikanya.

**Kriteria selesai:**
- [ ] 39 lint `unawaited_futures` hilang (via `await` atau `unawaited()` yang eksplisit)
- [ ] Tidak ada perubahan perilaku yang tidak disengaja — dibuktikan test lulus
- [ ] Flag tiap kasus yang termasuk golongan "bug nyata" di deskripsi PR

---

### S3. Audit 26× `avoid_dynamic_calls`
**Kenapa kritis:** akses `.toDouble()` / properti pada `dynamic` bisa meledak jadi `NoSuchMethodError` saat runtime kalau shape JSON berubah.

**Contoh ditemukan:**
```dart
// lib/core/models/birth_profile.dart:81-82
latitude: (coords?['lat'] as num?)?.toDouble(),
// lib/features/ai/presentation/oracle_card_widgets.dart:198
final value = (e.value as num?)?.toDouble() ?? 0.0;
```

**Cara kerja:** tambahkan cast eksplisit + fallback, dan (idealnya) test parsing dengan payload cacat/berbeda tipe.

**Kriteria selesai:**
- [ ] 26 lint `avoid_dynamic_calls` hilang atau diturunkan jelas jumlahnya
- [ ] Test parsing ditambah untuk minimal 3 payload edge case (field hilang, tipe salah, null)

---

## PRIORITAS 2 — TINGGI (lindungi fitur inti dengan test)

### S4. Test untuk `features/tarot` (nol test saat ini)
**Kenapa tinggi:** tarot adalah fitur inti + paling sering berubah (3 fix dalam 1 siklus rilis). Tanpa test, regresi tidak terdeteksi.

**Cakupan minimum:**
- [ ] `TarotCard` model — parsing dari JSON `assets/tarot/tarot-merged.json`
- [ ] `TarotLanguageProvider` — switch bahasa ID/EN, fallback kalau key hilang
- [ ] `TarotDrawTypeToggle` — widget test render + tap antar mode
- [ ] Cache key tarot v4 — pastikan `nameId` + `area` benar-benar masuk kunci (bug lama: `cardIndex` selalu 0)
- [ ] Parsing respons sintesis (`parseSynthesisResponse`) — konsisten dengan sisi backend

**Target:** +15 test, coverage `lib/features/tarot/` naik dari ~0% ke ≥40%.

---

### S5. Test untuk `features/ai` (nol test saat ini)
**Kenapa tinggi:** oracle chat adalah USP + memegang kuota Gemini (constraint paling ketat).

**Cakupan minimum:**
- [ ] `oracle_chat_provider` — state transitions: kirim pesan → loading → sukses/gagal
- [ ] Handling `OracleRestException` — pastikan dialog muncul & kuota tidak di-retry
- [ ] `ChatMessage` model — serialisasi/deserialisasi
- [ ] `ChatCacheService` — hit/miss cache, key generation

**Target:** +15 test, coverage `lib/features/ai/` naik dari ~0% ke ≥40%.

---

### S6. Test untuk `features/home` + `features/learning`
**Kenapa tinggi:** dashboard = entry point semua orang; Knowledge Hub baru dan belum ada yang menguji.

**Cakupan minimum:**
- [ ] `SeasonalSynthesisCard` — state A (tanpa tarot) & state B (dengan tarot), cache hit/miss
- [ ] `BaziChartProvider` — global state Ba Zi
- [ ] Knowledge Hub — render 12 Pranata Mangsa + 30 Wuku dari asset JSON
- [ ] `GlosariumSheet` — search + filter domain (28 istilah)

**Target:** +12 test.

---

## PRIORITAS 3 — SEDANG (dokumentasi & kebersihan)

### S7. Perbaiki README yang stale parah
**Bukti inkonsistensi (dalam satu file yang sama!):**
- L173 → `63.1% coverage (667/1057 lines)`
- L327 → `Test coverage: 2.8% → Target 60%` ← kontradiksi
- L316 → `Version: 1.0.0+1` (asli `0.8.0+2`)
- L107, L341–343 → placeholder `yourusername`, `[Your Name]`, `your-email@example.com`
- L335 → `[Specify your license here - MIT, Apache 2.0, etc.]`
- L317 → `Last Audit: July 14, 2026`

**Kerjaan:**
- [ ] Sinkronkan versi + coverage dengan fakta (ambil dari `pubspec.yaml` + `lcov.info`)
- [ ] Hapus blok coverage 2.8% yang kontradiktif
- [ ] Isi identitas repo: `github.com/achilles157/aestral`, maintainer, kontak
- [ ] Tentukan lisensi (butuh keputusan user — lihat "Keputusan User" di bawah)
- [ ] Tambah seksi status roadmap terkini (P1–P7 selesai, v0.8.0, arah v0.9.0)

---

### S8. Selesaikan TODO yang menggantung
- [ ] `lib/features/legal/presentation/consent_onboarding_screen.dart:255` — `// TODO: navigasi ke Privacy Policy screen`

---

### S9. Bersihkan lint kosmetik (~300 item)
Setelah S1–S3, sisa lint mayoritas kosmetik. Urutan dampak:

| Jumlah | Rule | Tindakan |
|---|---|---|
| 192× | `sort_constructors_first` | Otomatis via `dart fix --apply` (aman) |
| 53× | `prefer_const_constructors` | `dart fix --apply` + manual review |
| 43× | `use_null_aware_elements` | `dart fix --apply` |
| 30× | `prefer_single_quotes` | `dart fix --apply` |
| 24× | `curly_braces_in_flow_control_structures` | `dart fix --apply` |
| 13× | `unnecessary_underscores` | `dart fix --apply` |
| 9× | `local_variables_should_be_final` | manual, cepat |
| 7× | `use_key_in_widget_constructors` | manual, cepat |
| 4× | `angle_brackets_will_be_interpreted_as_html` | manual — cek dokumentasi |
| 3× | `prefer_const_literals_to_create_immutables` | `dart fix --apply` |
| 2× | `_field could be final` | manual, cepat |

**Strategi:** jalankan `dart fix --dry-run` dulu, review daftar, lalu `--apply` per-rule dalam commit terpisah supaya mudah di-revert. **Wajib** jalankan test penuh setelah tiap grup.

---

## PRIORITAS 4 — REFACTOR (setelah stabil & teruji)

### S10. Pecah 5 screen terbesar
**Prasyarat: S4–S6 selesai** (jangan pecah file yang belum ada test — tidak bisa verifikasi perilaku).

| Baris | File | Strategi |
|---|---|---|
| 1.161 | `tarot_draw_screen.dart` | pecah jadi `widgets/` per section (draw type, carousel, detail panel sudah ada) |
| 1.073 | `bazi_luck_pillars_widget.dart` | pisah table vs AI synthesis section |
| 1.068 | `astrological_planner_timeline.dart` | pisah timeline item, sheet header, konsultasi AI |
| 1.041 | `weton_compatibility_screen.dart` | pisah form, result, synthesis section |
| 860 | `dashboard_screen.dart` | sudah banyak sub-widget — pindahkan logic ke provider |
| 854 | `oracle_chat_screen.dart` | pisah chat list, input bar, suggestion pills |

**Satu PR = satu file.** Jangan gabung — supaya review & revert gampang.

---

### S11. Evaluasi `bazi_utils.dart` (2.888 baris)
File terbesar di proyek dan **bukan** screen — jadi batas 350 baris secara teknis tidak berlaku, tapi ukurannya tetap jadi masalah (sulit dites per-unit, rawan merge conflict).

**Cakupan isinya perlu dipetakan dulu**, lalu dipecah per domain, mis.:
- `bazi_utils.dart` — entry point/facade
- `bazi_pillars.dart` — kalkulasi 4 pilar
- `bazi_ten_gods.dart` — Ten Gods
- `bazi_luck_pillars.dart` — Da Yun / Luck Pillars
- `bazi_elements.dart` — Wu Xing balance, Day Master strength

**Kerjakan paling akhir** — risiko tertinggi, butuh test yang kuat dulu (sudah ada `bazi_utils_test.dart`, perlu diperluas dulu).

---

## Keputusan User Yang Dibutuhkan

| # | Pertanyaan | Kenapa butuh keputusan |
|---|---|---|
| 1 | **Lisensi proyek apa?** | README masih placeholder. Pilihan: MIT (paling permisif), Apache 2.0 (ada patent grant), atau proprietary |
| 2 | **Email kontak asli?** | Masih `privacy@aestral.app` / `legal@aestral.app` placeholder di dokumen legal |
| 3 | **Batas `lib/` untuk refactor?** | Apakah `core/utils/bazi_utils.dart` (2.888 baris) ikut dipecah, atau dibiarkan? |
| 4 | **Nama maintainer untuk README?** | Sekarang `[Your Name/Team]` |

---

## Urutan Eksekusi & Estimasi

| Fase | Item | Estimasi | PR |
|---|---|---|---|
| **1** | S1 (BuildContext) | 1 sesi | 1 PR `fix/` |
| **1** | S2 (unawaited futures) | 1 sesi | 1 PR `fix/` |
| **1** | S3 (dynamic calls) | 0.5 sesi | 1 PR `fix/` |
| **2** | S4 (test tarot) | 1.5 sesi | 1 PR `test/` |
| **2** | S5 (test ai) | 1.5 sesi | 1 PR `test/` |
| **2** | S6 (test home+learning) | 1 sesi | 1 PR `test/` |
| **3** | S7 (README) | 0.5 sesi | 1 PR `docs/` ← **butuh keputusan user** |
| **3** | S8 (TODO) | 0.5 sesi | gabung PR `fix/` |
| **3** | S9 (lint kosmetik) | 1 sesi | 2–3 PR `style/` |
| **4** | S10 (pecah screen) | 3 sesi | 5 PR `refactor/` |
| **4** | S11 (bazi_utils) | 2 sesi | 1 PR `refactor/` |

**Total: ~14 sesi kerja.** Bisa dipotong — kalau mau cepat, kerjakan Fase 1 + 2 + S7 saja (≈7 sesi) dan sisanya jadi utang terkelola.

---

## Definisi Selesai (v0.9.0)

- [ ] `flutter analyze` → 0 error, 0 warning, **≤50 info**
- [ ] `flutter test --coverage` → semua PASS, coverage **≥70%**
- [ ] `npx vitest run` → semua PASS
- [ ] `dart format .` → clean
- [ ] README akurat (versi, coverage, kontak, lisensi)
- [ ] Semua 6 fitur inti punya minimal smoke test
- [ ] Nol lint `use_build_context_synchronously` + `unawaited_futures`
- [ ] CHANGELOG `[Unreleased]` terisi lengkap
- [ ] `memory/` + `MEMORY.md` diperbarui dengan status baru
- [ ] PR `develop` → `main`, tag `v0.9.0`, auto-deploy Firebase

---

## Catatan Risiko

| Risiko | Mitigasi |
|---|---|
| `dart fix --apply` massal merusak perilaku | Commit per-rule, test penuh setelah tiap grup, revert gampang |
| Refactor tanpa test = regresi tak terdeteksi | S10/S11 **wajib** setelah S4–S6; jangan dibolak-balik |
| Kuota Gemini habis saat test AI | Test pakai fixture/mock, bukan panggilan jaringan nyata |
| Scope creep dari "sekalian ini itu" | Satu PR = satu item. Kalau nemu masalah lain, catat — jangan digabung |
