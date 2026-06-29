import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/home/presentation/dashboard_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    final session = ref.watch(authProvider);

    return MaterialApp(
      title: 'Aestral',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: session == null ? const LoginScreen() : const DashboardScreen(),
    );
  }
}
