import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/weton_utils.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/home/presentation/main_shell.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Weton character data ───────────────────────────────────────────────────
  // Pangarasan & pancasuda loaded from JSON once before runApp() so that
  // WetonUtils.calculateWeton() has data ready on first call.
  try {
    final charJson = await rootBundle.loadString(
      'assets/weton/pangarasan-pancasuda.json',
    );
    WetonUtils.loadCharacterData(jsonDecode(charJson) as Map<String, dynamic>);
  } catch (e) {
    debugPrint('WetonUtils: character data load failed — $e');
  }

  // ── Global error handlers ──────────────────────────────────────────────────

  // Catch Flutter framework errors (widget build crashes, rendering errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // default: logs to console in debug
    // TODO(Phase4): forward to Firebase Crashlytics when added
    // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Catch uncaught async errors thrown outside of Flutter's zone
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    // TODO(Phase4): forward to Firebase Crashlytics when added
    // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true; // return true = error handled, don't propagate
  };

  // ── Error widget override ──────────────────────────────────────────────────

  // In release mode, replace Flutter's red/blank crash screen with a graceful
  // branded error card so users see something useful instead of nothing.
  if (!kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _AestralErrorWidget(details: details);
    };
  }

  // ── Firebase init ──────────────────────────────────────────────────────────

  // Try to initialize Firebase, but catch errors to allow local-fallback execution
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase successfully initialized");
  } catch (e) {
    debugPrint("Firebase initialization failed (Running in Local Fallback mode): $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitializing = ref.watch(authInitializingProvider);
    final session = ref.watch(authProvider);

    return MaterialApp(
      title: 'Aestral',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: isInitializing
          ? const _AestralSplashScreen()
          : session == null
              ? const LoginScreen()
              : const MainShell(),
    );
  }
}

// ── Graceful error widget ──────────────────────────────────────────────────────

/// Shown in release mode when a widget subtree throws an unhandled exception.
/// Dark-themed and branded so users see a recoverable UI rather than a blank screen.
class _AestralErrorWidget extends StatelessWidget {
  const _AestralErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D0D1A), // matches AppTheme scaffold background
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFF7C6FCD),
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sesuatu berjalan di luar orbit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kosmis sedang menyeimbangkan diri.\nCoba kembali sebentar lagi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Splash screen ──────────────────────────────────────────────────────────────

/// Displayed while Firebase and auth state are initializing.
class _AestralSplashScreen extends StatelessWidget {
  const _AestralSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGold,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'AESTRAL',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Menyelaraskan energi kosmis...',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppTheme.accentGold,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
