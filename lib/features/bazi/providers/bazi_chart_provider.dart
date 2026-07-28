import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../domain/bazi_chart.dart';

/// Global provider for the user's Ba Zi chart.
///
/// Reactive to [birthProfileProvider] — auto-reloads when profile changes.
/// API response cached 1 year by [ApiService.getBaziChart] (deterministic).
/// Returns null when no dobDate in profile.
class BaziChartNotifier extends AsyncNotifier<BaziChart?> {
  @override
  Future<BaziChart?> build() async {
    final profile = await ref.watch(birthProfileProvider.future);
    if (profile.dobDate == null) return null;

    try {
      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final dobStr = DateFormat('yyyy-MM-dd').format(profile.dobDate!);

      final result = await ApiService.getBaziChart(
        birthDate: dobStr,
        birthHour: profile.birthHour,
        latitude: profile.latitude,
        longitude: profile.longitude,
        authHeader: authHeader,
      );

      // Handle both {chart: {...}} and flat response shapes
      final raw = result.containsKey('chart')
          ? result['chart'] as Map<String, dynamic>
          : result;

      return BaziChart.fromJson(raw);
    } catch (e) {
      debugPrint('BaziChartProvider: load error — $e');
      return null;
    }
  }
}

final baziChartProvider = AsyncNotifierProvider<BaziChartNotifier, BaziChart?>(
  BaziChartNotifier.new,
);
