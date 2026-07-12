import 'package:intl/intl.dart';

/// Model profil orang tersimpan untuk keperluan kompatibilitas.
class SavedProfile {
  final String id;
  final String name;
  final DateTime birthDate;
  final DateTime addedAt;

  const SavedProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.addedAt,
  });

  String get formattedBirthDate =>
      DateFormat('d MMM yyyy', 'id_ID').format(birthDate);

  String get birthDateIso =>
      DateFormat('yyyy-MM-dd').format(birthDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthDate': birthDate.millisecondsSinceEpoch,
        'addedAt': addedAt.millisecondsSinceEpoch,
      };

  factory SavedProfile.fromJson(Map<String, dynamic> j) => SavedProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        birthDate:
            DateTime.fromMillisecondsSinceEpoch(j['birthDate'] as int),
        addedAt:
            DateTime.fromMillisecondsSinceEpoch(j['addedAt'] as int),
      );
}
