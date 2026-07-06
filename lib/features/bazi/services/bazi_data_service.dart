import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads bazi-stems.json — 10 Heavenly Stems (天干) reference data.
final baziStemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await rootBundle.loadString('assets/bazi/bazi-stems.json');
  return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
});

/// Loads bazi-branches.json — 12 Earthly Branches (地支) with hidden stems.
final baziBranchesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await rootBundle.loadString('assets/bazi/bazi-branches.json');
  return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
});

/// Loads bazi-pillars.json — 60 sexagenary cycle (六十甲子) pillar descriptions.
final baziPillarsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await rootBundle.loadString('assets/bazi/bazi-pillars.json');
  return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
});

/// Loads 10day-masters.json — Day Master personality profiles.
final baziDayMastersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await rootBundle.loadString('assets/bazi/10day-masters.json');
  return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
});

/// Loads 10gods.json — Ten Gods (十神) archetype profiles.
final baziGodsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await rootBundle.loadString('assets/bazi/10gods.json');
  return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
});

/// Convenience extension: find an entry by its "id" field.
extension BaziListX on List<Map<String, dynamic>> {
  Map<String, dynamic>? findById(String id) {
    try {
      return firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }
}
