import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Default to production domain, but can be overridden or fallback to local
  static const String _productionUrl = 'https://aestral-backend.aestral-backend.workers.dev';
  static const String _localUrl = 'http://localhost:8787';

  static String get baseUrl => kDebugMode ? _localUrl : _productionUrl;

  // ── Retry logic ─────────────────────────────────────────────────────────────

  /// Wraps an HTTP call with exponential backoff retry (max 3 attempts).
  ///
  /// Retries only on transient network errors:
  /// - [SocketException] — no connectivity / DNS failure
  /// - [TimeoutException] — server too slow
  /// - [HttpException] — low-level HTTP transport error
  ///
  /// Does NOT retry on application-level errors (4xx status codes) since those
  /// indicate a bad request that won't succeed on retry.
  static Future<T> _withRetry<T>(Future<T> Function() call) async {
    const maxAttempts = 3;
    const baseDelay = Duration(seconds: 1);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await call();
      } on SocketException catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('ApiService: SocketException (attempt $attempt/$maxAttempts): $e — retrying...');
      } on TimeoutException catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('ApiService: TimeoutException (attempt $attempt/$maxAttempts): $e — retrying...');
      } on HttpException catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('ApiService: HttpException (attempt $attempt/$maxAttempts): $e — retrying...');
      }
      // Exponential backoff: 1s, 2s, 4s
      await Future<void>.delayed(baseDelay * (1 << (attempt - 1)));
    }
    // Unreachable, but required by Dart's type system
    throw StateError('_withRetry: exhausted attempts without result or rethrow');
  }

  // ── Endpoints ────────────────────────────────────────────────────────────────

  /// Calls POST /api/tarot/draw with the JSON payload.
  static Future<Map<String, dynamic>> drawTarot({
    required String birthDate,
    String? pangarasan,
    String? drawType,
    int? mangsaId,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/tarot/draw');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate': birthDate,
            if (pangarasan != null) 'pangarasan': pangarasan,
            if (drawType != null) 'drawType': drawType,
            if (mangsaId != null) 'mangsaId': mangsaId,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.drawTarot error (falling back): $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/weton/daily with the JSON payload.
  static Future<Map<String, dynamic>> getWetonDaily({
    required String birthDate,
    String? targetDate,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/weton/daily');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate': birthDate,
            if (targetDate != null) 'targetDate': targetDate,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.getWetonDaily error (falling back): $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/calendar/month with the JSON payload.
  static Future<Map<String, dynamic>> getCalendarMonth({
    required String birthDate,
    required int targetYear,
    required int targetMonth,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/calendar/month');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate': birthDate,
            'targetYear': targetYear,
            'targetMonth': targetMonth,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.getCalendarMonth error: $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/chat — kirim pertanyaan ke Aestral Oracle (Gemini AI).
  /// [aiContext] adalah map opsional berisi data weton/wuku/tarot yang
  /// akan disertakan sebagai konteks astrologi untuk Gemini.
  static Future<Map<String, dynamic>> generateAiChat({
    required String prompt,
    required String authHeader,
    Map<String, dynamic>? aiContext,
  }) async {
    final url = Uri.parse('$baseUrl/api/chat');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'prompt': prompt,
            if (aiContext != null) ...aiContext,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.generateAiChat error: $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/tarot/reading — kirim 3 kartu ke Oracle Tarot AI (Gemini).
  /// Mengembalikan narasi Barnum per-kartu + konklusi synthesis benang merah.
  static Future<Map<String, dynamic>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String authHeader,
    Map<String, dynamic>? wetonContext,
  }) async {
    final url = Uri.parse('$baseUrl/api/tarot/reading');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'cards': cards,
            if (wetonContext != null) ...wetonContext,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.generateTarotReading error: $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/weton/compatibility — hitung kompatibilitas dua weton.
  /// Hanya untuk registered user (bearer). Guest akan mendapat 403.
  static Future<Map<String, dynamic>> getWetonCompatibility({
    required String birthDate1,
    required String birthDate2,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/weton/compatibility');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate1': birthDate1,
            'birthDate2': birthDate2,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.getWetonCompatibility error: $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/bazi/chart — kalkulasi 4 Pilar Ba Zi dari backend.
  /// [latitude] diterima backend tapi belum dipakai dalam kalkulasi
  /// (reserved untuk koreksi Equation of Time di fase berikutnya).
  /// [longitude] dipakai untuk koreksi True Solar Time (TST) Pilar Jam.
  static Future<Map<String, dynamic>> getBaziChart({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/bazi/chart');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate': birthDate,
            if (birthHour != null) 'birthHour': birthHour,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.getBaziChart error: $e');
        rethrow;
      }
    });
  }

  /// Calls POST /api/bazi/insight — kalkulasi + narasi AI Oracle Ba Zi via Gemini.
  static Future<Map<String, dynamic>> getBaziInsight({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    String? prompt,
    String? dayMasterArketipe,
    bool? isMale,
    int? currentAge,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/bazi/insight');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate': birthDate,
            if (birthHour != null) 'birthHour': birthHour,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (prompt != null) 'prompt': prompt,
            if (dayMasterArketipe != null) 'dayMasterArketipe': dayMasterArketipe,
            if (isMale != null) 'isMale': isMale,
            if (currentAge != null) 'currentAge': currentAge,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.getBaziInsight error: $e');
        rethrow;
      }
    });
  }

  static Future<Map<String, dynamic>> getLuckPillars({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    required bool isMale,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/bazi/luck-pillars');
    return _withRetry(() async {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
          body: json.encode({
            'birthDate': birthDate,
            if (birthHour != null) 'birthHour': birthHour,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            'isMale': isMale,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.getLuckPillars error: $e');
        rethrow;
      }
    });
  }
}
