import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Default to production domain, but can be overridden or fallback to local
  static const String _productionUrl = 'https://aestral-backend.aestral-backend.workers.dev';
  static const String _localUrl = 'http://localhost:8787';

  static String get baseUrl => kDebugMode ? _localUrl : _productionUrl;

  /// Calls POST /api/tarot/draw with the JSON payload.
  static Future<Map<String, dynamic>> drawTarot({
    required String birthDate,
    String? pangarasan,
    String? drawType,
    int? mangsaId,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/tarot/draw');
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
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('ApiService.drawTarot error (falling back): $e');
      rethrow;
    }
  }

  /// Calls POST /api/weton/daily with the JSON payload.
  static Future<Map<String, dynamic>> getWetonDaily({
    required String birthDate,
    String? targetDate,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/weton/daily');
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
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('ApiService.getWetonDaily error (falling back): $e');
      rethrow;
    }
  }

  /// Calls POST /api/calendar/month with the JSON payload.
  static Future<Map<String, dynamic>> getCalendarMonth({
    required String birthDate,
    required int targetYear,
    required int targetMonth,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/calendar/month');
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
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('ApiService.getCalendarMonth error: $e');
      rethrow;
    }
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
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('ApiService.generateAiChat error: $e');
      rethrow;
    }
  }

  /// Calls POST /api/tarot/reading — kirim 3 kartu ke Oracle Tarot AI (Gemini).
  /// Mengembalikan narasi Barnum per-kartu + konklusi synthesis benang merah.
  static Future<Map<String, dynamic>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String authHeader,
    Map<String, dynamic>? wetonContext,
  }) async {
    final url = Uri.parse('$baseUrl/api/tarot/reading');
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
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('ApiService.generateTarotReading error: $e');
      rethrow;
    }
  }

  /// Calls POST /api/bazi/chart — kalkulasi 4 Pilar Ba Zi dari backend.
  /// Menerima koordinat untuk koreksi True Solar Time (TST).
  static Future<Map<String, dynamic>> getBaziChart({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/bazi/chart');
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
  }

  /// Calls POST /api/bazi/insight — kalkulasi + narasi AI Oracle Ba Zi via Gemini.
  static Future<Map<String, dynamic>> getBaziInsight({
    required String birthDate,
    int? birthHour,
    double? latitude,
    double? longitude,
    String? prompt,
    String? dayMasterArketipe,
    required String authHeader,
  }) async {
    final url = Uri.parse('$baseUrl/api/bazi/insight');
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
  }
}
