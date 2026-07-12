import 'package:intl/intl.dart';

/// Hasil satu hari yang lolos scoring Hari Baik.
class HariBaikResult {
  final DateTime date;
  final Map<String, dynamic> dayData;
  final int score;
  final String label; // 'ekspansi' | 'stabil'
  final List<String> reasons; // alasan positif singkat

  const HariBaikResult({
    required this.date,
    required this.dayData,
    required this.score,
    required this.label,
    required this.reasons,
  });

  String get wetonHariIni => dayData['weton_hari_ini'] as String? ?? '';
  String get wuku => dayData['wuku'] as String? ?? '';
  int get neptu => dayData['neptu'] as int? ?? 0;
  String get dateForApi => DateFormat('yyyy-MM-dd').format(date);

  String get formattedDate =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

  String get primaryReason =>
      reasons.isNotEmpty ? reasons.first : 'Energi stabil';

  /// Warna badge skor berdasarkan nilai.
  int get scoreColor {
    if (score >= 70) return 0xFFD4AF37; // emas — sangat baik
    if (score >= 50) return 0xFF10B981; // hijau — baik
    return 0xFF60A5FA; // biru — cukup baik
  }
}
