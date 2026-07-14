import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;

/// Displays the 8 Luck Pillars (大運) as a horizontal scrollable row of cards.
/// The currently active pillar (based on [birthDate]) is highlighted.
class BaziLuckPillarsWidget extends StatelessWidget {
  final List<LuckPillar> pillars;
  final Color elementColor;
  final bool isForward;

  /// Used to compute current age for active LP highlight.
  final DateTime birthDate;

  const BaziLuckPillarsWidget({
    super.key,
    required this.pillars,
    required this.elementColor,
    required this.isForward,
    required this.birthDate,
  });

  int _currentAge() {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final int age = _currentAge();
    final int nextTransitionAge = pillars
        .map((p) => p.startAge)
        .firstWhere(
          (ageVal) => ageVal > age,
          orElse: () => pillars.last.startAge,
        );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                '大運 ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: elementColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Luck Pillars',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _directionChip(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Siklus 10 Tahun (Da Yun) • Mulai usia ${pillars.first.startAge} • Transisi berikutnya: Usia $nextTransitionAge tahun',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            isForward
                ? '顺运 — Da Yun berjalan maju sesuai kalender. Energi terbuka secara progresif dari dekade ke dekade.'
                : '逆运 — Da Yun berjalan mundur melawan kalender. Perkembangan cenderung tidak konvensional; sering lebih kuat di paruh kedua tiap dekade.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: elementColor.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '5 tahun pertama tiap Da Yun dipengaruhi Heavenly Stem (ambisi & sosial) · 5 tahun terakhir dipengaruhi Earthly Branch (fondasi & kondisi internal).',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // ── Pillar cards ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pillars.map((lp) {
                final isActive = age >= lp.startAge && age <= lp.endAge;
                final isPast = lp.endAge < age;
                return _LuckPillarCard(
                  lp: lp,
                  isActive: isActive,
                  isPast: isPast,
                  elementColor: elementColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: elementColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: elementColor.withValues(alpha: 0.3)),
    ),
    child: Text(
      isForward ? '顺运' : '逆运',
      style: GoogleFonts.outfit(
        fontSize: 10,
        color: elementColor,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _LuckPillarCard extends StatelessWidget {
  final LuckPillar lp;
  final bool isActive;
  final bool isPast;
  final Color elementColor;

  const _LuckPillarCard({
    required this.lp,
    required this.isActive,
    required this.isPast,
    required this.elementColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        kBaziElementColors[lp.pillar.element] ?? AppTheme.accentGold;
    final Color activeColor = isActive ? elementColor : color;

    return Opacity(
      opacity: isPast ? 0.45 : 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 66,
            margin: const EdgeInsets.only(right: 8, top: 2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? elementColor.withValues(alpha: 0.18)
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? elementColor.withValues(alpha: 0.75)
                    : color.withValues(alpha: 0.25),
                width: isActive ? 1.8 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: elementColor.withValues(alpha: 0.28),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                // Age range
                Text(
                  '${lp.startAge}–${lp.endAge}',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: isActive ? elementColor : Colors.white38,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // Stem symbol
                Text(
                  lp.pillar.stemSymbol,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Branch symbol
                Text(
                  lp.pillar.branchSymbol,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    color: activeColor.withValues(alpha: 0.70),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lp.pillar.branchZodiacId,
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    color: isActive
                        ? elementColor.withValues(alpha: 0.80)
                        : Colors.white38,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── "AKTIF" badge ──────────────────────────────────────────────
          if (isActive)
            Positioned(
              top: -2,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: elementColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: Text(
                  'AKTIF',
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
