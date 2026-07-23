import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/utils/bazi_utils.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;

/// Chinese name + short modern name for each Ten God.
const Map<String, (String, String)> _kTenGodNames = {
  'friend': ('比肩', 'Sahabat'),
  'rob_wealth': ('劫財', 'Penantang'),
  'eating_god': ('食神', 'Pencipta'),
  'hurting_officer': ('傷官', 'Visioner'),
  'indirect_wealth': ('偏財', 'Jaring'),
  'direct_wealth': ('正財', 'Pembangun'),
  'seven_killings': ('七殺', 'Pendobrak'),
  'direct_officer': ('正官', 'Penjaga'),
  'indirect_resource': ('偏印', 'Filsuf'),
  'direct_resource': ('正印', 'Pustaka'),
};

/// Compact Ten Gods (十神) row — tap any chip (except self) for full detail sheet.
class BaziTenGodsWidget extends StatelessWidget {
  final BaziChart chart;
  final Color elementColor;

  /// From baziGodsProvider — used to populate the tap-detail bottom sheet.
  /// Null when provider hasn't loaded yet; tap is silently disabled.
  final List<Map<String, dynamic>>? godsData;

  const BaziTenGodsWidget({
    super.key,
    required this.chart,
    required this.elementColor,
    this.godsData,
  });

  @override
  Widget build(BuildContext context) {
    final int dmIdx = chart.dayPillar.stemIndex;

    final columns = [
      (label: '年', pillar: chart.yearPillar, isSelf: false),
      (label: '月', pillar: chart.monthPillar, isSelf: false),
      (label: '日', pillar: chart.dayPillar, isSelf: true),
      (label: '時', pillar: chart.hourPillar, isSelf: false),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '十神 ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  color: elementColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ten Gods',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (godsData != null)
                Text(
                  'Tap untuk detail',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Posisi menentukan ekspresi — Ten God yang sama berarti berbeda di Tahun (sosial & leluhur), Bulan (karier & ambisi), atau Jam (pikiran batin & warisan).',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: columns.map((col) {
              // Self (day pillar) or unknown hour — no tap
              if (col.isSelf || col.pillar == null) {
                return Expanded(
                  child: _GodChip(
                    col: col,
                    dmStemIndex: dmIdx,
                    elementColor: elementColor,
                    hasTap: false,
                  ),
                );
              }

              final String godId = BaziUtils.getTenGodId(
                dmIdx,
                col.pillar!.stemIndex,
              );
              final Map<String, dynamic>? godEntry = godsData?.firstWhere(
                (g) => g['id'] == godId,
                orElse: () => <String, dynamic>{},
              );
              final bool canTap = godEntry != null && godEntry.isNotEmpty;

              return Expanded(
                child: GestureDetector(
                  onTap: godEntry != null && godEntry.isNotEmpty
                      ? () => _showGodDetail(
                          context,
                          godId,
                          godEntry,
                          col.pillar!,
                          elementColor,
                        )
                      : null,
                  child: _GodChip(
                    col: col,
                    dmStemIndex: dmIdx,
                    elementColor: elementColor,
                    hasTap: canTap,
                    hanziOverride: godEntry?['hanzi'] as String?,
                    namePendekOverride: (godEntry?['nama_modern'] ?? godEntry?['nama_pendek']) as String?,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showGodDetail(
    BuildContext context,
    String godId,
    Map<String, dynamic> data,
    BaziPillar pillar,
    Color elementColor,
  ) {
    final String hanzi =
        data['hanzi'] as String? ?? _kTenGodNames[godId]?.$1 ?? '?';
    final String nameId =
        data['nama_pendek'] as String? ?? _kTenGodNames[godId]?.$2 ?? godId;
    final Color color = kBaziElementColors[pillar.element] ?? elementColor;
    final String fokus = data['fokus_utama'] as String? ?? '';
    final String interp = data['interpretasi_psikologis'] as String? ?? '';
    final List<String> superpowers =
        (data['superpower_karier'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GodDetailSheet(
        hanzi: hanzi,
        nameId: nameId,
        nameTradisional: data['nama_tradisional'] as String? ?? '',
        fokus: fokus,
        interpretasi: interp,
        superpowers: superpowers,
        color: color,
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _GodChip extends StatelessWidget {
  final ({String label, BaziPillar? pillar, bool isSelf}) col;
  final int dmStemIndex;
  final Color elementColor;
  final bool hasTap;

  /// Pre-resolved from JSON godsData; falls back to _kTenGodNames if null.
  final String? hanziOverride;
  final String? namePendekOverride;

  const _GodChip({
    required this.col,
    required this.dmStemIndex,
    required this.elementColor,
    required this.hasTap,
    this.hanziOverride,
    this.namePendekOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (col.pillar == null) {
      return Column(
        children: [
          Text(
            col.label,
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24),
          ),
          const SizedBox(height: 4),
          Text(
            '—',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24),
          ),
        ],
      );
    }

    if (col.isSelf) {
      return Column(
        children: [
          Text(
            col.label,
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            '日主',
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              color: elementColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Diri Sendiri',
            style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final String godId = BaziUtils.getTenGodId(
      dmStemIndex,
      col.pillar!.stemIndex,
    );
    final String hanzi = hanziOverride ?? _kTenGodNames[godId]?.$1 ?? '?';
    final String nameId =
        namePendekOverride ?? _kTenGodNames[godId]?.$2 ?? godId;
    final Color color =
        kBaziElementColors[col.pillar!.element] ?? AppTheme.accentGold;

    return Column(
      children: [
        Text(
          col.label,
          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
        ),
        const SizedBox(height: 4),
        Text(
          hanzi,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          nameId,
          style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasTap)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 12,
              color: color.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}

// ─── Detail Bottom Sheet ──────────────────────────────────────────────────────

class _GodDetailSheet extends StatelessWidget {
  final String hanzi;
  final String nameId;
  final String nameTradisional;
  final String fokus;
  final String interpretasi;
  final List<String> superpowers;
  final Color color;

  const _GodDetailSheet({
    required this.hanzi,
    required this.nameId,
    required this.nameTradisional,
    required this.fokus,
    required this.interpretasi,
    required this.superpowers,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Hanzi + names
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hanzi,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 52,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameId,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    nameTradisional,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Fokus
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fokus,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Interpretasi
          Text(
            'Profil Psikologis',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            interpretasi,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Superpowers
          if (superpowers.isNotEmpty) ...[
            Text(
              'Superpower Karier',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: superpowers
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
