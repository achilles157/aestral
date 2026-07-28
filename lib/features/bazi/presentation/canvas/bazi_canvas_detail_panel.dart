import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';
import '../widgets/bazi_pillar_column.dart';
import '../widgets/bazi_shared_constants.dart';

/// Returns the Saat Pitu label for the selected hour from timetable data.
String? _getSaatLabel(int hour, Map<String, dynamic>? timetableDay) {
  if (timetableDay == null) return null;
  final allSlots = [
    ...(timetableDay['jam_baik'] as List<dynamic>? ?? []),
    ...(timetableDay['jam_naas'] as List<dynamic>? ?? []),
  ];
  for (final slot in allSlots) {
    final slotMap = slot as Map<String, dynamic>;
    final range = slotMap['range'] as String? ?? '';
    final parts = range.split(' - ');
    if (parts.length < 2) continue;
    final startH = int.tryParse(parts[0].split(':')[0]) ?? -1;
    final endH = int.tryParse(parts[1].split(':')[0]) ?? -1;
    if (startH > endH) {
      if (hour >= startH || hour < endH) return slotMap['label'] as String?;
    } else {
      if (hour >= startH && hour < endH) return slotMap['label'] as String?;
    }
  }
  return null;
}

Color _saatColor(String? label) {
  if (label == null) return Colors.white38;
  if (label.contains('Rezeki')) return AppTheme.accentGold;
  if (label.contains('Gedhong')) return Colors.greenAccent;
  if (label.contains('Loro')) return Colors.orangeAccent;
  if (label.contains('Pati')) return const Color(0xFFF87171);
  return Colors.white38;
}

const Map<String, String> _kTenGodShort = {
  'friend': 'Sahabat',
  'rob_wealth': 'Penantang',
  'eating_god': 'Pencipta',
  'hurting_officer': 'Visioner',
  'indirect_wealth': 'Jaring',
  'direct_wealth': 'Pembangun',
  'seven_killings': 'Pendobrak',
  'direct_officer': 'Penjaga',
  'indirect_resource': 'Filsuf',
  'direct_resource': 'Pustaka',
};

const Map<String, String> _kTenGodHanzi = {
  'friend': '比肩',
  'rob_wealth': '劫財',
  'eating_god': '食神',
  'hurting_officer': '傷官',
  'indirect_wealth': '偏財',
  'direct_wealth': '正財',
  'seven_killings': '七殺',
  'direct_officer': '正官',
  'indirect_resource': '偏印',
  'direct_resource': '正印',
};

class CanvasDetailPanel extends StatelessWidget {
  const CanvasDetailPanel({
    super.key,
    required this.selectedHour,
    required this.selectedDecadeIdx,
    required this.chart,
    required this.luckPillars,
    this.timetableDay,
  });

  final int selectedHour;
  final int selectedDecadeIdx;
  final BaziChart chart;
  final List<LuckPillar> luckPillars;
  final Map<String, dynamic>? timetableDay;

  @override
  Widget build(BuildContext context) {
    final selectedPillar =
        luckPillars.isNotEmpty && selectedDecadeIdx < luckPillars.length
        ? luckPillars[selectedDecadeIdx]
        : null;

    final hourBranchIdx = ((selectedHour + 1) % 24) ~/ 2;
    final branchSymbol = kBaziBranchSymbol[hourBranchIdx];
    final branchName = kBaziBranchName[hourBranchIdx];
    final element = BaziUtils.branchElements[hourBranchIdx];
    final elementColor = kBaziElementColors[element] ?? Colors.white;

    // Ten God: today's hour pillar stem vs Day Master
    final now = DateTime.now();
    final todayDayPillar = BaziUtils.getDayPillar(now.year, now.month, now.day);
    final hourPillar = BaziUtils.getHourPillar(
      selectedHour,
      todayDayPillar.stemIndex,
    );
    final tenGodId = BaziUtils.getTenGodId(
      chart.dayPillar.stemIndex,
      hourPillar.stemIndex,
    );
    final tenGodName = _kTenGodShort[tenGodId] ?? tenGodId;
    final tenGodHanzi = _kTenGodHanzi[tenGodId] ?? '';

    // Saat Pitu from timetable
    final saatLabel = _getSaatLabel(selectedHour, timetableDay);
    final saatColor = _saatColor(saatLabel);

    return DraggableScrollableSheet(
      initialChildSize: 0.22,
      minChildSize: 0.12,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Section 1: Shichen + Ten God + Saat ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: elementColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: elementColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        branchSymbol,
                        style: TextStyle(
                          color: elementColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam $selectedHour:00 • Shichen $branchName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              // Ten God badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: elementColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: elementColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '$tenGodHanzi $tenGodName',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: elementColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Saat Pitu badge
                              if (saatLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: saatColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: saatColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    saatLabel,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: saatColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Elemen ${element.toUpperCase()}',
                            style: TextStyle(
                              color: elementColor.withValues(alpha: 0.65),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),

                // ── Section 2: Da Yun Detail ────────────────────────────
                if (selectedPillar != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilar Da Yun',
                        style: GoogleFonts.cinzel(
                          color: AppTheme.accentGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Usia ${selectedPillar.startAge}–${selectedPillar.endAge} Thn',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${selectedPillar.pillar.stemSymbol}${selectedPillar.pillar.branchSymbol}',
                          style: TextStyle(
                            color:
                                kBaziElementColors[selectedPillar
                                    .pillar
                                    .element] ??
                                Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedPillar.pillar.stemNameId} • ${selectedPillar.pillar.branchZodiacId}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Ten God of Da Yun stem vs Day Master
                              Builder(
                                builder: (_) {
                                  final dyId = BaziUtils.getTenGodId(
                                    chart.dayPillar.stemIndex,
                                    selectedPillar.pillar.stemIndex,
                                  );
                                  final dyName = _kTenGodShort[dyId] ?? dyId;
                                  final dyHanzi = _kTenGodHanzi[dyId] ?? '';
                                  final dyColor =
                                      kBaziElementColors[selectedPillar
                                          .pillar
                                          .element] ??
                                      Colors.white70;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dyColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: dyColor.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      '$dyHanzi $dyName',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: dyColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
