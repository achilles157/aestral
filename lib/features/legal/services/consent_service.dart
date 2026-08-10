import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consent_log.dart';

/// Provider untuk ConsentService.
final consentServiceProvider = Provider<ConsentService>(
  (ref) => ConsentService.instance,
);

/// Manajemen persetujuan PDP — simpan log konsen ke Firestore
/// (pengguna login) atau SharedPreferences (guest).
///
/// UU 27/2022 Pasal 20-24: consent harus eksplisit, tercatat,
/// dan bisa ditarik kembali.
class ConsentService {
  static final ConsentService instance = ConsentService._();

  ConsentService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  fba.FirebaseAuth get _auth => fba.FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'guest';

  /// Apakah user sudah login (bukan guest).
  bool get isSignedIn =>
      _auth.currentUser != null && !_auth.currentUser!.isAnonymous;

  // ── Kunci SharedPreferences ──────────────────────────────────────

  static const _prefsKeyPrefix = 'consent_';

  // ── Cek Status Consent ───────────────────────────────────────────

  /// Cek apakah consent sudah diberikan untuk tipe ini.
  /// Returns `true` jika versi terbaru sudah disetujui.
  Future<bool> hasConsented(ConsentType type) async {
    final latest = ConsentLog.latestVersions[type]!;
    if (isSignedIn) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('consents')
            .doc(type.name)
            .get();
        if (!doc.exists) return false;
        final stored = doc.data();
        final version = stored?['version'] as int? ?? 0;
        return version >= latest;
      } catch (_) {
        return false;
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsKeyPrefix${type.name}');
      if (raw == null) return false;
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        return ((map['version'] as int?) ?? 0) >= latest;
      } catch (_) {
        return false;
      }
    }
  }

  /// Cek semua consent yang wajib (dataProcessing + historyStorage).
  Future<bool> hasRequiredConsents() async {
    final results = await Future.wait([
      hasConsented(ConsentType.dataProcessing),
      hasConsented(ConsentType.historyStorage),
    ]);
    return results.every((r) => r);
  }

  // ── Simpan Consent ───────────────────────────────────────────────

  /// Catat persetujuan user (versi terbaru otomatis).
  Future<void> grant(ConsentType type) async {
    final now = DateTime.now();
    final version = ConsentLog.latestVersions[type]!;
    final log = ConsentLog(
      id: '${type.name}_$version',
      type: type,
      version: version,
      grantedAt: now,
    );

    if (isSignedIn) {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('consents')
          .doc(type.name)
          .set(log.toJson());
    }
    // Guest juga disimpan di SharedPreferences (selalu, sebagai cache lokal).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKeyPrefix${type.name}',
      json.encode(log.toJson()),
    );
  }

  /// Simpan semua consent sekaligus (dari onboarding).
  Future<void> grantAll({
    required bool dataProcessing,
    required bool historyStorage,
    required bool analytics,
  }) async {
    final futures = <Future<void>>[];
    if (dataProcessing) futures.add(grant(ConsentType.dataProcessing));
    if (historyStorage) futures.add(grant(ConsentType.historyStorage));
    if (analytics) futures.add(grant(ConsentType.analytics));
    await Future.wait(futures);
  }

  // ── Tarik Kembali (Revoke) ───────────────────────────────────────

  /// Tarik consent — hapus log persetujuan.
  Future<void> revoke(ConsentType type) async {
    if (isSignedIn) {
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('consents')
            .doc(type.name)
            .delete();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsKeyPrefix${type.name}');
  }

  /// Tarik SEMUA consent (dipanggil saat hapus akun).
  Future<void> revokeAll() async {
    await Future.wait(ConsentType.values.map((t) => revoke(t)));
  }

  // ── Dapatkan Semua Consent ───────────────────────────────────────

  /// Ambil semua log consent user saat ini.
  Future<List<ConsentLog>> getAll() async {
    if (isSignedIn) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('consents')
            .get();
        return snapshot.docs.map((d) => ConsentLog.fromJson(d.data())).toList();
      } catch (_) {
        return [];
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final results = <ConsentLog>[];
    for (final type in ConsentType.values) {
      final raw = prefs.getString('$_prefsKeyPrefix${type.name}');
      if (raw != null) {
        try {
          results.add(
            ConsentLog.fromJson(json.decode(raw) as Map<String, dynamic>),
          );
        } catch (_) {}
      }
    }
    return results;
  }
}
