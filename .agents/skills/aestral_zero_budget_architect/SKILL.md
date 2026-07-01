---
name: aestral-zero-budget-architect
description: Guides development, optimization, and auditing of features under the zero-budget, high-performance architecture rules for Aestral.
---

# Aestral Zero-Budget Architect Skill

Use this skill when you are designing, coding, debugging, or reviewing features for the Aestral app, particularly when modifying Firestore schemas, implementing Cloudflare Workers, handling Javanese Weton/Ba Zi calculations, or designing layout widgets.

## Firestore Optimization (NoSQL Flattening)
- **Rule**: Do not create nested maps/arrays inside documents that grow over time. Keep user documents flat.
- **Reference Pattern**:
  - `users/{uid}`: Keep basic profile, birthdate, birth location.
  - `users/{uid}/tarot_history/{historyId}`: A subcollection for tarot draws.
  - `users/{uid}/weton_history/{historyId}`: A subcollection for weton logs.
- **Static Kamus Data**: All static dictionaries (`tarot-merged.json`, `kamus-weton.json`, `sisabagi.json`, `wuku.json`, `bazi-pillars.json`) are bundled locally under `assets/tarot/` and `assets/weton/` or `assets/data/` to avoid network latencies and minimize Firestore read costs.

## Cloudflare Workers Development & Weighted RNG
- **Deployment**: Workers must be implemented in TypeScript. Use wrangler for local testing and deployment.
- **Security**: All API requests to Cloudflare Workers must pass the Firebase Auth JWT in the `Authorization` header (`Bearer <token>`). The Worker must verify the token's signature, issuer (`https://securetoken.google.com/<project-id>`), and audience (`<project-id>`) before completing calculations.
- **Weighted RNG**:
  - Map Tarot Suits to elements: Cups = Water, Wands = Fire, Pentacles = Earth, Swords = Metal, Major Arcana = Neutral.
  - For Tarot draws, apply Compensation (deficient element weight +15%) and Resonance (dominant element weight +10%) based on current Wuku (weekly) or daily Weton.
- **Computation**: Astrology calculations (Ba Zi, solar position, etc.) should use simple mathematical approximations or lightweight npm packages. Avoid heavy libraries that push memory/execution time close to free tier CPU limits (50ms execution time).

## Flutter Layout, UI & Asset Standards
- **Viewport Resilience**: All main screens must use `SingleChildScrollView` wrapped in a `LayoutBuilder` combined with `ConstrainedBox` and `IntrinsicHeight` if they contain `Spacer` or `Expanded` widgets.
- **Weton & Tarot UI Styling**:
  - Hide technical metadata (Neptu numbers, Wuku name, Pancasuda details) inside an `ExpansionTile` labeled **"Lihat Detail Perhitungan Teknis"**.
  - Focus the primary view on 3 aesthetic, modern cards representing: **Karier & Finansial**, **Asmara & Hubungan**, and **Sisi Gelap / Peringatan**.
  - Use growth-oriented, psychological framing for traditional warnings (e.g., Loro/Sakit -> health/stress awareness, Pati/Mati -> ego death/releasing toxic habits).
- **Asset Registration**: Any new asset file must be added to the physical directory (`assets/`) and registered in `pubspec.yaml` under `flutter.assets`. Run a verification check using `list_dir` to ensure the file exists.
