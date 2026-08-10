/// Exception terstruktur untuk kuota Gemini harian habis (503 ORACLE_REST).
///
/// Dipakai oleh [ApiService] saat backend menjawab 503 dengan
/// `code: ORACLE_REST` — pengganti pengecekan string `GEMINI_QUOTA:` yang
/// rapuh. Membawa [retryAfterSeconds] agar UI bisa menampilkan hitung mundur
/// "kembali dalam X jam".
class OracleRestException implements Exception {
  /// Pesan ramah dari backend (Bahasa Indonesia, tone mystical).
  final String message;

  /// Perkiraan detik hingga kuota reset (tengah malam UTC).
  final int retryAfterSeconds;

  const OracleRestException(this.message, {this.retryAfterSeconds = 0});

  /// Pesan fallback bila backend tidak mengirim pesan.
  String get friendlyMessage => message.isNotEmpty
      ? message
      : 'Oracle sedang beristirahat — kapasitas kosmis hari ini sudah penuh. Kembali besok.';

  /// Format hitung mundur ramah: "5 jam 12 menit" / "45 menit" / "30 detik".
  String get countdownLabel {
    final total = retryAfterSeconds;
    if (total <= 0) return 'kembali besok';
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours jam $minutes menit' : '$hours jam';
    }
    if (minutes > 0) {
      return seconds > 0 ? '$minutes menit $seconds detik' : '$minutes menit';
    }
    return '$seconds detik';
  }

  @override
  String toString() => 'OracleRestException: $friendlyMessage';
}
