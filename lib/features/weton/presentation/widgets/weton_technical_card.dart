import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import 'javanese_astrological_gear_dial.dart';

/// Card "Sandi Angka Kelahiran" — gear dial, detail rows, neptu bar, badges.
/// _DetailRow dan _AnalysisBadge dipindah ke sini dari weton_calculator_screen.
class WetonTechnicalCard extends StatelessWidget {
  final WetonInfo result;

  const WetonTechnicalCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      borderWidth: 1.2,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📜 Sandi Angka Kelahiran',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 16,
              color: AppTheme.accentPurple,
            ),
          ),
          const SizedBox(height: 16),
          JavaneseAstrologicalGearDial(
            saptawara: result.saptawara,
            pancawara: result.pancawara,
            wuku: result.wuku,
            totalNeptu: result.totalNeptu,
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF2E2452), height: 20, thickness: 1.5),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Kalender Jawa Asapon',
            value:
                '${result.javaneseDay} ${result.javaneseMonth} ${result.javaneseYear} (${result.javaneseYearName})',
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Wuku', value: result.wuku),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Neptu Saptawara',
            value: '${result.saptawara} (${result.neptuSaptawara})',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Neptu Pancawara',
            value: '${result.pancawara} (${result.neptuPancawara})',
          ),
          const SizedBox(height: 20),
          Text(
            'TOTAL NEPTU: ${result.totalNeptu} / 18',
            style: textTheme.labelLarge?.copyWith(color: AppTheme.accentGold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: result.totalNeptu / 18,
              backgroundColor: AppTheme.background,
              color: AppTheme.accentPurple,
              minHeight: 10,
            ),
          ),
          const Divider(color: Color(0xFF2E2452), height: 40, thickness: 1.5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AnalysisBadge(
                  label: 'Pangarasan',
                  value: result.pangarasan,
                  color: AppTheme.accentPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalysisBadge(
                  label: 'Pancasuda',
                  value: result.pancasuda,
                  color: AppTheme.accentPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalysisBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}
