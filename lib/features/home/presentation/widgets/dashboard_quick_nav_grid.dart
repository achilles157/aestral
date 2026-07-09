import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/shell_providers.dart';

/// Grid navigasi cepat ke 4 fitur utama: Tarot, Weton, Planner, Ba Zi.
class DashboardQuickNavGrid extends ConsumerWidget {
  final int crossAxisCount;
  final double childAspectRatio;

  const DashboardQuickNavGrid({
    super.key,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _NavItem(Icons.auto_awesome, 'Tarot', 'Soul Card & Kosmis',
          AppTheme.accentPink, 1),
      _NavItem(Icons.brightness_medium_rounded, 'Weton', 'Primbon Jawa',
          AppTheme.accentPurple, 2),
      _NavItem(Icons.calendar_month_rounded, 'Planner', 'Kalender Kosmis',
          AppTheme.accentGold, 3),
      _NavItem(Icons.grid_4x4_rounded, 'Ba Zi', '四柱八字',
          AppTheme.elementWater, 4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jelajahi',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textLight.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: items
              .map((item) => _NavTile(
                    item: item,
                    onTap: () => ref
                        .read(activeTabProvider.notifier)
                        .setTab(item.tabIndex),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int tabIndex;

  const _NavItem(
      this.icon, this.label, this.subtitle, this.color, this.tabIndex);
}

// ─── Tile widget ──────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: item.color.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: GoogleFonts.outfit(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              item.subtitle,
              style: GoogleFonts.outfit(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
