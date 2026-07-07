import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/shell_providers.dart';
import 'dashboard_screen.dart';
import '../../tarot/presentation/tarot_draw_screen.dart';
import '../../weton/presentation/weton_calculator_screen.dart';
import '../../weton/presentation/astrological_planner_screen.dart';
import '../../bazi/presentation/bazi_calculator_screen.dart';

/// Root shell that hosts all primary tabs via an [IndexedStack].
/// Switch tabs from anywhere by writing to [activeTabProvider]:
///   ref.read(activeTabProvider.notifier).state = 2; // jump to Weton
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    TarotDrawScreen(),
    WetonCalculatorScreen(),
    AstrologicalPlannerScreen(),
    BaziCalculatorScreen(),
  ];

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded,            label: 'Beranda'),
    _NavItem(icon: Icons.auto_awesome,            label: 'Tarot'),
    _NavItem(icon: Icons.brightness_medium_rounded, label: 'Weton'),
    _NavItem(icon: Icons.calendar_month_rounded,  label: 'Planner'),
    _NavItem(icon: Icons.grid_4x4_rounded,        label: 'Ba Zi'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab   = ref.watch(activeTabProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        // Extend safe-area bottom so inner screens leave room for the floating nav bar
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            bottom: MediaQuery.of(context).padding.bottom + 88,
          ),
        ),
        child: IndexedStack(
          index: activeTab,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _CosmicNavBar(
        items: _items,
        activeIndex: activeTab,
        bottomInset: bottomInset,
        onTap: (i) => ref.read(activeTabProvider.notifier).setTab(i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}

// ---------------------------------------------------------------------------
// Glassmorphic pill nav bar
// ---------------------------------------------------------------------------

class _CosmicNavBar extends StatelessWidget {
  const _CosmicNavBar({
    required this.items,
    required this.activeIndex,
    required this.bottomInset,
    required this.onTap,
  });

  final List<_NavItem>   items;
  final int              activeIndex;
  final double           bottomInset;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.cardBg.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavButton(
                    item: items[i],
                    isActive: i == activeIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem   item;
  final bool       isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                  width: 1,
                ),
              )
            : const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: isActive ? 22 : 20,
              color: isActive ? AppTheme.accentGold : AppTheme.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppTheme.accentGold : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
