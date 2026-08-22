import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/oracle_rest_exception.dart';

/// Kode error backend saat kuota Gemini harian habis (503).
const oracleRestCode = 'ORACLE_REST';

/// Kode legacy yang masih didukung untuk kompatibilitas.
const _legacyCodes = {'gemini_quota', 'gemini_daily_quota'};

/// Parse respons 503 backend AESTRAL menjadi exception yang bisa di-throw.
///
/// - 503 + code `ORACLE_REST` (atau kode legacy) → [OracleRestException]
///   (membawa pesan ramah + `retryAfterSeconds` untuk hitung mundur UI).
/// - 503 tanpa kode kuota → [Exception] dengan pesan backend bila ada.
/// - Selain 503 → `null` (bukan error layanan, biarkan flow existing).
///
/// Dipisahkan ke fungsi pure agar unit-testable tanpa HTTP server.
Exception? parseServiceError(http.Response response) {
  if (response.statusCode != 503) return null;

  String? code;
  String? msg;
  int retryAfter = 0;
  try {
    final body = json.decode(response.body) as Map<String, dynamic>;
    code = body['code'] as String?;
    msg = body['error'] as String?;
    retryAfter = int.tryParse('${body['retryAfterSeconds']}') ?? 0;
  } catch (_) {
    // Body bukan JSON — fallback ke pesan generik di bawah.
  }

  if (code == oracleRestCode || _legacyCodes.contains(code)) {
    return OracleRestException(
      msg ?? 'Kapasitas kosmis hari ini sudah penuh.',
      retryAfterSeconds: retryAfter,
    );
  }
  return Exception(msg ?? 'Layanan tidak tersedia saat ini.');
}
