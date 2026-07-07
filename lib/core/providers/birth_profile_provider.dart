import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/birth_profile.dart';
import '../utils/weton_utils.dart';
import '../../features/auth/services/auth_service.dart';

/// Single source of truth for the user's birth profile.
/// All screens (Weton, Ba Zi, Tarot, Dashboard) read and write through this.
class BirthProfileNotifier extends AsyncNotifier<BirthProfile> {
  @override
  Future<BirthProfile> build() async {
    // Re-load whenever auth state changes
    ref.watch(authProvider);
    return _load();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<BirthProfile> _load() async {
    final session = ref.read(authProvider);
    if (session == null) return const BirthProfile();

    try {
      if (_firebaseAvailable && !session.isMock) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(session.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          return BirthProfile.fromJson(doc.data()!);
        }
      } else {
        final cached = _guestCache;
        if (cached != null) return BirthProfile.fromJson(cached);
      }
    } catch (e) {
      debugPrint('BirthProfileNotifier: load error — $e');
    }
    return const BirthProfile();
  }

  // ── Write helpers ─────────────────────────────────────────────────────────

  /// Merge-writes a partial Firestore doc. For guests, merges into in-memory cache.
  Future<void> _merge(Map<String, dynamic> partial) async {
    final session = ref.read(authProvider);
    if (session == null) return;

    try {
      if (_firebaseAvailable && !session.isMock) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(session.uid)
            .set(partial, SetOptions(merge: true));
      } else {
        // Deep-merge into guest cache
        _guestCache = _deepMerge(_guestCache ?? {}, partial);
      }
    } catch (e) {
      debugPrint('BirthProfileNotifier: merge error — $e');
    }
  }

  Map<String, dynamic> _deepMerge(
      Map<String, dynamic> base, Map<String, dynamic> overlay) {
    final result = Map<String, dynamic>.from(base);
    overlay.forEach((key, value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(
            result[key] as Map<String, dynamic>, value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  void _updateState(BirthProfile updated) {
    state = AsyncData(updated);
  }

  // ── Public save methods ───────────────────────────────────────────────────

  /// Save date of birth. Recomputes and caches [WetonInfo].
  Future<void> saveDob(DateTime date) async {
    final dobUtc = DateTime.utc(date.year, date.month, date.day);
    final weton  = WetonUtils.calculateWeton(dobUtc);
    await _merge({
      'biometric_anchor': {
        'dob_utc_ms': dobUtc.millisecondsSinceEpoch,
      },
      'architectural_pillars': {'weton': weton.toJson()},
    });
    final current = state.value ?? const BirthProfile();
    _updateState(current.copyWith(dobDate: dobUtc, weton: weton));
  }

  /// Save birth hour (0–23). Pass null to clear.
  Future<void> saveBirthHour(int? hour) async {
    await _merge({
      'biometric_anchor': {'birth_hour': hour},
    });
    final current = state.value ?? const BirthProfile();
    _updateState(current.copyWith(birthHour: hour));
  }

  /// Save location coordinates and optional display label.
  Future<void> saveLocation(
    double lat,
    double lng, {
    String? cityName,
  }) async {
    final anchor = <String, dynamic>{
      'coordinates': {'lat': lat, 'lng': lng},
    };
    if (cityName != null) anchor['city_name'] = cityName;
    await _merge({'biometric_anchor': anchor});
    final current = state.value ?? const BirthProfile();
    _updateState(current.copyWith(
      latitude: lat,
      longitude: lng,
      cityName: cityName ?? current.cityName,
    ));
  }

  /// Save gender ('male' | 'female'). Pass null to clear.
  Future<void> saveGender(String? gender) async {
    await _merge({
      'biometric_anchor': {'gender': gender},
    });
    final current = state.value ?? const BirthProfile();
    _updateState(current.copyWith(gender: gender));
  }

  /// Convenience: save all fields at once (used by Weton screen and Edit sheet).
  Future<void> saveAll({
    required DateTime dob,
    int?    birthHour,
    double? latitude,
    double? longitude,
    String? cityName,
    String? gender,
  }) async {
    final dobUtc = DateTime.utc(dob.year, dob.month, dob.day);
    final weton  = WetonUtils.calculateWeton(dobUtc);

    final anchor = <String, dynamic>{
      'dob_utc_ms': dobUtc.millisecondsSinceEpoch,
      if (birthHour != null) 'birth_hour': birthHour,
      if (latitude  != null && longitude != null)
        'coordinates': {'lat': latitude, 'lng': longitude},
      if (cityName  != null) 'city_name': cityName,
      if (gender    != null) 'gender':    gender,
    };

    await _merge({
      'biometric_anchor': anchor,
      'architectural_pillars': {'weton': weton.toJson()},
    });

    _updateState(BirthProfile(
      dobDate:   dobUtc,
      birthHour: birthHour,
      latitude:  latitude,
      longitude: longitude,
      cityName:  cityName,
      gender:    gender,
      weton:     weton,
    ));
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  bool get _firebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// In-memory cache for guest/offline users. Lives as long as the notifier.
  static Map<String, dynamic>? _guestCache;

  /// Seed the in-memory guest cache (e.g. from a migration or test helper).
  static void seedGuestCache(Map<String, dynamic> data) {
    _guestCache = _deepMergeStatic(_guestCache ?? {}, data);
  }

  static Map<String, dynamic> _deepMergeStatic(
      Map<String, dynamic> base, Map<String, dynamic> overlay) {
    final result = Map<String, dynamic>.from(base);
    overlay.forEach((key, value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] =
            _deepMergeStatic(result[key] as Map<String, dynamic>, value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}

final birthProfileProvider =
    AsyncNotifierProvider<BirthProfileNotifier, BirthProfile>(
  BirthProfileNotifier.new,
);
