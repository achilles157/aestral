# 🌟 AESTRAL - Platform Astrologi Nusantara

[![Flutter](https://img.shields.io/badge/Flutter-3.10.3%2B-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Aplikasi astrologi modern** yang menggabungkan kearifan Nusantara (Weton Jawa) dengan sistem astrologi tradisional (Ba Zi/Four Pillars, Tarot) dan diperkuat dengan AI Oracle untuk memberikan insights personal yang mendalam.

---

## ✨ Features

### 🌙 Weton Calculator
Perhitungan weton Jawa lengkap dengan:
- Hari pasaran (Kliwon, Legi, Pahing, Pon, Wage)
- Nilai neptu dan karakteristik personal
- Kompatibilitas pasangan berdasarkan weton
- Pranata mangsa dan perhitungan siklus tradisional

### 🎴 Ba Zi (Four Pillars of Destiny)
Chinese astrology calculator dengan:
- Four Pillars chart (Year, Month, Day, Hour)
- Day Master analysis dan elemental balance
- Luck Pillars (Dasayun) calculation
- AI-powered insights untuk interpretasi personal

### 🔮 Tarot Reading
Tarot spread dengan AI interpretation:
- 3-card spread (Past, Present, Future)
- Context-aware readings berdasarkan profil astrologi
- Integrasi dengan weton untuk insights yang lebih dalam

### 🤖 AI Oracle Chat
Conversational astrology guidance:
- Personalized advice berdasarkan birth chart
- Multi-session memory untuk continuity
- Context-aware dengan weton, Ba Zi, dan tarot history

### 📅 Astrological Planner
Calendar dengan perhitungan hari baik/buruk:
- Daily weton insights
- Auspicious dates untuk aktivitas penting
- Pranata mangsa seasonal guidance

---

## 🏗️ Architecture

### Tech Stack
- **Frontend:** Flutter 3.10.3+ (iOS, Android, Web)
- **State Management:** Riverpod 3.3+
- **Backend:** Firebase (Auth, Firestore, Crashlytics, Analytics)
- **API:** Cloudflare Workers (zero-cost serverless)
- **AI:** Firebase AI Logic (Gemini API)

### Project Structure
```
lib/
├── core/                   # Shared resources
│   ├── models/            # Data models (BirthProfile, etc.)
│   ├── providers/         # Global providers (auth, profile)
│   ├── services/          # API, analytics, city service
│   ├── theme/             # AppTheme dengan dark theme
│   ├── utils/             # Utilities (weton, bazi, file saver)
│   └── widgets/           # Reusable widgets (glass card, loader)
│
└── features/              # Feature modules
    ├── ai/                # Oracle chat AI
    ├── auth/              # Authentication (Firebase + Guest mode)
    ├── bazi/              # Ba Zi calculator
    ├── hari_baik/         # Auspicious days
    ├── history/           # User history
    ├── home/              # Dashboard & main shell
    ├── profiles/          # User profiles
    ├── tarot/             # Tarot reading
    └── weton/             # Weton calculator

Each feature follows clean architecture:
    ├── data/              # Repositories, data sources
    ├── domain/            # Business logic, entities
    ├── presentation/      # Screens, widgets
    ├── providers/         # Riverpod state management
    └── services/          # Feature-specific services
```

### Design Principles
- **Feature-based modular architecture** - Easy to scale dan maintain
- **Offline-first design** - Guest mode tanpa internet, auto-sync saat login
- **Zero-budget compliance** - Firebase & Cloudflare free tier
- **Single source of truth** - Centralized state management dengan Riverpod
- **Glassmorphic UI** - Modern dark theme dengan blur effects

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK:** 3.10.3 or higher
- **Dart SDK:** 3.10.3 or higher (included dengan Flutter)
- **IDE:** VS Code, Android Studio, atau IntelliJ IDEA
- **Firebase project** (untuk production deployment)

### Installation

1. **Clone repository:**
   ```bash
   git clone https://github.com/yourusername/aestral.git
   cd aestral
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (untuk production):
   
   a. Buat Firebase project di [Firebase Console](https://console.firebase.google.com)
   
   b. Enable services:
      - Authentication (Google Sign-In)
      - Cloud Firestore
      - Crashlytics
      - Analytics
   
   c. Download config files:
      - Android: `google-services.json` → `android/app/`
      - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   
   d. Run FlutterFire CLI:
      ```bash
      flutterfire configure
      ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Guest Mode (No Firebase)
App mendukung **guest mode** untuk development atau offline usage:
- Tidak perlu Firebase configuration
- Data disimpan lokal dengan SharedPreferences
- Auto-migrate ke Firestore saat user login dengan Google

---

## 🧪 Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run with coverage report
flutter test --coverage

# View coverage in HTML (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Static Analysis
```bash
# Run Flutter analyzer
flutter analyze

# Check for outdated dependencies
flutter pub outdated
```

### Current Test Coverage
⚠️ **Status:** 2.8% coverage (CRITICAL - dalam perbaikan)

**Target:** 60% coverage dalam 8 weeks

**Priority tests:**
- `test/core/utils/weton_utils_test.dart` - Weton calculations
- `test/core/utils/bazi_utils_test.dart` - Ba Zi calculations
- `test/features/auth/auth_service_test.dart` - Auth flows
- `test/core/providers/birth_profile_provider_test.dart` - State management

---

## 📱 Build & Deployment

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (untuk Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Simulator build
flutter build ios --debug --simulator

# Release build (memerlukan Apple Developer account)
flutter build ios --release
```

### Web
```bash
# Build web app
flutter build web --release

# Deploy ke Firebase Hosting (jika configured)
firebase deploy --only hosting
```

---

## 🔒 Security

### Firestore Security Rules
⚠️ **PENTING:** Verify Firestore security rules di Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // User hanya bisa akses data mereka sendiri
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
    
    // Block all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Export rules ke repository:
```bash
firebase firestore:rules > firestore.rules
git add firestore.rules
git commit -m "chore: add Firestore security rules"
```

---

## 🤝 Contributing

### Development Workflow
1. Fork repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes dan ensure tests pass: `flutter test`
4. Run analyzer: `flutter analyze`
5. Commit changes: `git commit -m 'feat: add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open Pull Request

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Gunakan `flutter format .` sebelum commit
- Maintain zero warnings dari `flutter analyze`
- Add tests untuk new features

### Commit Convention
Gunakan [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style/formatting
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

---

## 📚 Documentation

- **Architecture Decision Records:** `docs/adr/` (coming soon)
- **API Documentation:** Run `dart doc` untuk generate dartdoc
- **Audit Report:** `AUDIT_SUMMARY.md` - Security & quality audit findings

---

## 🐛 Troubleshooting

### Firebase initialization failed
**Cause:** Firebase configuration files missing atau invalid.

**Solution:**
1. Verify `google-services.json` (Android) dan `GoogleService-Info.plist` (iOS) exist
2. Run `flutterfire configure` untuk regenerate `firebase_options.dart`
3. Atau gunakan guest mode untuk development

### Google Sign-In not working
**Cause:** OAuth client ID tidak configured.

**Solution:**
1. Android: Ensure `google-services.json` is up-to-date
2. iOS: Add URL schemes di `Info.plist` (FlutterFire handles this)
3. Web: Configure authorized domains di Firebase Console

### Build errors after `flutter pub get`
**Cause:** Flutter/Dart version mismatch.

**Solution:**
```bash
flutter clean
flutter pub get
flutter pub outdated  # Check for incompatibilities
flutter doctor -v     # Verify Flutter installation
```

---

## 📊 Project Status

**Version:** 1.0.0+1  
**Last Audit:** July 14, 2026  
**Overall Score:** 7.2/10 🟡 Good with Critical Gaps

### Strengths ✅
- Solid feature-based architecture (9/10)
- Modern state management dengan Riverpod (8.5/10)
- Zero-budget compliance (9/10)
- Clean code quality - zero analyzer warnings (9/10)

### In Progress ⚠️
- **Test coverage:** 2.8% → Target 60% (Week 1-8)
- **Firestore security audit:** Verification ongoing
- **Performance optimization:** BackdropFilter audit ongoing

---

## 📄 License

[Specify your license here - MIT, Apache 2.0, etc.]

---

## 👥 Team & Contact

**Maintainer:** [Your Name/Team]  
**Email:** [your-email@example.com]  
**Issues:** [GitHub Issues](https://github.com/yourusername/aestral/issues)

---

## 🙏 Acknowledgments

- **Weton calculations** berdasarkan tradisi Jawa
- **Ba Zi system** dari Chinese astrology traditions
- **AI powered by** Firebase AI Logic (Gemini API)
- **Icons & fonts** dari Google Fonts & Material Icons

---

**Built with ❤️ using Flutter**
