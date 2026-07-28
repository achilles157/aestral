import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for Daily Synthesis Card — one entry per calendar day.
///
/// Key pattern: `daily_synthesis_YYYY-MM-DD_<wukuName>`
/// Valid for the same calendar day. Wuku in key ensures fresh generation
/// if wuku somehow drifts (edge case: app used across midnight).
class DailySynthesisService {
  static const String _prefix = 'daily_synthesis_';

  static String _key(String wukuName) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return '$_prefix${dateStr}_${wukuName.replaceAll(' ', '_')}';
  }

  /// Returns today's cached synthesis, or null if not yet generated.
  static Future<String?> getToday(String wukuName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(wukuName));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['synthesis'] as String?;
    } catch (e) {
      debugPrint('DailySynthesisService.getToday error: $e');
      return null;
    }
  }

  /// Persists today's synthesis for the given wuku name.
  static Future<void> save(String wukuName, String synthesis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(wukuName),
        jsonEncode({
          'synthesis': synthesis,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('DailySynthesisService: cached for wuku $wukuName');
    } catch (e) {
      debugPrint('DailySynthesisService.save error: $e');
    }
  }

  /// Remove today's cache (force refresh on next open).
  static Future<void> invalidateToday(String wukuName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(wukuName));
    } catch (e) {
      debugPrint('DailySynthesisService.invalidate error: $e');
    }
  }
}
