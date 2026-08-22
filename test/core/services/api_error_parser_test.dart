import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:aestral/core/errors/oracle_rest_exception.dart';
import 'package:aestral/core/services/api_error_parser.dart';

http.Response _resp503(Map<String, dynamic> body) =>
    http.Response(json.encode(body), 503);

void main() {
  group('parseServiceError', () {
    test('mengembalikan null untuk status selain 503', () {
      final resp = http.Response('{}', 200);
      expect(parseServiceError(resp), isNull);
    });

    test('mengembalikan OracleRestException untuk code ORACLE_REST', () {
      final resp = _resp503({
        'code': 'ORACLE_REST',
        'error': 'Oracle sedang beristirahat.',
        'retryAfterSeconds': 7200,
      });

      final err = parseServiceError(resp);
      expect(err, isA<OracleRestException>());
      final oracleErr = err! as OracleRestException;
      expect(oracleErr.message, 'Oracle sedang beristirahat.');
      expect(oracleErr.retryAfterSeconds, 7200);
    });

    test('mendukung kode legacy gemini_quota & gemini_daily_quota', () {
      for (final code in ['gemini_quota', 'gemini_daily_quota']) {
        final err = parseServiceError(
          _resp503({'code': code, 'error': 'Kuota habis'}),
        );
        expect(err, isA<OracleRestException>(), reason: 'kode $code');
      }
    });

    test('memakai retryAfterSeconds default 0 saat tidak ada', () {
      final err =
          parseServiceError(
                _resp503({'code': 'ORACLE_REST', 'error': 'Istirahat'}),
              )!
              as OracleRestException;
      expect(err.retryAfterSeconds, 0);
    });

    test('fallback pesan default saat error kosong', () {
      final err =
          parseServiceError(_resp503({'code': 'ORACLE_REST'}))!
              as OracleRestException;
      expect(err.message, 'Kapasitas kosmis hari ini sudah penuh.');
    });

    test('503 tanpa kode kuota → Exception biasa dengan pesan backend', () {
      final err = parseServiceError(_resp503({'error': 'Maintenance'}));
      expect(err, isA<Exception>());
      expect(err, isNot(isA<OracleRestException>()));
      expect(err.toString(), contains('Maintenance'));
    });

    test('503 dengan body bukan JSON → Exception fallback, tidak crash', () {
      final err = parseServiceError(http.Response('<html>oops</html>', 503));
      expect(err, isA<Exception>());
      expect(err, isNot(isA<OracleRestException>()));
    });
  });
}
