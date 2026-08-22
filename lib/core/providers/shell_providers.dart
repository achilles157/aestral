import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the active tab index inside [MainShell].
/// Switch tabs from anywhere:
///   ref.read(activeTabProvider.notifier).setTab(2); // jump to Weton
class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(
  ActiveTabNotifier.new,
);

// ── Seasonal Synthesis → Sesepuh Kosmis Context ──────────────────────────

/// Konteks yang disimpan seasonal synthesis card sebelum navigasi ke Sesepuh
/// Kosmis. Dibaca oleh [OracleChatScreen] untuk auto-send prompt pre-filled.
class SeasonalSynthesisContext {
  /// ID Pranata Mangsa (1-12)
  final int mangsaId;

  /// Nama Pranata Mangsa, e.g. "Mangsa Kanem"
  final String mangsaName;

  /// Elemen musim dari Ba Zi, e.g. "api", "air"
  final String seasonElement;

  /// Ringkasan sintesis (3-5 kalimat hasil AI)
  final String synthesisSummary;

  /// Elemen Day Master dari Ba Zi chart (opsional)
  final String? dayMasterElement;

  /// Label Da Yun aktif (opsional), e.g. "Kayu Yin — usia 28-37"
  final String? daYunLabel;

  /// Arketipe modern Pranata Mangsa
  final String? mangsaArketipe;

  const SeasonalSynthesisContext({
    required this.mangsaId,
    required this.mangsaName,
    required this.seasonElement,
    required this.synthesisSummary,
    this.dayMasterElement,
    this.daYunLabel,
    this.mangsaArketipe,
  });
}

final seasonalSynthesisContextProvider =
    NotifierProvider<
      SeasonalSynthesisContextNotifier,
      SeasonalSynthesisContext?
    >(SeasonalSynthesisContextNotifier.new);

class SeasonalSynthesisContextNotifier
    extends Notifier<SeasonalSynthesisContext?> {
  @override
  SeasonalSynthesisContext? build() => null;

  void set(SeasonalSynthesisContext ctx) => state = ctx;
  void clear() => state = null;
}

// ── Reduce Effects ──────────────────────────────────────────────────────────

/// Persists user preference to reduce visual effects (blur, animations).
/// When true, [GlassCard] skips BackdropFilter and MediaQuery.disableAnimations
/// is overridden to true app-wide via [_EffectsMediaQueryOverride] in main.dart.
class ReduceEffectsNotifier extends AsyncNotifier<bool> {
  static const _key = 'reduce_effects';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    state = AsyncValue.data(!current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, !current);
  }
}

final reduceEffectsProvider =
    AsyncNotifierProvider<ReduceEffectsNotifier, bool>(
      ReduceEffectsNotifier.new,
    );
