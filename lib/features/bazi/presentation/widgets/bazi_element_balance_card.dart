import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/bazi_chart.dart';
import 'bazi_pillar_column.dart';

/// Wu Xing (五行) element balance bar chart.
/// Shows distribution of the 5 elements across all pillar stems + branches.
class BaziElementBalanceCard extends StatelessWidget {
  final WuXingBalance balance;

  const BaziElementBalanceCard({super.key, required this.balance});

  static const List<_ElementRow> _elements = [
    _ElementRow('kayu',  'Kayu 木', '🌿', Color(0xFF4ADE80)),
    _ElementRow('api',   'Api 火',  '🔥', Color(0xFFF87171)),
    _ElementRow('tanah', 'Tanah 土','🪨', Color(0xFFFBBF24)),
    _ElementRow('logam', 'Logam 金','⚔️', Color(0xFFE2E8F0)),
    _ElementRow('air',   'Air 水',  '💧', Color(0xFF60A5FA)),
  ];

  int _countFor(String key) {
    switch (key) {
      case 'kayu':  return balance.kayu;
      case 'api':   return balance.api;
      case 'tanah': return balance.tanah;
      case 'logam': return balance.logam;
      case 'air':   return balance.air;
      default:      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int maxCount =
        [balance.kayu, balance.api, balance.tanah, balance.logam, balance.air]
            .reduce((a, b) => a > b ? a : b);
    final int total = balance.total;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
            ],
          ),
          Text(
            'Dari ${total} karakter aktif (${balance.kayu + balance.api + balance.tanah + balance.logam + balance.air == 8 ? "8 karakter penuh" : "6 karakter — jam tidak diketahui"})',
            style: GoogleFonts.outfit(
                fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          ..._elements.map((el) {
            final int count = _countFor(el.key);
            final double fraction =
                maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(el.emoji,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 68,
                    child: Text(
                      el.label,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: el.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: el.color.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(el.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: count > 0 ? el.color : Colors.white24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Dominant / Deficient note
          const SizedBox(height: 4),
          Row(
            children: [
              _badge(
                  '↑ ${balance.dominant.toUpperCase()}',
                  kBaziElementColors[balance.dominant] ?? AppTheme.accentGold),
              const SizedBox(width: 8),
              _badge(
                  '↓ ${balance.deficient.toUpperCase()}',
                  (kBaziElementColors[balance.deficient] ?? Colors.white38)
                      .withOpacity(0.6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
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

class _ElementRow {
  final String key;
  final String label;
  final String emoji;
  final Color color;
  const _ElementRow(this.key, this.label, this.emoji, this.color);
}
