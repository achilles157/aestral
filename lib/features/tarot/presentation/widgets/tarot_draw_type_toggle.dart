import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Toggle pill antara "Tarot Kosmis (Mangsa)" dan "Tarot Lahir (Birth)".
/// Hanya ditampilkan untuk user authenticated saat belum ada kartu tertarik.
class TarotDrawTypeToggle extends StatelessWidget {
  final String selectedDrawType;
  final String currentLang;
  final void Function(String drawType) onTypeChanged;
  final bool isLocked;

  const TarotDrawTypeToggle({
    super.key,
    required this.selectedDrawType,
    required this.currentLang,
    required this.onTypeChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: currentLang == 'id' ? 'Tarot Kosmis' : 'Cosmic Tarot',
            isActive: selectedDrawType == 'mangsa',
            isLocked: isLocked,
            onTap: () => onTypeChanged('mangsa'),
          ),
          _Pill(
            label: currentLang == 'id' ? 'Tarot Lahir' : 'Birth Tarot',
            isActive: selectedDrawType == 'birth',
            isLocked: false,
            onTap: () => onTypeChanged('birth'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.lock_rounded,
                  size: 10,
                  color: Colors.white38,
                ),
              ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isActive
                    ? AppTheme.textLight
                    : AppTheme.textLight.withValues(
                        alpha: isLocked ? 0.35 : 0.6,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
