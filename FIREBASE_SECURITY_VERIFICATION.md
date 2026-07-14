# 🔒 Firebase Security Verification Guide

**Purpose:** Memastikan Firestore Security Rules properly configured untuk melindungi user data.

**Status:** 🔴 CRITICAL - MUST BE VERIFIED BEFORE PRODUCTION

---

## 📋 Security Requirements Checklist

- [ ] **Rule 1:** User hanya bisa read/write data mereka sendiri (`/users/{userId}`)
- [ ] **Rule 2:** Guest users (unauthenticated) tidak bisa akses Firestore
- [ ] **Rule 3:** Subcollections (history, sessions, cache) juga protected per-user
- [ ] **Rule 4:** All other paths explicitly blocked (deny by default)
- [ ] **Rule 5:** Data validation rules applied (isValidUserData)

---

## 🚀 Quick Verification (5 Minutes)

### Step 1: Login ke Firebase Console
1. Buka https://console.firebase.google.com
2. Select project "Aestral" (atau nama project Anda)
3. Navigate: **Firestore Database** → **Rules** tab

### Step 2: Compare Rules
**Expected rules:** See `firestore.rules` di repository root.

**Key sections to verify:**
```javascript
// ✅ User data isolation
match /users/{userId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId) && isValidUserData();
  allow update: if isOwner(userId) && isValidUserData();
  allow delete: if isOwner(userId);
}

// ✅ Block all other access
match /{document=**} {
  allow read, write: if false;
}
```

### Step 3: Export Current Rules
```bash
# Export rules dari Firebase
firebase firestore:rules > firestore.rules.current

# Compare dengan expected rules
diff firestore.rules firestore.rules.current

# Jika ada perbedaan, deploy correct rules:
firebase deploy --only firestore:rules
```

---

## 🧪 Testing Security Rules

### Option 1: Firebase Emulator (RECOMMENDED)

**Setup:**
```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize emulator
firebase init emulators
# Select: Firestore emulator
# Port: 8080 (default)

# Start emulator
firebase emulators:start --only firestore
```

**Test dengan Emulator:**
```dart
// lib/main.dart - Add emulator connection for debug
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

**Run app dengan emulator:**
```bash
flutter run
# App will connect to local Firestore emulator
# Check emulator UI at: http://localhost:4000
```

### Option 2: Firebase Console Rules Playground

1. Buka Firebase Console → Firestore → Rules tab
2. Click **"Rules Playground"** button
3. Test scenarios:

**Test Case 1: Authenticated user reads own data**
```
Location: /users/user123
Type: get
Auth: Authenticated (uid: user123)
Expected: ✅ ALLOW
```

**Test Case 2: Authenticated user reads other user's data**
```
Location: /users/user999
Type: get
Auth: Authenticated (uid: user123)
Expected: ❌ DENY
```

**Test Case 3: Unauthenticated read**
```
Location: /users/user123
Type: get
Auth: Unauthenticated
Expected: ❌ DENY
```

**Test Case 4: Write own data with valid structure**
```
Location: /users/user123
Type: set
Auth: Authenticated (uid: user123)
Data: { biometric_anchor: { dob_utc_ms: 631152000000 } }
Expected: ✅ ALLOW
```

**Test Case 5: Write own data with INVALID structure**
```
Location: /users/user123
Type: set
Auth: Authenticated (uid: user123)
Data: { random_field: "value" }
Expected: ❌ DENY (missing biometric_anchor)
```

---

## 🔍 Security Audit Checklist

### Critical Checks

#### ✅ 1. User Data Isolation
```bash
# Test: User A tidak bisa akses data User B
# Login sebagai User A (uid: userA)
# Try to read /users/userB
# Expected: PERMISSION_DENIED error
```

**Flutter test code:**
```dart
test('User cannot access other user data', () async {
  // Setup: Login as userA
  await signInAsUser('userA');
  
  // Attempt to read userB's data
  final result = await FirebaseFirestore.instance
      .collection('users')
      .doc('userB')
      .get();
  
  // Expected: throws permission denied
  expect(result.exists, false);
});
```

#### ✅ 2. Guest Mode Isolation
```bash
# Test: Unauthenticated users tidak bisa akses Firestore
# Logout dari Firebase Auth
# Try to read any /users/* document
# Expected: PERMISSION_DENIED error
```

**Manual test:**
1. Launch app
2. Select "Lanjutkan sebagai Tamu"
3. Navigate through app (data should be local only)
4. Check Firestore console: NO documents created
5. Expected: App works dengan SharedPreferences, zero Firestore access

#### ✅ 3. Subcollections Protected
```bash
# Test: Subcollections inherit parent protection
# Login as userA
# Try to read /users/userB/tarot_history/doc1
# Expected: PERMISSION_DENIED error
```

#### ✅ 4. Wildcard Paths Blocked
```bash
# Test: Any unlisted collection/document denied
# Try to read /random_collection/random_doc
# Expected: PERMISSION_DENIED error
```

#### ✅ 5. Write Validation
```bash
# Test: Invalid data structure rejected
# Login as userA
# Try to write { invalid: "data" } to /users/userA
# Expected: PERMISSION_DENIED (validation failed)
```

---

## 🚨 Common Security Issues & Fixes

### Issue 1: Rules allow public read/write
**Symptoms:** Any user can read any data.

**Bad rule (DON'T USE):**
```javascript
match /{document=**} {
  allow read, write: if true; // ❌ NEVER DO THIS
}
```

**Fix:** Use uid-based ownership check (see `firestore.rules`).

---

### Issue 2: Test mode rules still active
**Symptoms:** Console shows warning "Your rules are set to public".

**Bad rule (generated by Firebase for testing):**
```javascript
allow read, write: if request.time < timestamp.date(2026, 8, 1); // ❌ TEMPORARY
```

**Fix:** Replace with production rules immediately.

---

### Issue 3: Missing subcollection rules
**Symptoms:** User can access main document but not subcollections.

**Incomplete rule:**
```javascript
match /users/{userId} {
  allow read, write: if isOwner(userId);
  // ❌ Missing subcollection rules
}
```

**Fix:** Add explicit subcollection matches (see `firestore.rules`).

---

## 📝 Deployment Checklist

Before deploying to production:

- [ ] Rules verified in Firebase Console
- [ ] Rules tested with Emulator or Playground
- [ ] All 5 security checks passed
- [ ] Rules exported to repository: `firebase firestore:rules > firestore.rules`
- [ ] Rules committed to git: `git add firestore.rules && git commit -m "chore: add Firestore security rules"`
- [ ] Deployed to Firebase: `firebase deploy --only firestore:rules`
- [ ] Production test: Login and verify app works
- [ ] Production test: Logout and verify Firestore access denied

---

## 🔄 Ongoing Monitoring

### Firebase Console Monitoring
1. Navigate: **Firestore Database** → **Usage** tab
2. Monitor for:
   - Unexpected read/write spikes (potential abuse)
   - Permission denied errors (expected for unauthorized access)

### Set up Alerts
```bash
# Firebase Console → Alerts & Reporting
# Create alert for:
# - Daily read count > threshold
# - Daily write count > threshold
# - Permission denied rate > 10%
```

### Regular Security Audits
- **Weekly:** Review Firestore usage metrics
- **Monthly:** Re-run security test suite
- **Quarterly:** Full security audit with penetration testing

---

## 📚 Resources

- **Firestore Security Rules Docs:** https://firebase.google.com/docs/firestore/security/get-started
- **Rules Playground:** Firebase Console → Firestore → Rules → Playground
- **Firebase Emulator:** https://firebase.google.com/docs/emulator-suite
- **Security Best Practices:** https://firebase.google.com/docs/rules/best-practices

---

## 🆘 Need Help?

**If rules don't work:**
1. Check Firebase Console → Firestore → Rules tab for syntax errors
2. Use Rules Playground to debug specific cases
3. Check app logs for `PERMISSION_DENIED` errors
4. Verify `firebase_options.dart` configured correctly

**Contact:**
- Firebase Support: https://firebase.google.com/support
- Stack Overflow: https://stackoverflow.com/questions/tagged/firebase
- Project Issues: [GitHub Issues](https://github.com/yourusername/aes
