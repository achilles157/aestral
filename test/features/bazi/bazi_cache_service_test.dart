import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aestral/features/bazi/services/bazi_cache_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── Cache key generation ─────────────────────────────────────────────────

  group('BaziCacheService.cacheKey', () {
    test('same inputs → same key', () {
      final k1 = BaziCacheService.cacheKey('2002-07-15', 14, -6.2, 106.8);
      final k2 = BaziCacheService.cacheKey('2002-07-15', 14, -6.2, 106.8);
      expect(k1, k2);
    });

    test('different dates → different keys', () {
      final k1 = BaziCacheService.cacheKey('2002-07-15', null, null, null);
      final k2 = BaziCacheService.cacheKey('2002-07-16', null, null, null);
      expect(k1, isNot(k2));
    });

    test('different hours → different keys', () {
      final k1 = BaziCacheService.cacheKey('2002-07-15', 14, null, null);
      final k2 = BaziCacheService.cacheKey('2002-07-15', 15, null, null);
      expect(k1, isNot(k2));
    });

    test('no hour (null) → contains placeholder x', () {
      final k = BaziCacheService.cacheKey('2002-07-15', null, null, null);
      expect(k, contains('_x_'));
    });

    // Regression: stem=1,branch=10 vs stem=11,branch=0 must not collide
    // (This would be a BaziChart cache key issue, but verifies separator logic)
    test('lat/lng precision: 4 decimal places in key', () {
      final k = BaziCacheService.cacheKey('2002-07-15', null, -6.12345, 106.87654);
      expect(k, contains('-6.1235')); // toStringAsFixed(4) rounds
      expect(k, contains('106.8765'));
    });
  });

  // ─── get / save ───────────────────────────────────────────────────────────

  group('BaziCacheService get/save', () {
    test('get returns null when cache empty', () async {
      final result = await BaziCacheService.get('nonexistent_key');
      expect(result, isNull);
    });

    test('save then get returns same data', () async {
      const key = 'test_key';
      final data = {'dayMasterId': 'jia', 'wuXingBalance': {'kayu': 5}};
      await BaziCacheService.save(key, data);
      final result = await BaziCacheService.get(key);
      expect(result, isNotNull);
      expect(result!['dayMasterId'], 'jia');
    });

    test('save then get preserves nested data', () async {
      const key = 'nested_test';
      final data = {
        'yearPillar': {'stemIndex': 3, 'branchIndex': 7},
        'dayMasterId': 'bing',
      };
      await BaziCacheService.save(key, data);
      final result = await BaziCacheService.get(key);
      expect(result!['yearPillar']['stemIndex'], 3);
    });

    test('corrupt cache → returns null (tidak crash)', () async {
      // Inject corrupt JSON
      SharedPreferences.setMockInitialValues({'corrupt_key': 'not-valid-json{'});
      final result = await BaziCacheService.get('corrupt_key');
      expect(result, isNull);
    });

    test('overwrite existing key with new data', () async {
      const key = 'overwrite_test';
      await BaziCacheService.save(key, {'v': 1});
      await BaziCacheService.save(key, {'v': 2});
      final result = await BaziCacheService.get(key);
      expect(result!['v'], 2);
    });
  });
}
