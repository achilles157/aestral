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
        if (kIsWeb) {
          try {
            final UserCredential userCredential = await FirebaseAuth.instance
                .getRedirectResult();
            if (!ref.mounted) return;
            final user = userCredential.user;
            if (user != null) {
              state = UserSession(
                uid: user.uid,
                displayName: user.displayName ?? 'User',
                email: user.email ?? '',
                photoUrl: user.photoURL,
                isMock: false,
              );
              ref.read(authInitializingProvider.notifier).complete();
              return;
            }
          } catch (e) {
            debugPrint("Error loading redirect session: $e");
          }
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (!ref.mounted) return;
          state = UserSession(
            uid: currentUser.uid,
            displayName: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            photoUrl: currentUser.photoURL,
            isMock: false,
          );
          ref.read(authInitializingProvider.notifier).complete();
          return;
        }
      }

      // Fallback: check shared preferences for mock user
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
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
    } finally {
      if (ref.mounted) {
        ref.read(authInitializingProvider.notifier).complete();
      }
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!isFirebaseAvailable) {
      return false;
    }
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        try {
          final UserCredential userCredential = await FirebaseAuth.instance
              .signInWithPopup(googleProvider);
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
        } catch (popupError) {
          debugPrint(
            "Popup sign in failed, trying redirect fallback: $popupError",
          );
          await FirebaseAuth.instance.signInWithRedirect(googleProvider);
          return true; // Page redirects
        }
        return false;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
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

    // Reuse an existing unique guest UID across sessions.
    // Replace the old hardcoded placeholder if present.
    String? savedUid = prefs.getString('mock_user_uid');
    if (savedUid == null || savedUid == 'guest_user_123') {
      final ms = DateTime.now().millisecondsSinceEpoch;
      // Add a deterministic suffix to reduce collision probability further.
      final suffix = (ms % 99991).toString().padLeft(5, '0');
      savedUid = 'guest_${ms}_$suffix';
    }

    await prefs.setString('mock_user_uid', savedUid);
    await prefs.setString('mock_user_name', 'Tamu Offline');
    await prefs.setString('mock_user_email', 'guest@aestral.local');

    state = UserSession(
      uid: savedUid,
      displayName: 'Tamu Offline',
      email: 'guest@aestral.local',
      isMock: true,
    );
  }

  /// Builds the Authorization header for all API calls.
  /// Returns `'Bearer {idToken}'` for authenticated Firebase users,
  /// or `'Guest {uid}'` for guest/mock sessions.
  /// Use this instead of building the header inline in each screen.
  Future<String> getAuthHeader() async {
    final session = state;
    if (session == null || session.isMock) {
      return 'Guest ${session?.uid ?? 'anonymous'}';
    }
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      return token != null ? 'Bearer $token' : 'Guest ${session.uid}';
    } catch (e) {
      debugPrint('AuthNotifier.getAuthHeader: $e');
      return 'Guest ${session.uid}';
    }
  }

  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint("Error signing out from Firebase: $e");
      }
      try {
        // Only attempt Google Sign-In sign out on mobile, to avoid web configuration errors
        if (!kIsWeb) {
          await GoogleSignIn.instance.signOut();
        }
      } catch (e) {
        debugPrint("Error signing out from Google: $e");
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_user_uid');
      await prefs.remove('mock_user_name');
      await prefs.remove('mock_user_email');
    } catch (e) {
      debugPrint("Error clearing local session preferences: $e");
    }
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserSession?>(() {
  return AuthNotifier();
});

/// Provider untuk splash screen — di-set false oleh AuthNotifier saat inisialisasi selesai.
/// NotifierProvider<bool> lebih idiomatik daripada membaca getter dari notifier instance.
final authInitializingProvider = NotifierProvider<_InitializingNotifier, bool>(
  _InitializingNotifier.new,
);

class _InitializingNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  /// Dipanggil oleh AuthNotifier saat _loadSession() selesai.
  void complete() => state = false;
}
