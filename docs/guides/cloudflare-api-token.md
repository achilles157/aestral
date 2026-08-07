# Panduan Cloudflare API Token — Auto-Deploy Worker Aestral

> Revisi: 2026-08-07 · Berlaku untuk repo `achilles157/aestral`

## Kenapa panduan ini ada

Workflow `.github/workflows/deploy-worker.yml` butuh **2 GitHub secrets** yang belum terpasang:

| Secret | Isi |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Token API Cloudflare (bukan password akun) |
| `CLOUDFLARE_ACCOUNT_ID` | ID akun Cloudflare (32 karakter hex) |

Tanpa keduanya, workflow gagal: `In a non-interactive environment, it's necessary to set a CLOUDFLARE_API_TOKEN environment variable`.

Token Cloudflare memang punya banyak spesifikasi (permission, scope akun/zone, TTL). Panduan ini memilihkan konfigurasi **paling minimal & aman** untuk deploy Worker saja.

---

## 0. API Token vs API Key

| Jenis | Kegunaan | Untuk kita? |
|---|---|---|
| **API Token** (recommended) | Token per-tugas: permission, scope, dan masa berlaku bisa dibatasi | ✅ **Ini yang dipakai** |
| Global API Key | "Kunci utama" akun — akses penuh | ❌ JANGAN — terlalu berbahaya, tak bisa di-scope |
| Origin CA Key / Scoped Keys | Kasus khusus (SSL, dll) | ❌ Tidak relevan |

> ⚠️ Global API Key setara password akun. Kalau bocor ke log CI, akun Cloudflare bisa dikuasai orang lain. API Token hanya bisa mengelola Worker dan bisa dicabut kapan saja.

---

## 1. Ambil Account ID (±1 menit)

1. Login ke <https://dash.cloudflare.com>
2. Pojok kanan bawah sidebar → kotak **"Account ID"** (32 hex, contoh `af72b75133ce4041990a3b04f08ed3e9`)
   - Alternatif: URL dashboard berbentuk `dash.cloudflare.com/<ACCOUNT_ID>/...`
3. Simpan — dipakai untuk secret `CLOUDFLARE_ACCOUNT_ID`

---

## 2. Buat API Token (±5 menit)

1. Buka <https://dash.cloudflare.com/profile/api-tokens> (My Profile → API Tokens)
2. Klik **Create Token**
3. Pilih **"Create Custom Token"** (paling bawah) → **Get started**

### 2a. Isi form — spesifikasi persis

| Field | Isi | Catatan |
|---|---|---|
| Token name | `aestral-worker-deploy` | Bebas |
| Permissions → Account | `Workers Scripts` → `Edit` | **WAJIB** — upload script |
| Permissions → Account | `Account Settings` → `Read` | **Disarankan** — wrangler baca info akun |
| Permissions → Zone | `Zone` → `Read` | Opsional — hanya untuk custom domain; `*.workers.dev` murni tidak wajib |

> 🎯 Prinsip minimal privilege: jangan tambah permission lain. Token hanya boleh: edit Workers Scripts + baca Account Settings.

### 2b. Account Resources

- **Include** → pilih nama akun Cloudflare-mu (biasanya 1).

### 2c. Zone Resources

- Pilih **Include → All zones** (paling sederhana), atau kosongkan/selektif kalau hanya `*.workers.dev`.

### 2d. IP Filtering & TTL

| Field | Saran | Kenapa |
|---|---|---|
| Client IP Address Filtering | Kosongkan (semua IP) | GitHub Actions pakai banyak IP yang berubah |
| TTL | Start: now · End: +1 tahun | Lapisan keamanan ekstra; ingat untuk rotasi |

4. **Continue to summary** → periksa → **Create Token**

> 🔴 **PENTING:** token ditampilkan **hanya sekali** (kotak biru). Salin & simpan segera. Halaman ditutup = token tidak bisa dilihat lagi.

---

## 3. Verifikasi lokal (disarankan, ±1 menit)

```powershell
# Windows PowerShell
$env:CLOUDFLARE_API_TOKEN = "TOKEN_YANG_BARU"
npx wrangler whoami
```

Muncul nama email & ID akun → token valid. Error permission → cek ulang Langkah 2a.

---

## 4. Pasang secrets di GitHub (±2 menit)

1. Repo `achilles157/aestral` → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**, buat dua:

| Name (PERSIS) | Value |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Token dari Langkah 2 |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID dari Langkah 1 |

3. Tab **Actions** → workflow **Deploy Worker (Cloudflare)** → **Run workflow** (branch `main`)
4. Tunggu hijau. Log deploy akan menampilkan `Deployed ... workers.dev`

---

## 5. Troubleshooting

| Error | Penyebab | Solusi |
|---|---|---|
| `...necessary to set a CLOUDFLARE_API_TOKEN...` | Secret belum ada / nama salah | Cek ejaan nama secret (persis, huruf besar) |
| `Invalid request headers (9109)` / `Authentication error` | Token salah salin / kedaluwarsa | Buat token baru; `npx wrangler whoami` dulu |
| `Authorization failure...` | Permission kurang (Workers Scripts Edit hilang / scope salah) | Ulangi 2a; pastikan Include akun benar |
| Worker lama yang jalan | — | `wrangler deployments list`; rollback via `deploy --version-id` |
| Workflow tak muncul di Actions | Trigger path-specific | Pakai **Run workflow** manual (workflow_dispatch) |

---

## 6. Keamanan & pemeliharaan

- **Rotasi** token setiap ~6–12 bulan (hapus yang lama di halaman API Tokens).
- **Jangan commit token** — hanya di GitHub Secrets & `.dev.vars` lokal (sudah di `.gitignore`).
- **Cabut cepat** — curiga bocor? Halaman API Tokens → **Roll** atau **Delete** seketika.
- Cloudflare mencatat aktivitas API di audit log.

---

## ✅ Kriteria sukses

Workflow **Deploy Worker (Cloudflare)** hijau, dan `https://aestral-backend.aestral-backend.workers.dev/api/health` merespons `200` setelah setiap merge ke `main`.

---

*Workflow terkait: `.github/workflows/deploy-worker.yml` · Backend: `aestral-backend/` (Wrangler 4.105+, Node 22)*
