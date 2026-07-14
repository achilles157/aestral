import '../utils/weton_utils.dart';

/// Typed model for a user's birth profile.
/// Single source of truth shared by Weton, Ba Zi, Tarot, and Dashboard.
class BirthProfile {
  /// Date of birth — date only, time component is always midnight UTC.
  final DateTime? dobDate;

  /// Birth hour (0–23). Stored separately from [dobDate].
  final int? birthHour;

  final double? latitude;
  final double? longitude;

  /// Display label for the city (e.g. "Jakarta"). Not used for calculation.
  final String? cityName;

  /// 'male' | 'female' | null
  final String? gender;

  /// Cached Weton computed from [dobDate]. Null if [dobDate] is null.
  final WetonInfo? weton;

  const BirthProfile({
    this.dobDate,
    this.birthHour,
    this.latitude,
    this.longitude,
    this.cityName,
    this.gender,
    this.weton,
  });

  bool get hasIdentity => dobDate != null;
  bool get hasLocation => latitude != null && longitude != null;

  BirthProfile copyWith({
    DateTime? dobDate,
    Object? birthHour = _sentinel,
    double? latitude,
    double? longitude,
    Object? cityName = _sentinel,
    Object? gender = _sentinel,
    Object? weton = _sentinel,
  }) {
    return BirthProfile(
      dobDate: dobDate ?? this.dobDate,
      birthHour: birthHour == _sentinel ? this.birthHour : birthHour as int?,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName == _sentinel ? this.cityName : cityName as String?,
      gender: gender == _sentinel ? this.gender : gender as String?,
      weton: weton == _sentinel ? this.weton : weton as WetonInfo?,
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    final anchor = json['biometric_anchor'] as Map<String, dynamic>?;
    final coords = anchor?['coordinates'] as Map<String, dynamic>?;

    DateTime? dob;
    final ms = anchor?['dob_utc_ms'] as int?;
    if (ms != null) {
      final raw = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      // Normalise to UTC midnight — strip any embedded time
      dob = DateTime.utc(raw.year, raw.month, raw.day);
    }

    WetonInfo? weton;
    if (dob != null) {
      // WetonUtils.calculateWeton is pure and deterministic — always recompute
      // from dob so we never silently return stale cached data.
      weton = WetonUtils.calculateWeton(dob);
    }

    return BirthProfile(
      dobDate: dob,
      birthHour: anchor?['birth_hour'] as int?,
      latitude: (coords?['lat'] as num?)?.toDouble(),
      longitude: (coords?['lng'] as num?)?.toDouble(),
      cityName: anchor?['city_name'] as String?,
      gender: anchor?['gender'] as String?,
      weton: weton,
    );
  }

  /// Serialises to the Firestore document shape.
  /// Uses [SetOptions(merge: true)] on write so only present fields are touched.
  Map<String, dynamic> toFirestoreDoc() {
    final anchor = <String, dynamic>{};
    if (dobDate != null) {
      anchor['dob_utc_ms'] = DateTime.utc(
        dobDate!.year,
        dobDate!.month,
        dobDate!.day,
      ).millisecondsSinceEpoch;
    }
    if (birthHour != null) anchor['birth_hour'] = birthHour;
    if (latitude != null && longitude != null) {
      anchor['coordinates'] = {'lat': latitude, 'lng': longitude};
    }
    if (cityName != null) anchor['city_name'] = cityName;
    if (gender != null) anchor['gender'] = gender;

    final doc = <String, dynamic>{};
    if (anchor.isNotEmpty) doc['biometric_anchor'] = anchor;
    if (weton != null) {
      doc['architectural_pillars'] = {'weton': weton!.toJson()};
    }
    return doc;
  }

  static const Object _sentinel = Object();
}
