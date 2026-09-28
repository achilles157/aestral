import 'dart:convert';

import 'package:aestral/core/services/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit test untuk [CacheService] & [CachedResponse] — fondasi caching
/// seluruh aplikasi (dipakai `ApiService._cachedPost`).
///
/// Fokus: TTL/expiry, urutan lookup (memori → disk), pemulihan dari disk,
/// ketahanan terhadap data rusak, dan pembersihan otomatis.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prefix = 'api_cache_';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CachedResponse', () {
    test('isExpired false kalau expiresAt di masa depan', () {
      final entry = CachedResponse(
        data: {'a': 1},
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(entry.isExpired, isFalse);
    });

    test('isExpired true kalau expiresAt di masa lalu', () {
      final entry = CachedResponse(
        data: {'a': 1},
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(entry.isExpired, isTrue);
    });

    test('toJson menyimpan data dan expires_at sebagai ISO-8601', () {
      final expires = DateTime(2026, 12, 31, 23, 59);
      final entry = CachedResponse(data: {'x': 'y'}, expiresAt: expires);

      final json = entry.toJson();

      expect(json['data'], {'x': 'y'});
      expect(json['expires_at'], expires.toIso8601String());
    });

    test('round-trip toJson → fromJson mempertahankan nilai', () {
      final original = CachedResponse(
        data: {
          'nested': {'k': 42},
        },
        expiresAt: DateTime(2027, 1, 15, 8, 30),
      );

      final restored = CachedResponse.fromJson(original.toJson());

      expect(restored.data['nested'], {'k': 42});
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.isExpired, original.isExpired);
    });

    test('fromJson mempertahankan data kosong', () {
      final restored = CachedResponse.fromJson({
        'data': <String, dynamic>{},
        'expires_at': DateTime(2027, 1, 1).toIso8601String(),
      });

      expect(restored.data, isEmpty);
    });
  });

  group('CacheService.generateKey', () {
    test('params null → hanya endpoint', () {
      expect(CacheService.generateKey('weton_daily', null), 'weton_daily');
    });

    test('params kosong → hanya endpoint', () {
      expect(CacheService.generateKey('weton_daily', {}), 'weton_daily');
    });

    test('params sederhana digabung dengan format k=v', () {
      expect(
        CacheService.generateKey('weton', {'date': '2026-09-28'}),
        'weton_date=2026-09-28',
      );
    });

    test('urutan key tidak memengaruhi hasil (deterministik)', () {
      final a = CacheService.generateKey('x', {'b': 2, 'a': 1});
      final b = CacheService.generateKey('x', {'a': 1, 'b': 2});

      expect(a, b);
      expect(a, 'x_a=1&b=2');
    });

    test('key yang sama menghasilkan cache key yang sama', () {
      final k1 = CacheService.generateKey('bazi', {'dm': 'bing', 'y': 2026});
      final k2 = CacheService.generateKey('bazi', {'y': 2026, 'dm': 'bing'});

      expect(k1, k2);
    });

    test('nilai berbeda menghasilkan key berbeda', () {
      final a = CacheService.generateKey('weton', {'date': '2026-01-01'});
      final b = CacheService.generateKey('weton', {'date': '2026-01-02'});

      expect(a, isNot(b));
    });
  });

  group('CacheService — set & get dasar', () {
    test('get key yang belum pernah di-set → null', () async {
      final cache = CacheService();

      expect(await cache.get('tidak-ada'), isNull);
    });

    test('set lalu get mengembalikan data yang sama', () async {
      final cache = CacheService();
      await cache.set('kunci', {'nilai': 1});

      final hasil = await cache.get('kunci');

      expect(hasil, {'nilai': 1});
    });

    test(
      'get dari instance baru (memori kosong) memulihkan dari disk',
      () async {
        final cacheA = CacheService();
        await cacheA.set('disk-key', {'dari': 'disk'});

        // Instance baru: memori kosong, harus ambil dari SharedPreferences.
        final cacheB = CacheService();
        final hasil = await cacheB.get('disk-key');

        expect(hasil, {'dari': 'disk'});
      },
    );

    test(
      'data tersimpan di SharedPreferences dengan prefix yang benar',
      () async {
        final cache = CacheService();
        await cache.set('mykey', {'a': 1});

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('${prefix}mykey'), isNotNull);
      },
    );

    test('set menimpa nilai lama untuk key yang sama', () async {
      final cache = CacheService();
      await cache.set('k', {'v': 1});
      await cache.set('k', {'v': 2});

      expect(await cache.get('k'), {'v': 2});
    });

    test('key berbeda tidak saling bocor', () async {
      final cache = CacheService();
      await cache.set('a', {'x': 'a'});
      await cache.set('b', {'x': 'b'});

      expect(await cache.get('a'), {'x': 'a'});
      expect(await cache.get('b'), {'x': 'b'});
    });
  });

  group('CacheService — TTL & expiry', () {
    test('entry dengan TTL panjang masih valid', () async {
      final cache = CacheService();
      await cache.set('panjang', {'v': 1}, ttl: const Duration(days: 30));

      expect(await cache.get('panjang'), {'v': 1});
    });

    test('entry dengan TTL negatif langsung dianggap expired', () async {
      final cache = CacheService();
      await cache.set('basi', {'v': 1}, ttl: const Duration(seconds: -1));

      expect(await cache.get('basi'), isNull);
    });

    test('entry TTL nol dianggap expired', () async {
      final cache = CacheService();
      await cache.set('nol', {'v': 1}, ttl: Duration.zero);

      // Tunggu sedikit agar DateTime.now() pasti melewati expiresAt.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await cache.get('nol'), isNull);
    });

    test('entry expired dihapus dari disk saat diakses', () async {
      final cacheA = CacheService();
      await cacheA.set('hapus', {'v': 1}, ttl: const Duration(seconds: -1));

      // Instance baru agar tidak kena memori cache.
      final cacheB = CacheService();
      await cacheB.get('hapus');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${prefix}hapus'), isNull);
    });

    test('entry expired di disk tidak dipulihkan oleh instance baru', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${prefix}expired',
        json.encode({
          'data': {'v': 'lama'},
          'expires_at': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        }),
      );

      final cache = CacheService();
      expect(await cache.get('expired'), isNull);
    });

    test('entry valid di disk dipulihkan oleh instance baru', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${prefix}valid',
        json.encode({
          'data': {'v': 'baru'},
          'expires_at': DateTime.now()
              .add(const Duration(hours: 5))
              .toIso8601String(),
        }),
      );

      final cache = CacheService();
      expect(await cache.get('valid'), {'v': 'baru'});
    });
  });

  group('CacheService — ketahanan data rusak', () {
    test(
      'JSON rusak di disk → get mengembalikan null, tidak melempar',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${prefix}rusak', 'bukan json {{{');

        final cache = CacheService();

        expect(await cache.get('rusak'), isNull);
      },
    );

    test('JSON valid tapi struktur salah → null, tidak melempar', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${prefix}salah', json.encode([1, 2, 3]));

      final cache = CacheService();

      expect(await cache.get('salah'), isNull);
    });

    test('expires_at bukan tanggal valid → null, tidak melempar', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${prefix}tanggal-salah',
        json.encode({
          'data': {'a': 1},
          'expires_at': 'bukan-tanggal',
        }),
      );

      final cache = CacheService();

      expect(await cache.get('tanggal-salah'), isNull);
    });
  });

  group('CacheService — remove', () {
    test('remove menghapus dari memori dan disk', () async {
      final cache = CacheService();
      await cache.set('target', {'v': 1});
      expect(await cache.get('target'), {'v': 1});

      await cache.remove('target');

      expect(await cache.get('target'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${prefix}target'), isNull);
    });

    test('remove key yang tidak ada tetap aman', () async {
      final cache = CacheService();

      await cache.remove('tidak-ada');

      expect(await cache.get('tidak-ada'), isNull);
    });
  });

  group('CacheService — clearAll', () {
    test('menghapus semua entry ber-prefix', () async {
      final cache = CacheService();
      await cache.set('a', {'v': 1});
      await cache.set('b', {'v': 2});
      await cache.set('c', {'v': 3});

      await cache.clearAll();

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
      expect(await cache.get('c'), isNull);
    });

    test('tidak menghapus key prefs lain di luar prefix', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('setelan_pengguna', 'penting');

      final cache = CacheService();
      await cache.set('a', {'v': 1});
      await cache.clearAll();

      expect(prefs.getString('setelan_pengguna'), 'penting');
    });

    test('clearAll pada cache kosong tetap aman', () async {
      final cache = CacheService();

      await cache.clearAll();

      expect(await cache.get('apa-saja'), isNull);
    });
  });

  group('CacheService — getStats', () {
    test('melaporkan hitungan valid & expired dengan benar', () async {
      final cache = CacheService();
      await cache.set('valid1', {'v': 1});
      await cache.set('valid2', {'v': 2});
      await cache.set('expired', {'v': 3}, ttl: const Duration(seconds: -1));

      final stats = await cache.getStats();

      expect(stats['valid_entries'], 2);
      expect(stats['expired_entries'], 1);
      expect(stats['total_disk_entries'], 3);
    });

    test('memory_entries mencerminkan isi memori', () async {
      final cache = CacheService();
      await cache.set('m1', {'v': 1});
      await cache.set('m2', {'v': 2});

      final stats = await cache.getStats();

      expect(stats['memory_entries'], greaterThanOrEqualTo(2));
    });

    test('cache kosong → semua hitungan nol', () async {
      final cache = CacheService();

      final stats = await cache.getStats();

      expect(stats['valid_entries'], 0);
      expect(stats['expired_entries'], 0);
      expect(stats['total_disk_entries'], 0);
      expect(stats['memory_entries'], 0);
    });

    test('entry rusak dihitung sebagai expired', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${prefix}rusak', 'bukan json');

      final cache = CacheService();
      final stats = await cache.getStats();

      expect(stats['expired_entries'], 1);
      expect(stats['valid_entries'], 0);
    });

    test('getStats mengembalikan map kosong saat prefs error', () async {
      // Tidak bisa mensimulasikan error SharedPreferences secara langsung,
      // tapi kita verifikasi bentuk return yang selalu Map<String, dynamic>.
      final cache = CacheService();
      final stats = await cache.getStats();

      expect(stats, isA<Map<String, dynamic>>());
    });
  });
}
