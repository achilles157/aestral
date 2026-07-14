import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for Ba Zi data assets.
///
/// Provides typed access to all Ba Zi JSON assets in a single class,
/// following the same pattern as PranataMangsaRepository in the weton feature.
///
/// For Riverpod-based async loading, prefer the FutureProviders in
/// [bazi_data_service.dart]. Use this class when you need imperative
/// access (e.g. inside a NotifierProvider or a service class).
class BaziRepository {
  /// Loads the 10 Heavenly Stem (天干) profiles from bazi-stems.json.
  Future<List<Map<String, dynamic>>> getStems() async {
    final data = await rootBundle.loadString('assets/bazi/bazi-stems.json');
    return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Loads the 12 Earthly Branch (地支) profiles — including hidden stems —
  /// from bazi-branches.json.
  Future<List<Map<String, dynamic>>> getBranches() async {
    final data = await rootBundle.loadString('assets/bazi/bazi-branches.json');
    return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Loads the 60 sexagenary cycle (六十甲子) pillar descriptions
  /// from bazi-pillars.json.
  Future<List<Map<String, dynamic>>> getPillars() async {
    final data = await rootBundle.loadString('assets/bazi/bazi-pillars.json');
    return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Loads the 10 Day Master personality profiles from 10day-masters.json.
  Future<List<Map<String, dynamic>>> getDayMasters() async {
    final data = await rootBundle.loadString('assets/bazi/10day-masters.json');
    return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Loads the 10 Gods (十神) archetype profiles from 10gods.json.
  Future<List<Map<String, dynamic>>> getGods() async {
    final data = await rootBundle.loadString('assets/bazi/10gods.json');
    return (json.decode(data) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Convenience: find a Day Master entry by stem id (e.g. "geng").
  Future<Map<String, dynamic>?> getDayMasterById(String id) async {
    final list = await getDayMasters();
    try {
      return list.firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: find a pillar entry by slug id (e.g. "geng_chen").
  Future<Map<String, dynamic>?> getPillarById(String id) async {
    final list = await getPillars();
    try {
      return list.firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider exposing [BaziRepository] as a singleton.
final baziRepositoryProvider = Provider<BaziRepository>(
  (ref) => BaziRepository(),
);
