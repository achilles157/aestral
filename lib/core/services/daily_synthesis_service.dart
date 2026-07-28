import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for Seasonal Synthesis Card.
///
/// Granularitas: Pranata Mangsa (~30 hari, 12x per tahun).
/// Cache key: `seasonal_synthesis_pranata_<id>_<year>`
/// Valid selama Pranata Mangsa yang sama + tahun yang sama.
///
/// State A (tanpa Tarot Kosmis): cache key includes '_no_tarot'
/// State B (dengan Tarot Kosmis): cache key includes '_with_tarot'
/// Saat user draw Tarot Kosmis, State A cache tetap valid —
/// State B di-generate ulang dan cache-nya terpisah.
class DailySynthesisService {
  static const String _prefix = 'seasonal_synthesis_pranata_';

  static String _key(
    int mangsaId,
    int year, {
    required bool withTarot,
    required String wetonId, // e.g. 'jumat_kliwon' — unique per user
  }) {
    final tarotSuffix = withTarot ? 'with_tarot' : 'no_tarot';
    return '$_prefix${mangsaId}_${year}_${wetonId}_$tarotSuffix';
  }

  /// Returns cached synthesis for current Pranata Mangsa, or null if not cached.
  static Future<String?> getToday(
    int mangsaId,
    int year, {
    required bool withTarot,
    required String wetonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(
        _key(mangsaId, year, withTarot: withTarot, wetonId: wetonId),
      );
      if (raw == null) return null;
      return raw;
    } catch (e) {
      debugPrint('DailySynthesisService.get error: $e');
      return null;
    }
  }

  /// Saves synthesis for current Pranata Mangsa.
  static Future<void> save(
    int mangsaId,
    int year,
    String synthesis, {
    required bool withTarot,
    required String wetonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(mangsaId, year, withTarot: withTarot, wetonId: wetonId),
        synthesis,
      );
      debugPrint(
        'DailySynthesisService: cached pranata $mangsaId/$year '
        '(withTarot=$withTarot)',
      );
    } catch (e) {
      debugPrint('DailySynthesisService.save error: $e');
    }
  }

  /// Force re-generate on next open.
  static Future<void> invalidate(
    int mangsaId,
    int year, {
    bool? withTarot,
    required String wetonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (withTarot == null) {
        await prefs.remove(
          _key(mangsaId, year, withTarot: true, wetonId: wetonId),
        );
        await prefs.remove(
          _key(mangsaId, year, withTarot: false, wetonId: wetonId),
        );
      } else {
        await prefs.remove(
          _key(mangsaId, year, withTarot: withTarot, wetonId: wetonId),
        );
      }
    } catch (e) {
      debugPrint('DailySynthesisService.invalidate error: $e');
    }
  }

  /// Returns true if user's last Tarot draw was Kosmis (mangsa) mode.
  static Future<bool> isLastDrawKosmis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_tarot_draw_type') == 'mangsa';
    } catch (_) {
      return false;
    }
  }
}
