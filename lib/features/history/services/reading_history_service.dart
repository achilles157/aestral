import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_entry.dart';

/// Layanan penyimpanan riwayat pembacaan kosmis ke SharedPreferences.
/// Menyimpan maksimal [_maxEntries] entri terbaru (FIFO).
class ReadingHistoryService {
  static const _key = 'aestral_reading_history';
  static const _maxEntries = 50;

  /// Muat semua entri riwayat, terbaru di depan.
  static Future<List<ReadingEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(ReadingEntry.fromJson)
          .toList();
    } catch (e) {
      debugPrint('ReadingHistoryService.load error: $e');
      return [];
    }
  }

  /// Simpan entri baru di posisi terdepan. Non-fatal jika gagal.
  static Future<void> save(ReadingEntry entry) async {
    try {
      final entries = await load();
      // Hindari duplikat dalam 1 menit (misal: hot reload / double trigger)
      final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
      final isDupe = entries.any((e) =>
          e.type == entry.type &&
          e.title == entry.title &&
          e.timestamp.isAfter(cutoff));
      if (isDupe) return;

      entries.insert(0, entry);
      final trimmed = entries.length > _maxEntries
          ? entries.sublist(0, _maxEntries)
          : entries;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        json.encode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('ReadingHistoryService.save error: $e');
    }
  }

  /// Hapus seluruh riwayat.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('ReadingHistoryService.clear error: $e');
    }
  }
}
