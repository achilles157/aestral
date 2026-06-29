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
- **Static Kamus Data**: Keep tarot definitions and weton dictionaries in static JSON files in assets or dedicated read-only Firestore collections. Minimize reads by checking local caches first.

## Cloudflare Workers Development
- **Deployment**: Workers must be implemented in TypeScript. Use wrangler for local testing and deployment.
- **Security**: All API requests to Cloudflare Workers must pass the Firebase Auth JWT in the `Authorization` header (`Bearer <token>`). The Worker must verify the token's signature, issuer (`https://securetoken.google.com/<project-id>`), and audience (`<project-id>`) before completing calculations.
- **Computation**: Astrology calculations (Ba Zi, solar position, etc.) should use simple mathematical approximations or lightweight npm packages. Avoid heavy libraries that push memory/execution time close to free tier CPU limits (50ms execution time).

## Flutter Layout & Asset Standards
- **Viewport Resilience**: All main screens must use `SingleChildScrollView` wrapped in a `LayoutBuilder` combined with `ConstrainedBox` and `IntrinsicHeight` if they contain `Spacer` or `Expanded` widgets.
- **Asset Registration**: Any new asset file must be added to the physical directory (`assets/images/` or `assets/data/`) and registered in `pubspec.yaml` under `flutter.assets`. Run a verification check using `list_dir` to ensure the file exists.
