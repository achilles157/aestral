import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _productionUrl =
      'https://aestral-backend.aestral-backend.workers.dev';
  static const String _localUrl = 'http://localhost:8787';

  static String get baseUrl => kDebugMode ? _localUrl : _productionUrl;

  // ── Retry logic ─────────────────────────────────────────────────────────────

  static Future<T> _withRetry<T>(Future<T> Function() call) async {
    const maxAttempts = 3;
    const baseDelay = Duration(seconds: 1);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await call();
      } on SocketException catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('ApiService: SocketException ($attempt/$maxAttempts): $e');
      } on TimeoutException catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('ApiService: TimeoutException ($attempt/$maxAttempts): $e');
      } on HttpException catch (e) {
        if (attempt == maxAttempts) rethrow;
        debugPrint('ApiService: HttpException ($attempt/$maxAttempts): $e');
      }
      await Future<void>.delayed(baseDelay * (1 << (attempt - 1)));
    }
    throw StateError('_withRetry: exhausted attempts');
  }

  // ── Shared POST helper ────────────────────────────────────────────────────

  /// POST helper used by all endpoints except [sendOracleChat].
  /// Handles headers, timeout, status validation, JSON decode, and retry.
  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    required String authHeader,
    int timeoutSeconds = 10,
  }) {
    final url = Uri.parse('$baseUrl/$path');
    return _withRetry(() async {
      try {
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': authHeader,
              },
              body: json.encode(body),
            )
            .timeout(Duration(seconds: timeoutSeconds));

        if (response.statusCode != 200) {
          throw Exception('Status ${response.statusCode}: ${response.body}');
        }
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) return data;
        throw Exception('Invalid response format');
      } catch (e) {
        debugPrint('ApiService.$path error: $e');
        rethrow;
      }
    });
  }

  // ── Endpoints ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> drawTarot({
    required String birthDate,
    String? pangarasan,
    String? drawType,
    int? mangsaId,
    required String authHeader,
  }) =>
      _post('api/tarot/draw', {
        'birthDate': birthDate,
        if (pangarasan != null) 'pangarasan': pangarasan,
        if (drawType != null) 'drawType': drawType,
        if (mangsaId != null) 'mangsaId': mangsaId,
      }, authHeader: authHeader);

  static Future<Map<String, dynamic>> getWetonDaily({
    required String birthDate,
    String? targetDate,
    required String authHeader,
  }) =>
      _post('api/weton/daily', {
        'birthDate': birthDate,
        if (targetDate != null) 'targetDate': targetDate,
      }, authHeader: authHeader);

  static Future<Map<String, dynamic>> getCalendarMonth({
    required String birthDate,
    required int targetYear,
    required int targetMonth,
    required String authHeader,
  }) =>
      _post('api/calendar/month', {
        'birthDate': birthDate,
        'targetYear': targetYear,
        'targetMonth': targetMonth,
      }, authHeader: authHeader);

  static Future<Map<String, dynamic>> generateAiChat({
    required String prompt,
    required String authHeader,
    Map<String, dynamic>? aiContext,
  }) =>
      _post('api/chat', {
        'prompt': prompt,
        if (aiContext != null) ...aiContext,
      }, authHeader: authHeader, timeoutSeconds: 30);

  static Future<Map<String, dynamic>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String authHeader,
    Map<String, dynamic>? wetonContext,
  }) =>
      _post('api/tarot/reading', {
        'cards': cards,
        if (wetonContext != null) ...wetonContext,
      }, authHeader: authHeader, timeoutSeconds: 30);

  static Future<Map<String, dynamic>> getWetonCompatibility({
    required String birthDate1,
    required String birthDate2,
    required String authHeader,
  }) =>
      _post('api/weton/compatibility', {
        'birthDate1': birthDate1,
        'birthDate2': birthDate2,
      }, authHeader: authHeader);

  static Future<Map<String, dynamic>> getBaziChart({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    required String authHeader,
  }) =>
      _post('api/bazi/chart', {
        'birthDate': birthDate,
        if (birthHour != null) 'birthHour': birthHour,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }, authHeader: authHeader);

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
  }) =>
      _post('api/bazi/insight', {
        'birthDate': birthDate,
        if (birthHour != null) 'birthHour': birthHour,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (prompt != null) 'prompt': prompt,
        if (dayMasterArketipe != null) 'dayMasterArketipe': dayMasterArketipe,
        if (isMale != null) 'isMale': isMale,
        if (currentAge != null) 'currentAge': currentAge,
      }, authHeader: authHeader, timeoutSeconds: 30);

  /// POST /api/oracle/chat — NO retry intentional: Oracle calls are expensive;
  /// retrying wastes rate limit budget (3x consumption, up to 105s wait).
  static Future<Map<String, dynamic>> sendOracleChat({
    required String oracleType,
    required String prompt,
    required String authHeader,
    List<Map<String, dynamic>>? chatHistory,
    bool isFirstOpen = false,
    int daysSinceLastOpen = 0,
    String? lastTopic,
    Map<String, dynamic>? context,
  }) async {
    final url = Uri.parse('$baseUrl/api/oracle/chat');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authHeader,
            },
            body: json.encode({
              'oracleType': oracleType,
              'prompt': prompt,
              if (chatHistory != null && chatHistory.isNotEmpty)
                'chatHistory': chatHistory,
              'isFirstOpen': isFirstOpen,
              'daysSinceLastOpen': daysSinceLastOpen,
              if (lastTopic != null) 'lastTopic': lastTopic,
              if (context != null) 'context': context,
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 429) {
        final data = json.decode(response.body);
        throw Exception('RATE_LIMIT:${data['retryAfterSeconds'] ?? 60}');
      }
      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('ApiService.sendOracleChat error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLuckPillars({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    required bool isMale,
    required String authHeader,
  }) =>
      _post('api/bazi/luck-pillars', {
        'birthDate': birthDate,
        if (birthHour != null) 'birthHour': birthHour,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isMale': isMale,
      }, authHeader: authHeader, timeoutSeconds: 30);
}
