import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single journal entry — one per day.
class CosmicJournalEntry {
  final DateTime date;
  final String rating; // 'berat' | 'normal' | 'luar_biasa'
  final String prediction; // 'yong' | 'ji' | 'netral'

  const CosmicJournalEntry({
    required this.date,
    required this.rating,
    required this.prediction,
  });

  /// True when the day's cosmic prediction matched the user's actual experience.
  /// Netral predictions are excluded — only yong/ji are scored.
  bool get isAccurate =>
      (prediction == 'yong' && rating == 'luar_biasa') ||
      (prediction == 'ji' && rating == 'berat');

  /// Whether this entry is scorable (non-netral prediction).
  bool get isScorable => prediction != 'netral';

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'rating': rating,
    'prediction': prediction,
  };

  factory CosmicJournalEntry.fromJson(Map<String, dynamic> json) =>
      CosmicJournalEntry(
        date: DateTime.parse(json['date'] as String),
        rating: json['rating'] as String,
        prediction: json['prediction'] as String,
      );
}

/// Local journal service — SharedPreferences, privacy-first, no auth needed.
///
/// Key pattern: `cosmic_journal_YYYY-MM-DD`
/// Retains last 30 days of entries automatically.
class CosmicJournalService {
  static const String _prefix = 'cosmic_journal_';

  static String _keyForDate(DateTime date) =>
      '$_prefix${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Save or overwrite today's entry.
  /// Throws on failure so callers can surface the error to the user (W29).
  static Future<void> save(CosmicJournalEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForDate(entry.date);
    await prefs.setString(key, jsonEncode(entry.toJson()));
    debugPrint('CosmicJournalService: saved $key → ${entry.rating}');
  }

  /// Returns today's entry, or null if not yet logged.
  static Future<CosmicJournalEntry?> getTodayEntry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyForDate(DateTime.now());
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return CosmicJournalEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('CosmicJournalService.getTodayEntry error: $e');
      return null;
    }
  }

  /// Returns entries for the last [days] days (default 30), newest first.
  static Future<List<CosmicJournalEntry>> getRecentEntries({
    int days = 30,
  }) async {
    final entries = <CosmicJournalEntry>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      for (int i = 0; i < days; i++) {
        final date = today.subtract(Duration(days: i));
        final key = _keyForDate(date);
        final raw = prefs.getString(key);
        if (raw != null) {
          try {
            // W30: isolate per-entry parse so one bad entry doesn't abort the list
            entries.add(
              CosmicJournalEntry.fromJson(
                jsonDecode(raw) as Map<String, dynamic>,
              ),
            );
          } catch (entryErr) {
            debugPrint(
              'CosmicJournalService: skipping malformed entry $key — $entryErr',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('CosmicJournalService.getRecentEntries error: $e');
    }
    return entries;
  }

  /// Accuracy score 0.0–1.0 from scorable (non-netral) entries.
  /// Returns null if insufficient data (< 3 scorable entries).
  static double? calculateAccuracy(List<CosmicJournalEntry> entries) {
    final scorable = entries.where((e) => e.isScorable).toList();
    if (scorable.length < 3) return null;
    final accurate = scorable.where((e) => e.isAccurate).length;
    return accurate / scorable.length;
  }
}
