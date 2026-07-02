import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Default to production domain, but can be overridden or fallback to local
  static const String _productionUrl = 'https://aestral-backend.falah.workers.dev';
  static const String _localUrl = 'http://localhost:8787';

  static String get baseUrl => kDebugMode ? _localUrl : _productionUrl;

  /// Calls POST /api/tarot/draw with the JSON payload.
  static Future<Map<String, dynamic>> drawTarot({
    required String birthDate,
    String? pangarasan,
    String? wuku,
    String? drawType,
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
          'pangarasan':? pangarasan,
          'wukuHariIni':? wuku,
          'drawType':? drawType,
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
          'targetDate':? targetDate,
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
}
