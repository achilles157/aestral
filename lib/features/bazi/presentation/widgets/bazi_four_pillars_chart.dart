import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart';

/// Horizontal chart displaying all 4 Ba Zi pillars.
/// Traditional order: Year → Month → Day → Hour (left to right).
/// The Day Pillar is highlighted as it contains the Day Master.
class BaziFourPillarsChart extends StatelessWidget {
  final BaziChart chart;

  const BaziFourPillarsChart({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(
                '四柱',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Empat Pilar Nasib',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Day Master: ${chart.dayPillar.stemSymbol} ${chart.dayPillar.stemNameId}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color:
                  kBaziElementColors[chart.dayMasterElement]?.withValues(
                    alpha: 0.9,
                  ) ??
                  AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 16),

          // Pillar row
          Row(
            children: [
              Expanded(
                child: BaziPillarColumn(
                  label: 'TAHUN',
                  pillar: chart.yearPillar,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BaziPillarColumn(
                  label: 'BULAN',
                  pillar: chart.monthPillar,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BaziPillarColumn(
                  label: 'HARI',
                  pillar: chart.dayPillar,
                  isHighlighted: true,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BaziPillarColumn(
                  label: 'JAM',
                  pillar: chart.hourPillar,
                  dayMasterStemIndex: chart.dayPillar.stemIndex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Domain labels per pillar
          Row(
            children: [
              _domainLabel('Sosial\n& Leluhur'),
              const SizedBox(width: 8),
              _domainLabel('Karier\n& Ambisi'),
              const SizedBox(width: 8),
              _domainLabel('Diri\n& Pasangan'),
              const SizedBox(width: 8),
              _domainLabel('Warisan\n& Bawah Sadar'),
            ],
          ),
          const SizedBox(height: 10),

          // Cang Gan note
          Text(
            '藏干 (Hidden Stems) — elemen tersembunyi di dalam setiap zodiak, mewakili motivasi dan karakter laten yang beroperasi di bawah permukaan.',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),

          // TST note
          if (chart.trueSolarTimeNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      chart.trueSolarTimeNote!,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _domainLabel(String text) => Expanded(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 9,
        color: Colors.white30,
        height: 1.4,
      ),
    ),
  );
}
