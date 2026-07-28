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
          _ArchetypeCard(chart: chart, elementColor: elementColor),
          const SizedBox(height: 12),
          Row(
            children: columns.asMap().entries.map((entry) {
              final i = entry.key;
              final col = entry.value;
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
                          i,
                        )
                      : null,
                  child: _GodChip(
                    col: col,
                    dmStemIndex: dmIdx,
                    elementColor: elementColor,
                    hasTap: canTap,
                    hanziOverride: godEntry?['hanzi'] as String?,
                    namePendekOverride:
                        (godEntry?['nama_modern'] ?? godEntry?['nama_pendek'])
                            as String?,
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
    int pillarIndex,
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
        pillarIndex: pillarIndex,
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

/// Pillar position label + domain.
const Map<int, (String, String)> _kPillarPositionLabel = {
  0: ('Pilar Tahun', 'Sosial & Warisan Leluhur'),
  1: ('Pilar Bulan', 'Karier & Ambisi'),
  3: ('Pilar Jam', 'Pikiran Batin & Warisan Karya'),
};

/// Positional interpretation per Ten God × pillar index.
const Map<String, Map<int, String>> _kGodPositionalContext = {
  'direct_officer': {
    0: 'Di Pilar Tahun, Penjaga membentuk standar moral dari warisan leluhur — reputasi adalah harga dirimu.',
    1: 'Di Pilar Bulan, Penjaga mewarnai karier dengan kebutuhan akan struktur dan pengakuan formal. Kamu bekerja paling baik dalam sistem yang jelas.',
    3: 'Di Pilar Jam, Penjaga beroperasi sebagai hakim batin — standar yang kamu terapkan pada dirimu sendiri jauh lebih tinggi dari yang tampak di luar.',
  },
  'seven_killings': {
    0: 'Di Pilar Tahun, Pendobrak terbentuk dari tekanan sosial masa kecil yang mengasah ketangguhan. Tekanan itu yang membentukmu.',
    1: 'Di Pilar Bulan, Pendobrak menjadikan lingkungan kerja arena pembuktian diri. Tantangan justru mengaktifkan potensimu.',
    3: 'Di Pilar Jam, Pendobrak tak pernah tidur — ada dorongan batin yang terus mendorongmu melampaui batas, bahkan saat dunia sudah istirahat.',
  },
  'direct_wealth': {
    0: 'Di Pilar Tahun, Pembangun meletakkan fondasi nilai kerja keras dari keluarga. Kamu tahu harga sesuatu karena diajarkan sejak awal.',
    1: 'Di Pilar Bulan, Pembangun mewarnai karier dengan orientasi hasil yang terukur. Produktivitas dan konsistensi adalah bahasamu.',
    3: 'Di Pilar Jam, Pembangun beroperasi dalam aspirasi batin — impian tentang stabilitas dan kebebasan finansial mengisi pikiranmu yang paling dalam.',
  },
  'indirect_wealth': {
    0: 'Di Pilar Tahun, Jaring muncul sebagai kemampuan membaca peluang dari lingkungan sosial yang luas. Koneksi tak terduga jadi sumber rezekimu.',
    1: 'Di Pilar Bulan, Jaring mewarnai karier dengan intuisi bisnis dan kemampuan menemukan celah yang orang lain lewatkan.',
    3: 'Di Pilar Jam, Jaring bekerja di bawah sadar — ide tak konvensional tentang peluang datang di saat yang paling tidak terduga.',
  },
  'eating_god': {
    0: 'Di Pilar Tahun, Pencipta mewarisi bakat ekspresi dari keluarga yang menghargai kreativitas atau kelezatan hidup.',
    1: 'Di Pilar Bulan, Pencipta menjadikan karier medium ekspresi diri. Kamu bekerja paling produktif saat diberi kebebasan berkreasi.',
    3: 'Di Pilar Jam, Pencipta adalah sumber ide tak habisnya — imajinasi dan kebutuhan untuk menghasilkan sesuatu memenuhi seluruh ruang batinmu.',
  },
  'hurting_officer': {
    0: 'Di Pilar Tahun, Visioner membawa warisan pemberontak dari keluarga atau terlahir untuk mengubah norma yang ada di lingkungannya.',
    1: 'Di Pilar Bulan, Visioner mewarnai karier dengan semangat inovasi yang sering bertabrakan dengan sistem. Ini sumber terobosanmu.',
    3: 'Di Pilar Jam, Visioner beroperasi sebagai kritikus batin yang tak pernah puas — kamu selalu melihat jarak antara apa yang ada dan apa yang seharusnya.',
  },
  'direct_resource': {
    0: 'Di Pilar Tahun, Pustaka mewarisi tradisi belajar yang kuat dari keluarga. Fondasi intelektualmu dibangun sejak dini.',
    1: 'Di Pilar Bulan, Pustaka mewarnai karier dengan kebutuhan untuk terus belajar dan mengasah keahlian. Mentor adalah figur penting dalam perjalananmu.',
    3: 'Di Pilar Jam, Pustaka beroperasi sebagai pencari makna batin — pikiranmu selalu mengolah, merefleksikan, dan mencari pemahaman yang lebih dalam.',
  },
  'indirect_resource': {
    0: 'Di Pilar Tahun, Filsuf mewarisi intuisi dan kepekaan spiritual dari leluhur. Ada kebijaksanaan yang mengalir dalam darahmu.',
    1: 'Di Pilar Bulan, Filsuf mewarnai karier dengan pendekatan tidak konvensional. Kamu memproses masalah dengan cara yang orang lain tidak pikirkan.',
    3: 'Di Pilar Jam, Filsuf beroperasi sebagai penerima sinyal batin — mimpi, firasat, dan momen hening adalah sumber wawasanmu yang paling jujur.',
  },
  'friend': {
    0: 'Di Pilar Tahun, Sahabat muncul sebagai jaringan sosial yang luas dan kemampuan membangun solidaritas. Identitasmu terhubung kuat dengan komunitas.',
    1: 'Di Pilar Bulan, Sahabat mewarnai karier dengan kolaborasi dan kerja tim. Kamu tumbuh paling pesat dalam lingkungan yang saling mendukung.',
    3: 'Di Pilar Jam, Sahabat beroperasi sebagai kebutuhan batin untuk dimengerti — di dalam, kamu mendambakan koneksi autentik yang melampaui permukaan.',
  },
  'rob_wealth': {
    0: 'Di Pilar Tahun, Penantang membawa warisan kompetisi dari keluarga yang menuntut kemandirian sejak dini.',
    1: 'Di Pilar Bulan, Penantang mewarnai karier dengan energi kompetitif yang tinggi. Kamu bekerja paling tajam saat ada sesuatu yang dipertaruhkan.',
    3: 'Di Pilar Jam, Penantang beroperasi sebagai suara batin yang mendorong otonomi total — ada bagian darimu yang selalu ingin berdiri sendiri.',
  },
};

class _GodDetailSheet extends StatelessWidget {
  final String hanzi;
  final String nameId;
  final String nameTradisional;
  final String fokus;
  final String interpretasi;
  final List<String> superpowers;
  final Color color;
  final int pillarIndex;

  const _GodDetailSheet({
    required this.hanzi,
    required this.nameId,
    required this.nameTradisional,
    required this.fokus,
    required this.interpretasi,
    required this.superpowers,
    required this.color,
    required this.pillarIndex,
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

          // ── Positional Context ──────────────────────────────────────────
          if (_kPillarPositionLabel.containsKey(pillarIndex)) ...[
            const SizedBox(height: 16),
            Text(
              'Makna di Posisi Ini',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _kPillarPositionLabel[pillarIndex]!.$1,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _kPillarPositionLabel[pillarIndex]!.$2,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _kGodPositionalContext[nameId.toLowerCase().replaceAll(' ', '_')]?[pillarIndex] ??
                        _kGodPositionalContext.entries
                            .firstWhere(
                              (e) => e.key.contains(
                                nameId.toLowerCase().split(' ').first,
                              ),
                              orElse: () => const MapEntry('', {}),
                            )
                            .value[pillarIndex] ??
                        '',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.80),
                      height: 1.5,
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
}

// ─── Archetype Card ───────────────────────────────────────────────────────────

/// Maps Ten God id → archetype group id.
const Map<String, String> _kGodToGroup = {
  'direct_wealth': 'wealth',
  'indirect_wealth': 'wealth',
  'direct_officer': 'authority',
  'seven_killings': 'authority',
  'direct_resource': 'resource',
  'indirect_resource': 'resource',
  'eating_god': 'expression',
  'hurting_officer': 'expression',
  'friend': 'companion',
  'rob_wealth': 'companion',
};

const Map<String, (String, String, String)> _kArchetypes = {
  'wealth': (
    '👑 Pembangun Terstruktur',
    'Membangun kekayaan & stabilitas secara metodis, disiplin, dan konsisten.',
    'direct_wealth',
  ),
  'authority': (
    '⚡ Pemimpin Berwibawa',
    'Disiplin, reputasi, dan pengaruh dalam struktur — lahir untuk memimpin.',
    'direct_officer',
  ),
  'resource': (
    '📚 Pemikir Strategis',
    'Keahlian mendalam, intuisi tajam, dan fondasi intelektual yang kuat.',
    'direct_resource',
  ),
  'expression': (
    '🎨 Kreator Bebas',
    'Ekspresi otentik, terobosan kreatif, dan kebebasan berkarya tanpa batas.',
    'eating_god',
  ),
  'companion': (
    '🔥 Pendobrak Mandiri',
    'Kemandirian jiwa, daya kompetitif tinggi, dan karakter yang tidak mudah goyah.',
    'friend',
  ),
};

/// Computes dominant archetype from [chart]'s Ten God distribution.
/// Returns (groupId, godIds used for display).
({String groupId, List<String> dominantGods}) _computeArchetype(
  BaziChart chart,
) {
  final dmIdx = chart.dayPillar.stemIndex;
  final pillars = [
    chart.yearPillar,
    chart.monthPillar,
    if (chart.hourPillar != null) chart.hourPillar!,
  ];

  // Count per group
  final counts = <String, int>{};
  final godsByGroup = <String, List<String>>{};

  for (final p in pillars) {
    final godId = BaziUtils.getTenGodId(dmIdx, p.stemIndex);
    final group = _kGodToGroup[godId] ?? 'companion';
    counts[group] = (counts[group] ?? 0) + 1;
    godsByGroup.putIfAbsent(group, () => []);
    if (!godsByGroup[group]!.contains(godId)) {
      godsByGroup[group]!.add(godId);
    }
  }

  // Find dominant group
  String topGroup = 'resource';
  int topCount = 0;
  counts.forEach((g, c) {
    if (c > topCount) {
      topCount = c;
      topGroup = g;
    }
  });

  return (groupId: topGroup, dominantGods: godsByGroup[topGroup] ?? []);
}

class _ArchetypeCard extends StatelessWidget {
  final BaziChart chart;
  final Color elementColor;

  const _ArchetypeCard({required this.chart, required this.elementColor});

  @override
  Widget build(BuildContext context) {
    final result = _computeArchetype(chart);
    final archetype = _kArchetypes[result.groupId];
    if (archetype == null) return const SizedBox.shrink();

    final label = archetype.$1;
    final desc = archetype.$2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elementColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: elementColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Arketipe Utama',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Dominant god pills
              ...result.dominantGods.take(2).map((gId) {
                final names = _kTenGodNames[gId];
                if (names == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: elementColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: elementColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${names.$1} ${names.$2}',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: elementColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
