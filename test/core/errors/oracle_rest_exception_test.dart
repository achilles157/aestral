import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/errors/oracle_rest_exception.dart';

void main() {
  group('OracleRestException', () {
    test('friendlyMessage memakai pesan asli saat ada', () {
      const e = OracleRestException('Oracle sedang beristirahat.');
      expect(e.friendlyMessage, 'Oracle sedang beristirahat.');
    });

    test('friendlyMessage fallback saat pesan kosong', () {
      const e = OracleRestException('');
      expect(e.friendlyMessage, contains('beristirahat'));
    });

    test('countdownLabel 0 detik → kembali besok', () {
      const e = OracleRestException('x', retryAfterSeconds: 0);
      expect(e.countdownLabel, 'kembali besok');
    });

    test('countdownLabel jam + menit', () {
      const e = OracleRestException('x', retryAfterSeconds: 5 * 3600 + 12 * 60);
      expect(e.countdownLabel, '5 jam 12 menit');
    });

    test('countdownLabel hanya jam', () {
      const e = OracleRestException('x', retryAfterSeconds: 3 * 3600);
      expect(e.countdownLabel, '3 jam');
    });

    test('countdownLabel menit + detik', () {
      const e = OracleRestException('x', retryAfterSeconds: 45 * 60 + 10);
      expect(e.countdownLabel, '45 menit 10 detik');
    });

    test('countdownLabel hanya detik', () {
      const e = OracleRestException('x', retryAfterSeconds: 30);
      expect(e.countdownLabel, '30 detik');
    });

    test('toString mengandung pesan ramah', () {
      const e = OracleRestException('Pesan ramah.');
      expect(e.toString(), contains('Pesan ramah.'));
    });
  });
}
