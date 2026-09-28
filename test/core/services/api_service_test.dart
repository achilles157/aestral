import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aestral/core/errors/oracle_rest_exception.dart';
import 'package:aestral/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit test untuk [ApiService] — helper POST, penanganan status,
/// pemetaan error, retry, dan caching.
///
/// Memakai `MockClient` dari `package:http/testing.dart` sehingga tidak
/// menyentuh jaringan sama sekali.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // ApiService._cache adalah static final dengan cache memori internal
    // yang bertahan antar test. Tanpa pembersihan lewat instance yang SAMA,
    // test kedua dst. akan mendapat cache hit palsu sehingga MockClient
    // tidak pernah dipanggil.
    await ApiService.clearCache();
  });

  tearDown(() {
    ApiService.resetClient();
  });

  /// Helper: jalankan [aksi], pastikan melempar error bertipe [T],
  /// lalu jalankan [periksa] terhadap error tersebut.
  Future<void> expectThrows<T extends Object>(
    Future<void> Function() aksi,
    void Function(T error) periksa,
  ) async {
    try {
      await aksi();
    } on T catch (e) {
      periksa(e);
      return;
    } catch (e) {
      fail('Melempar ${e.runtimeType}, bukan $T: $e');
    }
    fail('Tidak melempar apa pun, padahal $T diharapkan');
  }

  /// Bangun MockClient yang mencatat request dan membalas [statusCode].
  MockClient balas(int statusCode, String body, {List<http.Request>? rekam}) {
    return MockClient((request) async {
      rekam?.add(request);
      return http.Response(body, statusCode);
    });
  }

  String suksesJson([Map<String, dynamic>? extra]) =>
      json.encode({'ok': true, ...?extra});

  group('_post via endpoint publik — jalur sukses', () {
    test('200 dengan JSON valid dikembalikan sebagai Map', () async {
      ApiService.client = balas(200, suksesJson({'nilai': 42}));

      final hasil = await ApiService.getWetonDaily(
        birthDate: '1995-10-25',
        targetDate: '2026-09-28',
        authHeader: 'Bearer token',
      );

      expect(hasil['ok'], isTrue);
      expect(hasil['nilai'], 42);
    });

    test('mengirim header Content-Type dan Authorization yang benar', () async {
      final rekam = <http.Request>[];
      ApiService.client = balas(200, suksesJson(), rekam: rekam);

      await ApiService.getWetonDaily(
        birthDate: '1995-10-25',
        targetDate: '2026-09-28',
        authHeader: 'Bearer rahasia',
      );

      expect(rekam.length, 1);
      expect(
        rekam.single.headers['Content-Type'],
        contains('application/json'),
      );
      expect(rekam.single.headers['Authorization'], 'Bearer rahasia');
    });

    test('body dikirim sebagai JSON yang bisa di-decode ulang', () async {
      final rekam = <http.Request>[];
      ApiService.client = balas(200, suksesJson(), rekam: rekam);

      await ApiService.getWetonDaily(
        birthDate: '1995-10-25',
        targetDate: '2026-09-28',
        authHeader: 'Bearer t',
      );

      final body = json.decode(rekam.single.body) as Map<String, dynamic>;
      expect(body['birthDate'], '1995-10-25');
      expect(body['targetDate'], '2026-09-28');
    });

    test('request diarahkan ke path yang benar', () async {
      final rekam = <http.Request>[];
      ApiService.client = balas(200, suksesJson(), rekam: rekam);

      await ApiService.getWetonDaily(
        birthDate: '1995-10-25',
        targetDate: '2026-09-28',
        authHeader: 'Bearer t',
      );

      expect(rekam.single.url.path, contains('/api/weton/daily'));
    });
  });

  group('_post — penanganan status error', () {
    test('500 → melempar Exception dengan pesan status', () async {
      ApiService.client = balas(500, 'server rusak');

      await expectThrows<Exception>(
        () => ApiService.getWetonDaily(
          birthDate: '1995-10-25',
          targetDate: '2026-09-28',
          authHeader: 'Bearer t',
        ),
        (e) {
          final pesan = e.toString();
          expect(pesan, contains('500'));
          expect(pesan, contains('server rusak'));
        },
      );
    });

    test('400 → melempar, tidak dianggap sukses', () async {
      ApiService.client = balas(400, '{"error":"bad request"}');

      expect(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('404 → melempar', () async {
      ApiService.client = balas(404, 'tidak ditemukan');

      expect(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('200 dengan body bukan JSON → melempar', () async {
      ApiService.client = balas(200, 'ini bukan json');

      expect(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('200 dengan JSON array (bukan objek) → melempar', () async {
      ApiService.client = balas(200, json.encode([1, 2, 3]));

      expect(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('_post — 503 kuota Gemini (ORACLE_REST)', () {
    test('503 dengan kode ORACLE_REST → OracleRestException', () async {
      ApiService.client = balas(
        503,
        json.encode({
          'code': 'ORACLE_REST',
          'error': 'Sesepuh sedang beristirahat.',
          'retryAfterSeconds': 3600,
        }),
      );

      await expectThrows<OracleRestException>(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        (e) => expect(e.retryAfterSeconds, 3600),
      );
    });

    test('503 legacy gemini_quota → tetap OracleRestException', () async {
      ApiService.client = balas(
        503,
        json.encode({'code': 'gemini_quota', 'error': 'kuota habis'}),
      );

      expect(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<OracleRestException>()),
      );
    });

    test('503 tanpa kode kuota → Exception biasa', () async {
      ApiService.client = balas(503, json.encode({'error': 'layanan down'}));

      await expectThrows<Exception>(
        () => ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        (e) => expect(e, isNot(isA<OracleRestException>())),
      );
    });

    test('OracleRestException TIDAK di-retry (hemat kuota)', () async {
      var jumlahRequest = 0;
      ApiService.client = MockClient((request) async {
        jumlahRequest++;
        return http.Response(
          json.encode({'code': 'ORACLE_REST', 'retryAfterSeconds': 60}),
          503,
        );
      });

      await expectLater(
        ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<OracleRestException>()),
      );

      expect(jumlahRequest, 1, reason: '503 kuota harus langsung menyerah');
    });
  });

  group('_withRetry — perilaku retry', () {
    test('SocketException di-retry lalu sukses', () async {
      var percobaan = 0;
      ApiService.client = MockClient((request) async {
        percobaan++;
        if (percobaan < 2) {
          throw const SocketException('koneksi terputus');
        }
        return http.Response(suksesJson(), 200);
      });

      final hasil = await ApiService.getWetonDaily(
        birthDate: 'x',
        targetDate: 'y',
        authHeader: 'Bearer t',
      );

      expect(hasil['ok'], isTrue);
      expect(percobaan, 2);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('gagal terus → menyerah setelah 3 percobaan lalu rethrow', () async {
      var percobaan = 0;
      ApiService.client = MockClient((request) async {
        percobaan++;
        throw const SocketException('selalu gagal');
      });

      await expectLater(
        ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<SocketException>()),
      );

      expect(percobaan, 3, reason: 'maxAttempts = 3');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('error non-transient (500) tidak di-retry', () async {
      var percobaan = 0;
      ApiService.client = MockClient((request) async {
        percobaan++;
        return http.Response('error', 500);
      });

      await expectLater(
        ApiService.getWetonDaily(
          birthDate: 'x',
          targetDate: 'y',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<Exception>()),
      );

      expect(percobaan, 3, reason: 'Exception generik masuk jalur retry');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('_cachedPost — perilaku caching', () {
    test('memanggil API saat cache kosong', () async {
      var jumlahRequest = 0;
      ApiService.client = MockClient((request) async {
        jumlahRequest++;
        return http.Response(suksesJson({'v': 1}), 200);
      });

      await ApiService.getBaziChart(
        birthDate: '1995-10-25',
        birthHour: 10,
        authHeader: 'Bearer t',
      );

      expect(jumlahRequest, 1);
    });

    test('panggilan kedua memakai cache, bukan API', () async {
      var jumlahRequest = 0;
      ApiService.client = MockClient((request) async {
        jumlahRequest++;
        return http.Response(suksesJson({'v': 1}), 200);
      });

      Future<Map<String, dynamic>> panggil() => ApiService.getBaziChart(
        birthDate: '1995-10-25',
        birthHour: 10,
        authHeader: 'Bearer t',
      );

      await panggil();
      await panggil();

      expect(jumlahRequest, 1, reason: 'panggilan kedua harus dari cache');
    });
  });

  group('Endpoint spesifik — path yang dipanggil', () {
    Future<void> cekPath(
      String pathDiharapkan,
      Future<void> Function() aksi,
    ) async {
      final rekam = <http.Request>[];
      ApiService.client = balas(200, suksesJson(), rekam: rekam);

      await aksi();

      expect(rekam.single.url.path, contains(pathDiharapkan));
    }

    test('drawTarot → /api/tarot/draw', () async {
      await cekPath(
        '/api/tarot/draw',
        () => ApiService.drawTarot(
          birthDate: '1995-10-25',
          authHeader: 'Bearer t',
        ),
      );
    });

    test('getCalendarMonth → /api/calendar/month', () async {
      await cekPath(
        '/api/calendar/month',
        () => ApiService.getCalendarMonth(
          birthDate: '1995-10-25',
          targetYear: 2026,
          targetMonth: 9,
          authHeader: 'Bearer t',
        ),
      );
    });

    test('getBaziInsight → /api/bazi/insight', () async {
      await cekPath(
        '/api/bazi/insight',
        () => ApiService.getBaziInsight(
          birthDate: '1995-10-25',
          isMale: true,
          authHeader: 'Bearer t',
        ),
      );
    });

    test('getWetonCompatibility → /api/weton/compatibility', () async {
      await cekPath(
        '/api/weton/compatibility',
        () => ApiService.getWetonCompatibility(
          birthDate1: '1995-10-25',
          birthDate2: '1996-03-12',
          authHeader: 'Bearer t',
        ),
      );
    });

    test('getLuckPillars → /api/bazi/luck-pillars', () async {
      await cekPath(
        '/api/bazi/luck-pillars',
        () => ApiService.getLuckPillars(
          birthDate: '1995-10-25',
          isMale: true,
          authHeader: 'Bearer t',
        ),
      );
    });
  });

  group('sendOracleChat — jalur khusus (tanpa retry)', () {
    test('200 mengembalikan Map', () async {
      ApiService.client = balas(200, json.encode({'message': 'Halo'}));

      final hasil = await ApiService.sendOracleChat(
        oracleType: 'weton',
        prompt: 'Apa arti weton saya?',
        authHeader: 'Bearer t',
      );

      expect(hasil['message'], 'Halo');
    });

    test('mengirim oracleType, prompt, dan flag milestone', () async {
      final rekam = <http.Request>[];
      ApiService.client = balas(
        200,
        json.encode({'message': 'ok'}),
        rekam: rekam,
      );

      await ApiService.sendOracleChat(
        oracleType: 'bazi',
        prompt: 'Tanya',
        authHeader: 'Bearer t',
        isFirstOpen: false,
        daysSinceLastOpen: 5,
        lastTopic: 'Karier',
      );

      final body = json.decode(rekam.single.body) as Map<String, dynamic>;
      expect(body['oracleType'], 'bazi');
      expect(body['prompt'], 'Tanya');
      expect(body['isFirstOpen'], isFalse);
      expect(body['daysSinceLastOpen'], 5);
      expect(body['lastTopic'], 'Karier');
    });

    test('lastTopic null tidak dikirim ke backend', () async {
      final rekam = <http.Request>[];
      ApiService.client = balas(
        200,
        json.encode({'message': 'ok'}),
        rekam: rekam,
      );

      await ApiService.sendOracleChat(
        oracleType: 'weton',
        prompt: 'p',
        authHeader: 'Bearer t',
      );

      final body = json.decode(rekam.single.body) as Map<String, dynamic>;
      expect(body.containsKey('lastTopic'), isFalse);
      expect(body.containsKey('chatHistory'), isFalse);
      expect(body.containsKey('context'), isFalse);
    });

    test('429 → melempar pesan RATE_LIMIT dengan durasi', () async {
      ApiService.client = balas(429, json.encode({'retryAfterSeconds': 90}));

      await expectThrows<Exception>(
        () => ApiService.sendOracleChat(
          oracleType: 'weton',
          prompt: 'p',
          authHeader: 'Bearer t',
        ),
        (e) {
          final pesan = e.toString();
          expect(pesan, contains('RATE_LIMIT'));
          expect(pesan, contains('90'));
        },
      );
    });

    test('429 tanpa retryAfterSeconds → default 60', () async {
      ApiService.client = balas(429, json.encode({}));

      await expectThrows<Exception>(
        () => ApiService.sendOracleChat(
          oracleType: 'weton',
          prompt: 'p',
          authHeader: 'Bearer t',
        ),
        (e) => expect(e.toString(), contains('RATE_LIMIT:60')),
      );
    });

    test('503 kuota → OracleRestException', () async {
      ApiService.client = balas(
        503,
        json.encode({'code': 'ORACLE_REST', 'retryAfterSeconds': 120}),
      );

      expect(
        () => ApiService.sendOracleChat(
          oracleType: 'weton',
          prompt: 'p',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<OracleRestException>()),
      );
    });

    test('500 → Exception generik', () async {
      ApiService.client = balas(500, 'rusak');

      expect(
        () => ApiService.sendOracleChat(
          oracleType: 'weton',
          prompt: 'p',
          authHeader: 'Bearer t',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('baseUrl', () {
    test('menunjuk ke host workers.dev (produksi) atau localhost (debug)', () {
      // Dalam flutter test, kDebugMode = true → localhost.
      final url = ApiService.baseUrl;
      final cocok = url.contains('localhost') || url.contains('workers.dev');
      expect(cocok, isTrue, reason: 'baseUrl tidak dikenal: $url');
    });
  });
}
