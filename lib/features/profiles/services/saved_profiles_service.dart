import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_profile.dart';

/// Layanan penyimpanan profil orang tersimpan di SharedPreferences.
/// Maksimal [_maxProfiles] profil. Tersedia untuk semua user (guest + logged-in).
class SavedProfilesService {
  static const _key = 'aestral_saved_profiles';
  static const _maxProfiles = 10;

  static Future<List<SavedProfile>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(SavedProfile.fromJson)
          .toList();
    } catch (e) {
      debugPrint('SavedProfilesService.load error: $e');
      return [];
    }
  }

  static Future<void> save(SavedProfile profile) async {
    try {
      final profiles = await load();
      // Hindari duplikat nama + tanggal yang sama
      final isDupe = profiles.any((p) =>
          p.name.toLowerCase() == profile.name.toLowerCase() &&
          p.birthDate == profile.birthDate);
      if (isDupe) return;

      profiles.insert(0, profile);
      final trimmed = profiles.length > _maxProfiles
          ? profiles.sublist(0, _maxProfiles)
          : profiles;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        json.encode(trimmed.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('SavedProfilesService.save error: $e');
    }
  }

  static Future<void> delete(String id) async {
    try {
      final profiles = await load();
      profiles.removeWhere((p) => p.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        json.encode(profiles.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('SavedProfilesService.delete error: $e');
    }
  }
}
