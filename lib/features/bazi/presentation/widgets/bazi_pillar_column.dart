import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bazi_chart.dart';

/// Element accent colors — consistent across all Ba Zi widgets.
const Map<String, Color> kBaziElementColors = {
  'kayu':  Color(0xFF4ADE80),
  'api':   Color(0xFFF87171),
  'tanah': Color(0xFFFBBF24),
  'logam': Color(0xFFE2E8F0),
  'air':   Color(0xFF60A5FA),
};

const Map<String, String> kBaziElementEmoji = {
  'kayu':  '🌿',
  'api':   '🔥',
  'tanah': '🪨',
  'logam': '⚔️',
  'air':   '💧',
};

/// Cang Gan (藏干) — hidden stems per Earthly Branch.
const Map<String, List<String>> _kCangGan = {
  'zi':   ['gui'],
  'chou': ['ji', 'gui', 'xin'],
  'yin':  ['jia', 'bing', 'wu'],
  'mao':  ['yi'],
  'chen': ['wu', 'yi', 'gui'],
  'si':   ['bing', 'wu', 'geng'],
  'wu':   ['ding', 'ji'],
  'wei':  ['ji', 'ding', 'yi'],
  'shen': ['geng', 'ren', 'wu'],
  'you':  ['xin'],
  'xu':   ['wu', 'xin', 'ding'],
  'hai':  ['ren', 'jia'],
};

const Map<String, String> _kStemSymbol = {
  'jia': '甲', 'yi': '乙', 'bing': '丙', 'ding': '丁', 'wu': '戊',
  'ji':  '己', 'geng': '庚', 'xin': '辛', 'ren': '壬', 'gui': '癸',
};

const Map<String, String> _kStemElement = {
  'jia': 'kayu', 'yi':   'kayu',  'bing': 'api',   'ding': 'api',
  'wu':  'tanah', 'ji':  'tanah', 'geng': 'logam', 'xin':  'logam',
  'ren': 'air',   'gui': 'air',
};

/// A single vertical pillar column showing Heavenly Stem above Earthly Branch.
///
/// Used inside [BaziFourPillarsChart]. Pass [pillar] = null to render the
/// "Jam tidak diketahui" placeholder.
class BaziPillarColumn extends StatelessWidget {
  final String label;
  final BaziPillar? pillar;
  final bool isHighlighted; // true for Day Pillar (Day Master emphasis)

  const BaziPillarColumn({
    super.key,
    required this.label,
    required this.pillar,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color elementColor = pillar != null
        ? (kBaziElementColors[pillar!.element] ?? AppTheme.accentGold)
        : Colors.white24;

    final Color glowColor = elementColor.withOpacity(0.18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? elementColor : elementColor.withOpacity(0.4),
          width: isHighlighted ? 1.5 : 0.8,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: glowColor, blurRadius: 18, spreadRadius: 2)]
            : [BoxShadow(color: glowColor, blurRadius: 8)],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pillar label (Tahun / Bulan / Hari / Jam)
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: elementColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          if (pillar != null) ...[
            // Heavenly Stem symbol
            Text(
              pillar!.stemSymbol,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: elementColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // Stem Indonesian name
            Text(
              pillar!.stemNameId,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white70,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: elementColor.withOpacity(0.25), height: 1),
            const SizedBox(height: 10),
            // Earthly Branch symbol
            Text(
              pillar!.branchSymbol,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                color: elementColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // Branch zodiac name
            Text(
              pillar!.branchZodiacId,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white60,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            // Hidden Stems 藏干
            _CangGanRow(branchId: pillar!.branchId),
            const SizedBox(height: 6),
            // Sexagenary slug pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: elementColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: elementColor.withOpacity(0.3)),
              ),
              child: Text(
                pillar!.id.replaceAll('_', ' '),
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  color: elementColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ] else ...[
            // Unknown hour placeholder
            const SizedBox(height: 8),
            Text(
              '？',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak\nDiketahui',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white30,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact row of hidden stem (藏干) symbols, each tinted by element color.
class _CangGanRow extends StatelessWidget {
  final String branchId;
  const _CangGanRow({required this.branchId});

  @override
  Widget build(BuildContext context) {
    final stems = _kCangGan[branchId] ?? [];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stems.map((s) {
        final Color c = kBaziElementColors[_kStemElement[s]] ?? Colors.white24;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            _kStemSymbol[s] ?? '',
            style: TextStyle(
              fontSize: 9,
              color: c.withOpacity(0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
