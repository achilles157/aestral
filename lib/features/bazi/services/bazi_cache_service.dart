import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache untuk Ba Zi chart result.
///
/// Chart adalah deterministik — input yang sama selalu menghasilkan output yang
/// sama — sehingga tidak perlu TTL. Cache disimpan selamanya sampai app di-clear.
class BaziCacheService {
  static const _prefix = 'bazi_chart_';

  /// Buat cache key dari parameter kalkulasi.
  static String cacheKey(String date, int? hour, double? lat, double? lng) {
    final h = hour?.toString() ?? 'x';
    final la = lat?.toStringAsFixed(4) ?? '0';
    final lo = lng?.toStringAsFixed(4) ?? '0';
    return '$_prefix${date}_${h}_${la}_$lo';
  }

  /// Ambil data dari cache. Mengembalikan null jika tidak ada atau corrupt.
  static Future<Map<String, dynamic>?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Cache corrupt — hapus dan return null agar di-fetch ulang
      await prefs.remove(key);
      return null;
    }
  }

  /// Simpan API response data ke cache.
  static Future<void> save(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      // Cache write failure non-fatal — app tetap berjalan normal
      debugPrint('BaziCacheService: failed to save — $e');
    }
  }
}
