import '../models/hari_baik_result.dart';

/// Menghitung skor Hari Baik dari data hari kalender dan tujuan user.
/// Semua kalkulasi dilakukan client-side dari boolean fields yang sudah
/// tersedia di response /api/calendar/month — tidak butuh endpoint baru.
class HariBaikScorer {
  // ── Bobot dasar ────────────────────────────────────────────────────────────

  static const _scoreEkspansi = 40;
  static const _scoreStabil = 10;
  static const _penaltyDinoWas = -50;
  static const _penaltyBaziClash = -20;
  static const _penaltyWukuRawan = -10;
  static const _penaltyMangsaRawan = -10;
  static const _scoreBaziHarmony = 20;
  static const _scoreBaziYongShen = 15;

  // ── Bobot modifier per tujuan ─────────────────────────────────────────────

  static const _modifiers = {
    'karir_bisnis': {'is_bazi_yong_shen': 10},
    'pernikahan': {'is_bazi_harmony': 10},
    'kesehatan': {'is_wuku_rawan': -10, 'is_mangsa_rawan': -10},
    'umum': <String, int>{},
  };

  static const _minScore = 30;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Hitung skor satu hari. Return nilai integer (bisa negatif).
  static int score(Map<String, dynamic> dayData, String tujuan) {
    int s = 0;

    final label = dayData['pancasuda']?['planner_label'] as String? ?? '';
    final isDinoWas = dayData['is_dino_was'] as bool? ?? false;
    final isBaziClash = dayData['is_bazi_clash'] as bool? ?? false;
    final isWukuRawan = dayData['is_wuku_rawan'] as bool? ?? false;
    final isMangsaRawan = dayData['is_mangsa_rawan'] as bool? ?? false;
    final isBaziHarmony = dayData['is_bazi_harmony'] as bool? ?? false;
    final isBaziYongShen = dayData['is_bazi_yong_shen'] as bool? ?? false;

    // Skor dasar pancasuda
    if (label == 'ekspansi') s += _scoreEkspansi;
    if (label == 'stabil') s += _scoreStabil;

    // Penalti
    if (isDinoWas) s += _penaltyDinoWas;
    if (isBaziClash) s += _penaltyBaziClash;
    if (isWukuRawan) s += _penaltyWukuRawan;
    if (isMangsaRawan) s += _penaltyMangsaRawan;

    // Bonus Ba Zi
    if (isBaziHarmony) s += _scoreBaziHarmony;
    if (isBaziYongShen) s += _scoreBaziYongShen;

    // Modifier per tujuan
    final mod = _modifiers[tujuan] ?? {};
    if (mod['is_bazi_yong_shen'] != null && isBaziYongShen) {
      s += mod['is_bazi_yong_shen']!;
    }
    if (mod['is_bazi_harmony'] != null && isBaziHarmony) {
      s += mod['is_bazi_harmony']!;
    }
    if (mod['is_wuku_rawan'] != null && isWukuRawan) {
      s += mod['is_wuku_rawan']!;
    }
    if (mod['is_mangsa_rawan'] != null && isMangsaRawan) {
      s += mod['is_mangsa_rawan']!;
    }

    return s;
  }

  /// Filter dan sort hari-hari terbaik dari list dayData.
  /// Return maksimal [maxResults] hari dengan skor tertinggi,
  /// hanya hari yang lolos threshold dan tidak is_dino_was.
  static List<HariBaikResult> filter(
    List<Map<String, dynamic>> days,
    String tujuan, {
    int maxResults = 10,
  }) {
    final results = <HariBaikResult>[];

    for (final day in days) {
      final isDinoWas = day['is_dino_was'] as bool? ?? false;
      if (isDinoWas) continue; // dino was tidak pernah masuk

      final s = score(day, tujuan);
      if (s < _minScore) continue;

      final dateStr = day['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;

      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      // Skip hari yang sudah lewat
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final dayDate = DateTime(date.year, date.month, date.day);
      if (dayDate.isBefore(todayDate)) continue;

      results.add(
        HariBaikResult(
          date: date,
          dayData: day,
          score: s,
          label: day['pancasuda']?['planner_label'] as String? ?? 'stabil',
          reasons: _buildReasons(day, tujuan),
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static List<String> _buildReasons(Map<String, dynamic> day, String tujuan) {
    final r = <String>[];
    final label = day['pancasuda']?['planner_label'] as String? ?? '';
    final fase = day['pancasuda']?['fase'] as String? ?? '';

    if (label == 'ekspansi') r.add('Pancasuda $fase — Hari Ekspansi');
    if (day['is_bazi_harmony'] as bool? ?? false) {
      r.add('Ba Zi Harmoni');
    }
    if (day['is_bazi_yong_shen'] as bool? ?? false) {
      r.add('Yong Shen — Energi Penyeimbang');
    }
    if (label == 'stabil' && r.isEmpty)
      r.add('Pancasuda $fase — Energi Stabil');
    return r;
  }
}
