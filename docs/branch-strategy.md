# Branch Strategy & Git Workflow — Aestral

> Status: Aktif sejak 2026-08-06
> Prinsip: **2 branch permanen + branch short-lived**. Bukan banyak branch permanen yang ribet di-maintain — tapi banyak branch sementara yang pendek umurnya dan dihapus setelah merge.

---

## 1. Branch Permanen (hanya 2)

| Branch | Peran | Proteksi | Auto-deploy |
|---|---|---|---|
| `main` | **Production** — hanya berisi kode yang sudah rilis | Wajib PR + review, no direct push | ✅ Firebase Hosting live |
| `develop` | **Integration** — tempat semua fitur digabung & diuji | Wajib PR, no direct push | ❌ (tidak deploy) |

### Alur deploy

```
feature/* ──PR──▶ develop ──PR (release)──▶ main ──push──▶ Firebase live
                  │  ▲                              │
                  │  └── CI: format+analyze+test    └── CI lagi + deploy
                  └── preview PR (URL unik)
```

**Kenapa develop tidak auto-deploy?** Karena `main` adalah satu-satunya sumber kebenaran untuk production. `develop` bisa berisi kode yang masih diuji — kalau dia deploy sendiri, production bisa rusak tanpa disadari.

---

## 2. Branch Short-Lived (dibuat per kerjaan, dihapus setelah merge)

Prefix branch mengikuti **Conventional Commits type** — gampang ditebak isinya:

| Prefix | Untuk apa | Contoh |
|---|---|---|
| `feature/*` | Fitur baru | `feature/tarot-tematik` |
| `fix/*` | Bug fix | `fix/weton-null-crash` |
| `refactor/*` | Perombakan kode tanpa ubah perilaku | `refactor/api-service-cache` |
| `perf/*` | Optimasi performa | `perf/skeleton-loading` |
| `docs/*` | Dokumentasi | `docs/branch-strategy` |
| `test/*` | Menambah/memperbaiki test | `test/bazi-coverage` |
| `ci/*` | Workflow / CI-CD | `ci/github-actions` |
| `chore/*` | Maintenance lain | `chore/update-deps` |
| `style/*` | Format, lint, styling | `style/dart-format` |

### Aturan main

1. Branch dari `develop` (bukan dari `main`).
2. Satu branch = satu fokus. Kalau butuh 2 hal → 2 branch.
3. PR ke `develop`, judul PR ikut Conventional Commits.
4. CI harus hijau (format, analyze, test, build) sebelum merge.
5. **Hapus branch setelah merge** — GitHub otomatis tawarkan tombol "Delete branch".

---

## 3. Alur Rilis (main)

| Langkah | Aksi |
|---|---|
| 1 | Pastikan `develop` stabil (CI hijau, semua fitur selesai) |
| 2 | Buat branch `release/vX.Y.Z` dari `develop` (opsional, untuk freeze) |
| 3 | PR `release/vX.Y.Z` → `main`, review final |
| 4 | Merge ke `main` → **auto-deploy Firebase live** |
| 5 | Buat tag `vX.Y.Z` di `main` → workflow `release.yml` membuat GitHub Release + changelog |
| 6 | Merge balik `main` → `develop` jika ada hotfix langsung di main |

### Hotfix darurat (production rusak)

```
fix/hotfix-xxx ──PR──▶ main (langsung, diizinkan) ──deploy──▶ live
     │
     └── merge balik ke develop juga (jangan lupa!)
```

Hotfix boleh bypass `develop` karena darurat, tapi **wajib di-cherry-pick balik ke develop** agar tidak tertinggal.

---

## 4. CI/CD Pipeline (file di `.github/workflows/`)

| Workflow | Trigger | Fungsi |
|---|---|---|
| `ci.yml` | Push ke develop/main, PR ke develop/main | Format check + `flutter analyze` + `flutter test --coverage` (threshold 40%) + `flutter build web` |
| `firebase-preview.yml` | PR ke develop/main | Deploy preview channel per-PR (URL unik untuk review) |
| `firebase-deploy.yml` | Push ke `main` + manual dispatch | Build web + deploy ke Firebase Hosting **live** |
| `commit-check.yml` | PR | Validasi semua commit pakai Conventional Commits |
| `release.yml` | Tag `v*.*.*` | Buat GitHub Release + extract changelog |

### Aturan CI

1. Coverage: **minimum 18%** (hard fail), target **40%** (warning), aspirasi 60% (untuk rilis).
2. `flutter analyze` hanya fail pada `error`/`warning` — info-level lint tidak memblokir.
3. `dart format --set-exit-if-changed .` — semua file harus rapi sebelum merge.
4. Preview PR otomatis dibuat untuk tiap PR — review UI tanpa deploy manual.

---

## 5. Kenapa Skema Ini (bukan trunk-only / bukan banyak branch permanen)

| Skema | Cocok untuk | Masalah di Aestral |
|---|---|---|
| **Trunk-based** (1 branch) | Tim besar + deploy tiap jam | Aestral solo/dev kecil — butuh ruang uji sebelum production |
| **Banyak permanen** (main/dev/staging/qa/uat) | Enterprise multi-env | Mahal maintain, 5 branch permanen = 5x merge overhead |
| **2 permanen + short-lived** ✅ | Solo / tim kecil, zero-budget | Cukup 1 env production + 1 integration, sisanya transien |

**Intinya:** branch permanen itu mahal (harus selalu sinkron). Yang "mikro dan mudah di-maintain" bukan berarti banyak branch permanen, tapi banyak **branch sementara yang pendek umurnya** + prefix jelas + auto-delete setelah merge.
