import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/cosmic_journal_service.dart';

/// Computes today's cosmic prediction from birth date (pure offline).
String _predictToday(DateTime birthDate) {
  final today = DateTime.now();
  if (WetonUtils.checkIsDinoWas(birthDate, today)) return 'ji';
  final birthWeton = WetonUtils.calculateWeton(birthDate);
  final todayWeton = WetonUtils.calculateWeton(today);
  final sisaBagi = (birthWeton.totalNeptu + todayWeton.totalNeptu) % 5;
  if (sisaBagi == 3) return 'yong'; // Gedhong — hari ekspansi
  if (sisaBagi == 4 || sisaBagi == 0) return 'ji'; // Loro + Pati — hari berat
  return 'netral';
}

/// Daily 1-tap Cosmic Calibration card.
///
/// State A — not yet logged today: shows 3 rating buttons.
/// State B — already logged: shows result + accuracy score.
class CosmicCalibrationCard extends StatefulWidget {
  final DateTime birthDate;

  const CosmicCalibrationCard({super.key, required this.birthDate});

  @override
  State<CosmicCalibrationCard> createState() => _CosmicCalibrationCardState();
}

class _CosmicCalibrationCardState extends State<CosmicCalibrationCard> {
  CosmicJournalEntry? _todayEntry;
  List<CosmicJournalEntry> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await CosmicJournalService.getTodayEntry();
    final recent = await CosmicJournalService.getRecentEntries();
    if (mounted) {
      setState(() {
        _todayEntry = today;
        _recent = recent;
        _loading = false;
      });
    }
  }

  Future<void> _rate(String rating) async {
    final prediction = _predictToday(widget.birthDate);
    final entry = CosmicJournalEntry(
      date: DateTime.now(),
      rating: rating,
      prediction: prediction,
    );
    await CosmicJournalService.save(entry);
    final recent = await CosmicJournalService.getRecentEntries();
    if (mounted) {
      setState(() {
        _todayEntry = entry;
        _recent = recent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final prediction = _predictToday(widget.birthDate);
    final accuracy = CosmicJournalService.calculateAccuracy(_recent);
    final hasEnoughData = _recent.length >= 7;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.30),
      child: _todayEntry == null
          ? _buildPrompt(prediction)
          : _buildResult(_todayEntry!, accuracy, hasEnoughData),
    );
  }

  Widget _buildPrompt(String prediction) {
    final today = DateTime.now();
    final dateFmt = DateFormat('EEEE, d MMM', 'id');
    final predLabel = _predictionLabel(prediction);
    final predColor = _predictionColor(prediction);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '✦ Kalibrasi Kosmis',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.accentPurple,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: predColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: predColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                predLabel,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: predColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Bagaimana energi ${dateFmt.format(today)} ini?',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _RatingButton(
              emoji: '⚡',
              label: 'Berat',
              onTap: () => _rate('berat'),
              color: const Color(0xFFF87171),
            ),
            const SizedBox(width: 8),
            _RatingButton(
              emoji: '😌',
              label: 'Normal',
              onTap: () => _rate('normal'),
              color: Colors.white54,
            ),
            const SizedBox(width: 8),
            _RatingButton(
              emoji: '🔥',
              label: 'Luar biasa',
              onTap: () => _rate('luar_biasa'),
              color: AppTheme.accentGold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(
    CosmicJournalEntry entry,
    double? accuracy,
    bool hasEnoughData,
  ) {
    final ratingEmoji = _ratingEmoji(entry.rating);
    final ratingLabel = _ratingLabel(entry.rating);
    final predLabel = _predictionLabel(entry.prediction);
    final predColor = _predictionColor(entry.prediction);
    final match = entry.isAccurate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '✅ Tercatat hari ini',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _todayEntry = null),
              child: Text(
                'Ubah',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.accentPurple.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '$ratingEmoji $ratingLabel',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: predColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: predColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Prediksi: $predLabel',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: predColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              entry.isScorable ? (match ? '· ✓ Sesuai' : '· ✗ Berbeda') : '',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: match ? Colors.greenAccent.shade400 : Colors.white38,
              ),
            ),
          ],
        ),
        if (hasEnoughData && accuracy != null) ...[
          const SizedBox(height: 8),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Akurasi kosmis Anda: ',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
              ),
              Text(
                '${(accuracy * 100).round()}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: accuracy >= 0.6 ? AppTheme.accentGold : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' (${_recent.length} hari)',
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Rating button ────────────────────────────────────────────────────────────

class _RatingButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _RatingButton({
    required this.emoji,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _predictionLabel(String p) => switch (p) {
  'yong' => '✦ Yong Shen',
  'ji' => '⚡ Ji Shen',
  _ => '≈ Netral',
};

Color _predictionColor(String p) => switch (p) {
  'yong' => AppTheme.accentGold,
  'ji' => const Color(0xFFF87171),
  _ => Colors.white54,
};

String _ratingEmoji(String r) => switch (r) {
  'berat' => '⚡',
  'luar_biasa' => '🔥',
  _ => '😌',
};

String _ratingLabel(String r) => switch (r) {
  'berat' => 'Berat',
  'luar_biasa' => 'Luar biasa',
  _ => 'Normal',
};
