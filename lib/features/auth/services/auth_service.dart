import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isMock;

  UserSession({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.isMock,
  });
}

class AuthNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() {
    _loadSession();
    if (isFirebaseAvailable && !kIsWeb) {
      try {
        GoogleSignIn.instance.initialize();
      } catch (e) {
        debugPrint("Error initializing GoogleSignIn: $e");
      }
    }
    return null;
  }

  bool get isFirebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadSession() async {
    try {
      if (isFirebaseAvailable) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          state = UserSession(
            uid: currentUser.uid,
            displayName: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            photoUrl: currentUser.photoURL,
            isMock: false,
          );
          return;
        }
      }

      // Fallback: check shared preferences for mock user
      final prefs = await SharedPreferences.getInstance();
      final mockUid = prefs.getString('mock_user_uid');
      if (mockUid != null) {
        state = UserSession(
          uid: mockUid,
          displayName: prefs.getString('mock_user_name') ?? 'Tamu Offline',
          email: prefs.getString('mock_user_email') ?? 'guest@aestral.local',
          isMock: true,
        );
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!isFirebaseAvailable) {
      return false;
    }
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user != null) {
          state = UserSession(
            uid: user.uid,
            displayName: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            isMock: false,
          );
          return true;
        }
        return false;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        state = UserSession(
          uid: user.uid,
          displayName: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          isMock: false,
        );
        return true;
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    }
    return false;
  }

  Future<void> signInAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    const uid = 'guest_user_123';
    await prefs.setString('mock_user_uid', uid);
    await prefs.setString('mock_user_name', 'Tamu Offline');
    await prefs.setString('mock_user_email', 'guest@aestral.local');

    state = UserSession(
      uid: uid,
      displayName: 'Tamu Offline',
      email: 'guest@aestral.local',
      isMock: true,
    );
  }

  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint("Error signing out from Firebase: $e");
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mock_user_uid');
    await prefs.remove('mock_user_name');
    await prefs.remove('mock_user_email');
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserSession?>(() {
  return AuthNotifier();
});
