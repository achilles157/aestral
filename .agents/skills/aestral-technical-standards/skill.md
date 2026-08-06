# Aestral Technical Standards — Coding, Testing & Style

Standar teknis yang harus diikuti semua agent yang menulis kode di proyek Aestral.

---

## Dart / Flutter Standards

### Naming Conventions
- **File:** `snake_case.dart`
- **Class/Enum:** `PascalCase`
- **Variable/Function:** `camelCase`
- **Constant:** `camelCase`
- **Private members:** prefix `_`

### Project Structure (Feature-Based)
```
lib/features/<nama_fitur>/
  data/           → Repository implementations
  domain/         → Entities, business logic interfaces
  presentation/   → Screens and widgets
    widgets/      → Sub-widgets (jika screen >350 baris)
  providers/      → Riverpod providers
  services/       → Feature-specific services
```

### Widget Size
- Screen file **maksimal 350 baris** — pecah ke `widgets/`
- Widget file **maksimal 250 baris**
- Gunakan `const` constructor di mana pun memungkinkan
- Tidak boleh ada business logic di `build()`

### Riverpod Rules
- `setState` HANYA untuk UI-local state
- Business logic di `StateNotifier` / `AsyncNotifier`
- `ref.watch()` untuk baca, `ref.read()` untuk aksi
- Provider selalu di top-level, bukan di dalam `build()`

### UI Rules
- Semua teks user-facing: Bahasa Indonesia
- Gunakan `debugPrint()` bukan `print()`
- `withValues(alpha: 0.x)` bukan `withOpacity(0.x)`
- BackdropFilter hanya jika benar-benar butuh

---

## TypeScript (Cloudflare Workers) Standards

- **Selalu typed** — jangan pakai `any`
- Interface untuk semua request body
- Semua input dari client: **validasi + sanitasi**
- Gunakan `sanitizeCtx()` untuk string ke prompt AI
- `requireAuth()` untuk endpoint yang butuh autentikasi
- Guest token: batasi fitur

### Router Pattern
```typescript
async function handleNamaFitur(request: Request, env: Env): Promise<Response> {
  const authResult = await requireAuth(request.headers.get('Authorization'), env);
  if (authResult instanceof Response) return authResult;

  const clientIp = request.headers.get('CF-Connecting-IP') ?? 'cf-no-ip';
  if (await isRateLimited(clientIp, LIMIT, WINDOW, env.RATE_LIMIT_KV)) {
    // return 429
  }
  // Parse body → Execute logic → Return json
}
```

---

## Testing Standards

- **Target coverage:** ≥60% (current: 63.1% — jaga jangan turun)
- Unit test untuk semua utility functions
- Widget test untuk screen utama
- Backend: vitest — test semua endpoint + edge cases

### Test Naming
```dart
test('ClassName methodName behaviorWhenCondition', () { ... });
```

---

## Performance Rules
- BackdropFilter: cek `MediaQuery.disableAnimations`
- Gambar: gunakan `cacheWidth`/`cacheHeight`
- JSON assets: load sekali di startup
- API response: selalu caching via `CacheService`

---

## Common Mistakes
1. Nambah state di `build()` → provider harus top-level
2. Lupa `const` constructor
3. Mixed language Inggris-Indonesia
4. Hardcode cache key → pakai `CacheService.generateKey()`
5. Tidak handle guest mode
6. Backend: lupa sanitasi input prompt
7. Backend: lupa return type `Promise<Response>`
