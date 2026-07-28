import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart' show kBaziElementColors;
import 'bazi_shared_constants.dart';

// ─── Psychological narratives per pillar-pair ──────────────────────────────

/// Narasi psikologis untuk Six Clash (六冲) per kombinasi indeks pilar.
/// Key: 'A_B' atau 'B_A' (sorted smaller first).
const Map<String, String> _kClashNarrative = {
  '0_1':
      'Visi sosial & leluhur (Pilar Tahun) berbenturan dengan tuntutan karier & ambisi (Pilar Bulan). Tekanan untuk "mewarisi" vs. kebebasan mendefinisikan diri sendiri.',
  '0_2':
      'Identitas sosial lama (Pilar Tahun) bertabrakan dengan inti diri & cara berhubungan (Pilar Hari). Transformasi besar-besaran pada cara Anda memandang diri sendiri.',
  '0_3':
      'Warisan keluarga (Pilar Tahun) bertabrakan dengan suara batin terdalam (Pilar Jam). Konflik antara nilai yang ditanamkan sejak lahir vs. aspirasi murni Anda.',
  '1_2':
      'Tuntutan karier & lingkungan (Pilar Bulan) berbenturan dengan identitas inti & hubungan intim (Pilar Hari). Ketegangan klasik antara peran profesional dan jati diri sejati.',
  '1_3':
      'Ambisi karier (Pilar Bulan) berbenturan dengan pikiran batin & kreativitas (Pilar Jam). Tekanan antara "harus" di dunia luar vs. apa yang sungguh ingin Anda ciptakan.',
  '2_3':
      'Identitas diri & hubungan (Pilar Hari) berbenturan dengan aspirasi batin terdalam (Pilar Jam). Konflik antara siapa Anda di mata dunia vs. siapa Anda di keheningan.',
  '0_4':
      'Energi tahun ini (流年) bertabrakan dengan pola sosial & warisan Anda. Tahun penuh tekanan transformatif — lebih baik melepas daripada bertahan.',
  '1_4':
      'Energi tahun ini (流年) berbenturan dengan jalur karier Anda. Hindari keputusan besar soal pekerjaan, fokus pada evaluasi & penyesuaian.',
  '2_4':
      'Energi tahun ini (流年) bertabrakan dengan inti diri Anda. Tahun yang menantang untuk hubungan intim — prioritaskan komunikasi jujur.',
  '3_4':
      'Energi tahun ini (流年) berbenturan dengan suara batin Anda. Jaga kesehatan mental, kurangi komitmen baru.',
};

/// Narasi psikologis untuk Six Harmony (六合) per kombinasi indeks pilar.
const Map<String, String> _kHarmonyNarrative = {
  '0_1':
      'Warisan sosial & karier Anda mengalir harmonis. Keluarga mendukung ambisi profesional — energi ini memperkuat reputasi jangka panjang.',
  '0_2':
      'Latar belakang & identitas inti selaras sempurna. Siapa Anda "di luar" konsisten dengan siapa Anda "di dalam" — fondasi kepercayaan diri yang kuat.',
  '0_3':
      'Nilai keluarga & suara batin Anda berjalan seirama. Intuisi dan naluri selaras dengan warisan leluhur — bakat alami mengalir bebas.',
  '1_2':
      'Karier & identitas diri bersinergi. Pekerjaan Anda adalah ekspresi otentik diri — langka dan berharga. Lingkungan kerja mendukung pertumbuhan pribadi.',
  '1_3':
      'Ambisi karier & kreativitas batin bergandengan tangan. Ide-ide terbaik Anda justru datang saat bekerja — inovasi dan produktivitas terhubung erat.',
  '2_3':
      'Hubungan intim & kehidupan batin selaras dalam. Pasangan atau orang terdekat memahami sisi paling murni Anda — koneksi emosional sangat dalam.',
  '0_4':
      'Energi tahun ini (流年) bersinergi dengan pola sosial Anda. Tahun yang baik untuk mempererat hubungan keluarga dan memperluas jaringan.',
  '1_4':
      'Energi tahun ini (流年) mendukung karier Anda. Peluang profesional mengalir lancar — waktu yang tepat untuk negosiasi dan kolaborasi.',
  '2_4':
      'Energi tahun ini (流年) harmonis dengan inti diri Anda. Hubungan intim berkembang positif — komunikasi dan kedekatan emosional meningkat.',
  '3_4':
      'Energi tahun ini (流年) selaras dengan batin Anda. Kreativitas dan intuisi berada di puncak — waktu terbaik untuk proyek personal.',
};

String? _clashNarrative(int a, int b) {
  final key = a < b ? '${a}_$b' : '${b}_$a';
  return _kClashNarrative[key];
}

String? _harmonyNarrative(int a, int b) {
  final key = a < b ? '${a}_$b' : '${b}_$a';
  return _kHarmonyNarrative[key];
}

/// Displays Six Clashes (六冲), Six Harmonies (六合), Three Harmonies (三合),
/// and Empty Branches (空亡) detected within the chart.
class BaziBranchRelationsCard extends StatelessWidget {
  final BaziChart chart;
  final BaziRelations relations;
  final List<int> emptyBranches;
  final List<BaziPillar?> pillars; // 0=Tahun,1=Bulan,2=Hari,3=Jam

  const BaziBranchRelationsCard({
    super.key,
    required this.chart,
    required this.relations,
    required this.emptyBranches,
    required this.pillars,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = !relations.isEmpty || emptyBranches.isNotEmpty;
    if (!hasContent) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Text(
            '⚡ Interaksi Pilar · Branch Relations',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // ── Six Clashes 六冲 ────────────────────────────────────────────
          if (relations.clashes.isNotEmpty) ...[
            _sectionLabel('六冲 · Six Clashes', const Color(0xFFF87171)),
            _helpText(
              'Oposisi langsung antara dua zodiak. Menciptakan tekanan atau perubahan mendadak di area pilar yang terlibat — bukan kutukan, sering justru pemicu transformasi terbesar.',
            ),
            ...relations.clashes.map((c) => _clashRow(c)),
            const SizedBox(height: 14),
          ],

          // ── Six Harmonies 六合 ──────────────────────────────────────────
          if (relations.harmonies.isNotEmpty) ...[
            _sectionLabel('六合 · Six Harmonies', AppTheme.accentGold),
            _helpText(
              'Pasangan alami yang sangat selaras — dua zodiak yang berpasangan mengalirkan energi lancar di area pilar yang diwakilinya.',
            ),
            ...relations.harmonies.map((h) => _harmonyRow(h)),
            const SizedBox(height: 14),
          ],

          // ── Three Harmonies 三合 ────────────────────────────────────────
          if (relations.triads.isNotEmpty) ...[
            _sectionLabel('三合 · Three Harmonies', const Color(0xFF60A5FA)),
            _helpText(
              'Koalisi tiga zodiak yang membentuk elemen baru secara kolektif. Semakin lengkap ketiga pilarnya, semakin kuat energi yang terbentuk.',
            ),
            ...relations.triads.map((t) => _triadRow(t)),
            const SizedBox(height: 14),
          ],

          // ── Empty Branches 空亡 ─────────────────────────────────────────
          _sectionLabel('空亡 · Empty Branches', AppTheme.textMuted),
          _helpText(
            'Zona kosong spiritual — area kehidupan di mana ambisi materi perlu dilepaskan. Paradoksnya, melepas di area ini justru membuka jalan kebijaksanaan dan kedamaian batin.',
          ),
          const SizedBox(height: 8),
          _emptyBranchesRow(),

          // ── AI Synthesis ────────────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          _BranchRelationsAiSection(
            chart: chart,
            relations: relations,
            emptyBranches: emptyBranches,
          ),
        ],
      ),
    );
  }

  Widget _clashRow(BaziClash c) {
    final pA = _pillarAt(c.indexA);
    final pB = _pillarAt(c.indexB);
    final narrative = _clashNarrative(c.indexA, c.indexB);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pillarBadge(c.indexA, pA),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '⚡',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFFF87171).withValues(alpha: 0.9),
                  ),
                ),
              ),
              _pillarBadge(c.indexB, pB),
              const SizedBox(width: 8),
              Text(
                'Bentrok',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFFF87171).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (narrative != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(
                narrative,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _harmonyRow(BaziHarmony h) {
    final resultColor =
        kBaziElementColors[h.resultElement] ?? AppTheme.accentGold;
    final narrative = _harmonyNarrative(h.indexA, h.indexB);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pillarBadge(h.indexA, _pillarAt(h.indexA)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '✦',
                  style: TextStyle(fontSize: 14, color: Color(0xFFFBBF24)),
                ),
              ),
              _pillarBadge(h.indexB, _pillarAt(h.indexB)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: resultColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '→ ${kBaziElementLabel[h.resultElement] ?? h.resultElement}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: resultColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (narrative != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(
                narrative,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _triadRow(BaziTriad t) {
    final elColor = kBaziElementColors[t.element] ?? AppTheme.accentPurple;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          ...t.pillarIndices.map(
            (idx) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _pillarBadge(idx, _pillarAt(idx)),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: elColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: elColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              '${t.isComplete ? "✓" : "~"} ${kBaziElementLabel[t.element] ?? t.element} ${t.isComplete ? "Lengkap" : "Parsial"}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: elColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBranchesRow() {
    // Which natal pillars contain empty branches
    final affectedLabels = <String>[];
    for (int i = 0; i < pillars.length; i++) {
      final p = pillars[i];
      if (p != null && emptyBranches.contains(p.branchIndex)) {
        affectedLabels.add(kBaziPillarLabels[i]);
      }
    }

    return Row(
      children: [
        ...emptyBranches.map(
          (b) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kBaziBranchSymbol[b],
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    kBaziBranchName[b],
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (affectedLabels.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            '← terdampak di: ${affectedLabels.join(", ")}',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else
          Text(
            'Tidak ada pilar yang terdampak',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _pillarBadge(int idx, BaziPillar? pillar) {
    final label = idx < kBaziPillarLabels.length ? kBaziPillarLabels[idx] : '?';
    final symbol = pillar != null ? pillar.branchSymbol : '?';
    final color = pillar != null
        ? (kBaziElementColors[pillar.element] ?? AppTheme.textMuted)
        : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: GoogleFonts.playfairDisplay(fontSize: 14, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  BaziPillar? _pillarAt(int idx) =>
      (idx >= 0 && idx < pillars.length) ? pillars[idx] : null;

  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: GoogleFonts.outfit(
      fontSize: 10,
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  Widget _helpText(String text) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: AppTheme.textMuted.withValues(alpha: 0.75),
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
    ),
  );
}

// ─── Branch Relations AI Synthesis ────────────────────────────────────────────

class _BranchRelationsAiSection extends ConsumerStatefulWidget {
  const _BranchRelationsAiSection({
    required this.chart,
    required this.relations,
    required this.emptyBranches,
  });

  final BaziChart chart;
  final BaziRelations relations;
  final List<int> emptyBranches;

  @override
  ConsumerState<_BranchRelationsAiSection> createState() =>
      _BranchRelationsAiSectionState();
}

class _BranchRelationsAiSectionState
    extends ConsumerState<_BranchRelationsAiSection> {
  String? _insight;
  bool _loading = false;

  /// Deterministik: sorted clash pairs digabung — sama untuk chart yang sama.
  static String _cacheKey(String dmId, BaziRelations relations) {
    final clashSig = (relations.clashes.map((c) {
      final a = c.indexA < c.indexB ? c.indexA : c.indexB;
      final b = c.indexA < c.indexB ? c.indexB : c.indexA;
      return '${a}_$b';
    }).toList()..sort()).join(',');
    return 'bazi_relations_ai_${dmId}_$clashSig';
  }

  String _buildPrompt() {
    final parts = <String>[];

    if (widget.relations.clashes.isNotEmpty) {
      final desc = widget.relations.clashes.map((c) {
        final ia = c.indexA.clamp(0, 3);
        final ib = c.indexB.clamp(0, 3);
        final key = ia < ib ? '${ia}_$ib' : '${ib}_$ia';
        final narrative = _kClashNarrative[key] ?? '';
        return 'Clash ${kBaziPillarLabels[ia]}-${kBaziPillarLabels[ib]}: $narrative';
      }).join(' | ');
      parts.add(desc);
    }

    if (widget.relations.harmonies.isNotEmpty) {
      final desc = widget.relations.harmonies.map((h) {
        final ia = h.indexA.clamp(0, 3);
        final ib = h.indexB.clamp(0, 3);
        return 'Harmony ${kBaziPillarLabels[ia]}-${kBaziPillarLabels[ib]} → ${h.resultElement}';
      }).join(' | ');
      parts.add(desc);
    }

    if (widget.emptyBranches.isNotEmpty) {
      final desc = widget.emptyBranches
          .map((b) => kBaziBranchName[b])
          .join(', ');
      parts.add('Empty Branches: $desc');
    }

    return 'Day Master: ${widget.chart.dayMasterElement} '
        '(${widget.chart.dmStrength.label}). '
        'Interaksi pilar: ${parts.join(". ")}. '
        'Tulis 3–4 kalimat yang mensintesis SEMUA interaksi ini menjadi satu '
        'tema psikologis dominan yang terasa dalam kehidupan sehari-hari. '
        'Jangan merangkum per pasangan — temukan benang merah yang '
        'menghubungkan semuanya. '
        'Nada empatik, psikologi modern, bukan ramalan buta.';
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(widget.chart.dayMasterId, widget.relations);
      final cached = prefs.getString(key);
      if (cached != null) {
        if (mounted) setState(() { _insight = cached; _loading = false; });
        return;
      }

      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final result = await ApiService.generateAiChat(
        prompt: _buildPrompt(),
        authHeader: authHeader,
      );
      final text = result['response'] as String? ?? '';
      if (text.isNotEmpty) {
        await prefs.setString(key, text);
        if (mounted) setState(() => _insight = text);
      }
    } catch (e) {
      debugPrint('_BranchRelationsAiSection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_insight != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '☯ Sintesis Pola Interaksimu',
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(
                    _cacheKey(widget.chart.dayMasterId, widget.relations),
                  );
                  if (mounted) setState(() => _insight = null);
                },
                child: Text(
                  '↻',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _insight!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.55,
            ),
          ),
        ],
      );
    }

    return Center(
      child: _loading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Menyusun sintesis pola interaksi...',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.accentGold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: _generate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      'Baca sintesis pola interaksimu',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
