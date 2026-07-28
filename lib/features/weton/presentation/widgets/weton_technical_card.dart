import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../core/widgets/glass_card.dart';
import 'javanese_astrological_gear_dial.dart';

String _neptuLabel(int neptu) {
  if (neptu <= 10) return 'Energi ringan — fleksibel dan adaptif';
  if (neptu <= 14) return 'Energi seimbang — stabil dan terukur';
  return 'Energi besar — kuat namun perlu dikelola';
}

/// Card "Sandi Angka Kelahiran" — gear dial, wuku, neptu kontekstual,
/// detail teknis tersembunyi, dan badge Pangarasan & Pancasuda yang tappable.
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
          const SizedBox(height: 12),

          // ── Wuku — selalu terlihat ──────────────────────────────────────
          _DetailRow(label: 'Wuku', value: result.wuku),
          const SizedBox(height: 16),

          // ── Total Neptu dengan label kontekstual ───────────────────────
          Text(
            'TOTAL NEPTU: ${result.totalNeptu} / 18',
            style: textTheme.labelLarge?.copyWith(color: AppTheme.accentGold),
          ),
          const SizedBox(height: 4),
          Text(
            _neptuLabel(result.totalNeptu),
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.accentGold.withValues(alpha: 0.65),
              fontStyle: FontStyle.italic,
            ),
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
          const SizedBox(height: 4),

          // ── Detail teknis tersembunyi — hanya Kalender Asapon ──────────
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Lihat Detail Perhitungan Teknis',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
              iconColor: Colors.white24,
              collapsedIconColor: Colors.white24,
              children: [
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Kalender Jawa Asapon',
                  value:
                      '${result.javaneseDay} ${result.javaneseMonth} ${result.javaneseYear} (${result.javaneseYearName})',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Neptu selalu terlihat ───────────────────────────────────────
          _DetailRow(
            label: 'Neptu Saptawara',
            value: '${result.saptawara} (${result.neptuSaptawara})',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Neptu Pancawara',
            value: '${result.pancawara} (${result.neptuPancawara})',
          ),
          const SizedBox(height: 12),

          const Divider(color: Color(0xFF2E2452), height: 32, thickness: 1.5),

          // ── Pangarasan & Pancasuda — tappable ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AnalysisBadge(
                  label: 'Pangarasan',
                  value: result.pangarasan,
                  color: AppTheme.accentPurple,
                  onTap: () => _showPangarasanSheet(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnalysisBadge(
                  label: 'Pancasuda',
                  value: result.pancasuda,
                  color: AppTheme.accentPink,
                  onTap: () => _showPancasudaSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPangarasanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BadgeDetailSheet(
        title: 'Pangarasan',
        subtitle: result.pangarasan,
        color: AppTheme.accentPurple,
        future: rootBundle
            .loadString('assets/weton/pangarasan-pancasuda.json')
            .then((raw) {
          final data = json.decode(raw) as Map<String, dynamic>;
          final map = data['pangarasan'] as Map<String, dynamic>;
          return map[result.saptawara] as String? ?? result.pangarasan;
        }),
        description:
            'Pangarasan adalah karakter dasar energi hari lahirmu berdasarkan hari Jawa (Saptawara). '
            'Ia menggambarkan cara kamu bergerak dan berinteraksi dengan dunia di sekitarmu.',
      ),
    );
  }

  void _showPancasudaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BadgeDetailSheet(
        title: 'Pancasuda',
        subtitle: result.pancasuda,
        color: AppTheme.accentPink,
        future: rootBundle
            .loadString('assets/weton/pangarasan-pancasuda.json')
            .then((raw) {
          final data = json.decode(raw) as Map<String, dynamic>;
          final list = data['pancasuda'] as List<dynamic>;
          final idx = result.totalNeptu % 7;
          return list[idx] as String? ?? result.pancasuda;
        }),
        description:
            'Pancasuda adalah kualitas energi jiwa berdasarkan total Neptu kelahiranmu. '
            'Ia menggambarkan sifat dasar dan pola hidup yang mengalir dalam dirimu.',
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────────

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
  final VoidCallback? onTap;

  const _AnalysisBadge({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: color.withValues(alpha: 0.5),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Detail Bottom Sheet ──────────────────────────────────────────────────

class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.future,
    required this.description,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Future<String> future;
  final String description;

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
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<String>(
            future: future,
            builder: (_, snap) {
              final text = snap.data ?? subtitle;
              return Text(
                text,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.withValues(alpha: 0.35)),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }
}
