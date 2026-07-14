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
