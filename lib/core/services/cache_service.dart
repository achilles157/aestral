import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached response with expiry metadata.
class CachedResponse {
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  CachedResponse({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'data': data,
    'expires_at': expiresAt.toIso8601String(),
  };

  factory CachedResponse.fromJson(Map<String, dynamic> json) {
    return CachedResponse(
      data: Map<String, dynamic>.from(json['data'] as Map),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Cache service untuk API responses dengan TTL support.
///
/// Usage:
/// ```dart
/// final cache = CacheService();
///
/// // Try cache first
/// final cached = await cache.get('weton_daily_2024-01-01');
/// if (cached != null) return cached;
///
/// // Fetch from API
/// final fresh = await apiCall();
///
/// // Cache for 24 hours
/// await cache.set('weton_daily_2024-01-01', fresh,
///   ttl: Duration(hours: 24));
/// ```
class CacheService {
  static const String _keyPrefix = 'api_cache_';
  static const int _maxCacheSize = 50; // Max entries before cleanup

  // In-memory cache untuk fast access (app lifetime only)
  final Map<String, CachedResponse> _memoryCache = {};

  /// Get cached response if exists dan belum expired.
  /// Returns null jika tidak ada atau sudah expired.
  Future<Map<String, dynamic>?> get(String key) async {
    // 1. Check memory cache first
    final memEntry = _memoryCache[key];
    if (memEntry != null && !memEntry.isExpired) {
      debugPrint('CacheService: Memory hit for $key');
      return memEntry.data;
    }

    // 2. Check persistent cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_keyPrefix$key');

      if (jsonStr != null) {
        final entry = CachedResponse.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );

        if (!entry.isExpired) {
          // Restore to memory cache
          _memoryCache[key] = entry;
          debugPrint('CacheService: Disk hit for $key');
          return entry.data;
        } else {
          // Expired - remove from disk
          await prefs.remove('$_keyPrefix$key');
          debugPrint('CacheService: Expired entry removed for $key');
        }
      }
    } catch (e) {
      debugPrint('CacheService.get error for $key: $e');
    }

    return null;
  }

  /// Cache response with TTL (Time To Live).
  ///
  /// Default TTL: 1 hour
  /// Recommended TTLs:
  /// - Deterministic data (Ba Zi chart): Duration(days: 365)
  /// - Daily data (Weton daily): Duration(hours: 24)
  /// - Monthly data (Calendar): Duration(days: 7)
  /// - Static data (Tarot metadata): Duration(days: 30)
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final expiresAt = DateTime.now().add(ttl);
    final entry = CachedResponse(data: data, expiresAt: expiresAt);

    // Store in memory
    _memoryCache[key] = entry;

    // Store in persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$key', jsonEncode(entry.toJson()));
      debugPrint('CacheService: Cached $key (TTL: ${ttl.inMinutes}m)');

      // Cleanup if cache too large
      await _cleanupIfNeeded(prefs);
    } catch (e) {
      debugPrint('CacheService.set error for $key: $e');
    }
  }

  /// Clear specific cache entry.
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$key');
      debugPrint('CacheService: Removed $key');
    } catch (e) {
      debugPrint('CacheService.remove error: $e');
    }
  }

  /// Clear all cached responses.
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('CacheService: Cleared all cache (${keys.length} entries)');
    } catch (e) {
      debugPrint('CacheService.clearAll error: $e');
    }
  }

  /// Get cache statistics (count, size estimate).
  Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));

      int validCount = 0;
      int expiredCount = 0;

      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          try {
            final entry = CachedResponse.fromJson(
              jsonDecode(jsonStr) as Map<String, dynamic>,
            );
            if (entry.isExpired) {
              expiredCount++;
            } else {
              validCount++;
            }
          } catch (_) {
            expiredCount++;
          }
        }
      }

      return {
        'valid_entries': validCount,
        'expired_entries': expiredCount,
        'memory_entries': _memoryCache.length,
        'total_disk_entries': keys.length,
      };
    } catch (e) {
      debugPrint('CacheService.getStats error: $e');
      return {};
    }
  }

  /// Internal: Cleanup expired entries jika cache terlalu besar.
  Future<void> _cleanupIfNeeded(SharedPreferences prefs) async {
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList();

    if (keys.length > _maxCacheSize) {
      debugPrint('CacheService: Cleaning up (${keys.length} entries)');

      int removed = 0;
      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          try {
            final entry = CachedResponse.fromJson(
              jsonDecode(jsonStr) as Map<String, dynamic>,
            );
            if (entry.isExpired) {
              await prefs.remove(key);
              removed++;
            }
          } catch (_) {
            // Corrupt entry - remove
            await prefs.remove(key);
            removed++;
          }
        }
      }

      if (removed > 0) {
        debugPrint('CacheService: Removed $removed expired/corrupt entries');
      }
    }
  }

  /// Generate cache key untuk API endpoint dengan params.
  static String generateKey(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return endpoint;

    // Sort keys untuk consistent cache keys
    final sortedKeys = params.keys.toList()..sort();
    final paramStr = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    return '${endpoint}_$paramStr';
  }
}
