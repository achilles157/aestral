import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../models/tarot_oracle_reading.dart';
import '../../services/tarot_data.dart';

/// Panel UI yang menampilkan hasil pembacaan Oracle AI untuk tebaran 3 kartu.
/// Menampilkan narasi Barnum per-kartu (dengan label posisi + badge orientasi)
/// dan konklusi synthesis di bagian bawah.
class TarotOraclePanel extends StatelessWidget {
  final TarotOracleReading oracleReading;
  final List<DrawnCardInfo> drawnCards;

  const TarotOraclePanel({
    super.key,
    required this.oracleReading,
    required this.drawnCards,
  });

  static const _positionIcons = {'past': '🕐', 'present': '☉', 'future': '✦'};

  static const _positionLabels = {
    'past': 'MASA LALU',
    'present': 'MASA KINI',
    'future': 'MASA DEPAN',
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      borderColor: AppTheme.accentGold.withValues(alpha: 0.4),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BACAAN ORACLE KOSMIS',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF2E2452), height: 28, thickness: 1),

          // Per-card narratives
          ...List.generate(drawnCards.length, (i) {
            final cardInfo = drawnCards[i];
            final label = cardInfo.label;
            final narrative = oracleReading.getNarrativeForLabel(label);
            if (narrative.isEmpty) return const SizedBox.shrink();
            return _buildCardNarrative(
              icon: _positionIcons[label] ?? '✦',
              positionLabel: _positionLabels[label] ?? label.toUpperCase(),
              cardName: cardInfo.card.nameId,
              isReversed: cardInfo.isReversed,
              narrative: narrative,
              isLast: i == drawnCards.length - 1,
            );
          }),

          // Synthesis / Konklusi
          if (oracleReading.synthesis.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.accentGold,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'KONKLUSI — BENANG MERAH',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          color: AppTheme.accentGold,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                oracleReading.synthesis,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.7,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardNarrative({
    required String icon,
    required String positionLabel,
    required String cardName,
    required bool isReversed,
    required String narrative,
    required bool isLast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$positionLabel — $cardName',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isReversed
                    ? AppTheme.accentPink.withValues(alpha: 0.15)
                    : AppTheme.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isReversed
                      ? AppTheme.accentPink.withValues(alpha: 0.4)
                      : AppTheme.accentGold.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isReversed ? 'TERBALIK ↺' : 'TEGAK ☼',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isReversed ? AppTheme.accentPink : AppTheme.accentGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          narrative,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.65,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }
}
