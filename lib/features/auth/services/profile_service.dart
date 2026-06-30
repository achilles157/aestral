import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/utils/weton_utils.dart';
import 'auth_service.dart';

final profileProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref);
});

class ProfileService {
  final Ref _ref;

  // Temporary in-memory cache for guest profile (cleared on reload/refresh)
  Map<String, dynamic>? _temporaryGuestProfile;

  ProfileService(this._ref);

  bool get isFirebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveProfile({
    required DateTime dob,
    required double latitude,
    required double longitude,
    required WetonInfo weton,
  }) async {
    final session = _ref.read(authProvider);
    if (session == null) return false;

    // Construct flat profile JSON as specified in Arsitektur Backend
    final Map<String, dynamic> profileData = {
      'biometric_anchor': {
        'dob_utc_ms': dob.millisecondsSinceEpoch,
        'coordinates': {
          'lat': latitude,
          'lng': longitude,
        }
      },
      'architectural_pillars': {
        'weton': weton.toJson(),
      }
    };

    try {
      if (isFirebaseAvailable && !session.isMock) {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(session.uid)
            .set(profileData, SetOptions(merge: true));
        debugPrint("Profile successfully saved to Firestore for UID: ${session.uid}");
        return true;
      } else {
        // Fallback: save to temporary in-memory cache for guest
        _temporaryGuestProfile = profileData;
        debugPrint("Profile successfully saved to temporary memory for Tamu: ${session.uid}");
        return true;
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
    }
    return false;
  }

  Future<Map<String, dynamic>?> loadProfile() async {
    final session = _ref.read(authProvider);
    if (session == null) return null;

    try {
      if (isFirebaseAvailable && !session.isMock) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(session.uid)
            .get();
        if (doc.exists) {
          return doc.data();
        }
      } else {
        // Fallback: read from temporary in-memory cache for guest
        return _temporaryGuestProfile;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
    return null;
  }
}
