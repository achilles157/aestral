import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;

/// Displays the 8 Luck Pillars (大運) as a horizontal scrollable row of cards.
/// The currently active pillar (based on [birthDate]) is highlighted & auto-scrolled into view.
class BaziLuckPillarsWidget extends StatefulWidget {
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

  @override
  State<BaziLuckPillarsWidget> createState() => _BaziLuckPillarsWidgetState();
}

class _BaziLuckPillarsWidgetState extends State<BaziLuckPillarsWidget> {
  late final ScrollController _scrollCtrl;

  int _currentAge() {
    final now = DateTime.now();
    int age = now.year - widget.birthDate.year;
    if (now.month < widget.birthDate.month ||
        (now.month == widget.birthDate.month && now.day < widget.birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.pillars.isEmpty) return;
      final age = _currentAge();
      final activeIdx = widget.pillars.indexWhere(
        (lp) => age >= lp.startAge && age <= lp.endAge,
      );
      if (activeIdx > 0) {
        final targetOffset = (activeIdx * 74.0) - 20.0;
        _scrollCtrl.animateTo(
          targetOffset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int age = _currentAge();
    final bool isChildhood = widget.pillars.isNotEmpty && age < widget.pillars.first.startAge;
    final int nextTransitionAge = widget.pillars
        .map((p) => p.startAge)
        .firstWhere(
          (ageVal) => ageVal > age,
          orElse: () => widget.pillars.last.startAge,
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
                  color: widget.elementColor,
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
            isChildhood
                ? 'Siklus 10 Tahun (Da Yun) • Mulai usia ${widget.pillars.first.startAge} tahun • Saat ini di periode 童限 (Childhood Fortune)'
                : 'Siklus 10 Tahun (Da Yun) • Mulai usia ${widget.pillars.first.startAge} • Transisi berikutnya: Usia $nextTransitionAge tahun',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isForward
                ? '顺运 — Da Yun berjalan maju sesuai kalender. Energi terbuka secara progresif dari dekade ke dekade.'
                : '逆运 — Da Yun berjalan mundur melawan kalender. Perkembangan cenderung tidak konvensional; sering lebih kuat di paruh kedua tiap dekade.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: widget.elementColor.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk kartu pilar untuk melihat detail dinamika 10 tahun tersebut.',
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
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.pillars.map((lp) {
                final isActive = age >= lp.startAge && age <= lp.endAge;
                final isPast = lp.endAge < age;
                return _LuckPillarCard(
                  lp: lp,
                  isActive: isActive,
                  isPast: isPast,
                  elementColor: widget.elementColor,
                  onTap: () => _showLuckPillarDetail(context, lp, isActive, isPast),
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
          color: widget.elementColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.elementColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          widget.isForward ? '顺运 Maju' : '逆运 Mundur',
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: widget.elementColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  void _showLuckPillarDetail(
    BuildContext context,
    LuckPillar lp,
    bool isActive,
    bool isPast,
  ) {
    final stemElem = lp.pillar.element;
    final elemColor = kBaziElementColors[stemElem] ?? AppTheme.accentGold;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: elemColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: elemColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Usia ${lp.startAge}–${lp.endAge} Tahun',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: elemColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.elementColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PERIODE AKTIF SAAT INI',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${lp.pillar.stemSymbol} ${lp.pillar.branchSymbol} (${lp.pillar.stemNameId} ${lp.pillar.branchZodiacId})',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elemen Utama: ${stemElem.toUpperCase()} • Zodiak: ${lp.pillar.branchZodiacId}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: elemColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Dinamika Energi 10 Tahun:\n'
              '• 5 Tahun Pertama (Usia ${lp.startAge}–${lp.startAge + 4}): didominasi energi Batang Langit (${lp.pillar.stemSymbol} ${lp.pillar.stemNameId}) yang memengaruhi pencapaian sosial, orientasi karier, dan cita-cita luar.\n'
              '• 5 Tahun Kedua (Usia ${lp.startAge + 5}–${lp.endAge}): didominasi energi Cabang Bumi (${lp.pillar.branchSymbol} ${lp.pillar.branchZodiacId}) yang membentuk fondasi internal, kondisi emosional, dan stabilitas fisik.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuckPillarCard extends StatelessWidget {
  final LuckPillar lp;
  final bool isActive;
  final bool isPast;
  final Color elementColor;
  final VoidCallback onTap;

  const _LuckPillarCard({
    required this.lp,
    required this.isActive,
    required this.isPast,
    required this.elementColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        kBaziElementColors[lp.pillar.element] ?? AppTheme.accentGold;
    final Color activeColor = isActive ? elementColor : color;

    return Opacity(
      opacity: isPast ? 0.45 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}

