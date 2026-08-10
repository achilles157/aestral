import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/legal/services/consent_service.dart';
import '../../../features/legal/presentation/consent_onboarding_screen.dart';
import '../../../core/theme/app_theme.dart';

/// Gate yang memeriksa consent sebelum mengizinkan akses ke MainShell.
///
/// P3-A: Muncul SEKALI — setelah consent disetujui, dicek ulang hanya jika
/// versi kebijakan naik (via [ConsentService.hasRequiredConsents]).
class ConsentGate extends ConsumerStatefulWidget {
  final Widget child;

  const ConsentGate({super.key, required this.child});

  @override
  ConsumerState<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends ConsumerState<ConsentGate> {
  bool? _needsConsent; // null = loading
  bool _showingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final svc = ref.read(consentServiceProvider);
    final has = await svc.hasRequiredConsents();
    if (!mounted) return;
    setState(() {
      _needsConsent = !has;
      _showingOnboarding = !has;
    });
  }

  void _onConsentComplete() {
    setState(() {
      _showingOnboarding = false;
      _needsConsent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsConsent == null) {
      // Loading — tampilkan blank screen sementara
      return Container(
        color: const Color(0xFF0B0B1A),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPurple),
        ),
      );
    }

    if (_showingOnboarding && _needsConsent == true) {
      return ConsentOnboardingScreen(onComplete: _onConsentComplete);
    }

    return widget.child;
  }
}
