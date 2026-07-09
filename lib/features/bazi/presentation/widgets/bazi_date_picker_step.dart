import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

/// Step 0 — pemilihan tanggal lahir.
class BaziDatePickerStep extends StatelessWidget {
  final int step;
  final DateTime? birthDate;
  final VoidCallback onPickDate;
  final VoidCallback? onNext;

  const BaziDatePickerStep({
    super.key,
    required this.step,
    required this.birthDate,
    required this.onPickDate,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(active: step),
          const SizedBox(height: 32),
          Text(
            'Tanggal Lahir',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digunakan untuk menghitung 4 Pilar Ba Zi berdasarkan siklus kalender surya.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onPickDate,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.accentGold, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      birthDate == null
                          ? 'Ketuk untuk memilih tanggal...'
                          : '${birthDate!.day} / ${birthDate!.month} / ${birthDate!.year}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: birthDate == null ? Colors.white38 : Colors.white,
                        fontWeight: birthDate == null ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (birthDate != null)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4ADE80), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          _BaziPrimaryButton(label: 'Lanjut →', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Private shared UI helpers ────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int active;
  const _StepIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done    = i < active;
        final current = i == active;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: done
                  ? AppTheme.accentGold
                  : current
                      ? AppTheme.accentPurple
                      : Colors.white12,
            ),
          ),
        );
      }),
    );
  }
}

class _BaziPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _BaziPrimaryButton({required this.label, this.onTap, });

  @override
  Widget build(BuildContext context) {
    const btnColor = AppTheme.accentPurple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onTap != null ? btnColor.withValues(alpha: 0.85) : Colors.white12,
          boxShadow: onTap != null
              ? [BoxShadow(color: btnColor.withValues(alpha: 0.35), blurRadius: 16)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: onTap != null ? Colors.white : Colors.white30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
