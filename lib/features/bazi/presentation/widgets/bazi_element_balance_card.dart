import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart';
import 'bazi_wu_xing_radar.dart';

const _kDominantDesc = {
  'kayu':  'Kayu dominan: tendensi kuat untuk terus tumbuh dan berinovasi.',
  'api':   'Api dominan: semangat dan kepemimpinan ekspresif yang menonjol.',
  'tanah': 'Tanah dominan: stabilitas dan kemampuan memelihara yang kuat.',
  'logam': 'Logam dominan: ketegasan dan presisi dalam mengambil keputusan.',
  'air':   'Air dominan: intuisi yang dalam dan kemampuan beradaptasi tinggi.',
};

const _kDeficientDesc = {
  'kayu':  'Fleksibilitas dan kreativitas adalah area untuk lebih diaktivasi.',
  'api':   'Antusiasme dan semangat bisa lebih dikembangkan secara sadar.',
  'tanah': 'Koneksi dengan hal-hal praktis dan fondasi perlu lebih diperhatikan.',
  'logam': 'Disiplin dan struktur adalah area untuk terus ditingkatkan.',
  'air':   'Kemampuan beradaptasi dan intuisi perlu lebih diasah.',
};

/// Wu Xing (五行) element balance — pentagon radar chart with dominant/deficient badges.
class BaziElementBalanceCard extends StatelessWidget {
  final WuXingBalance balance;

  const BaziElementBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final total = balance.total;
    final totalLabel = total == 18
        ? '18 karakter penuh'
        : total == 15 || total == 16
            ? '$total karakter (jam diketahui)'
            : '$total karakter — jam tidak diketahui';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(children: [
            Text(
              '五行',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Keseimbangan Lima Elemen',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
          Text(
            'Dari $totalLabel',
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 16),

          // ── Pentagon Radar ──────────────────────────────────────────────
          BaziWuXingRadar(balance: balance),

          // ── Dominant / Deficient badges ─────────────────────────────────
          const SizedBox(height: 14),
          Row(children: [
            _badge(
              '↑ ${balance.dominant.toUpperCase()}',
              kBaziElementColors[balance.dominant] ?? AppTheme.accentGold,
            ),
            const SizedBox(width: 8),
            _badge(
              '↓ ${balance.deficient.toUpperCase()}',
              (kBaziElementColors[balance.deficient] ?? Colors.white38)
                  .withValues(alpha: 0.55),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            '${_kDominantDesc[balance.dominant] ?? ''} ${_kDeficientDesc[balance.deficient] ?? ''}',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}
