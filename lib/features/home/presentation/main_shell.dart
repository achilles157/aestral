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
        child: _FadingIndexedStack(
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
// Fading IndexedStack — smooth opacity transition saat ganti tab
// ---------------------------------------------------------------------------

class _FadingIndexedStack extends StatefulWidget {
  const _FadingIndexedStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_FadingIndexedStack> createState() => _FadingIndexedStackState();
}

class _FadingIndexedStackState extends State<_FadingIndexedStack> {
  int _currentIndex = 0;
  double _opacity = 1.0;
  Offset _slideOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
  }

  @override
  void didUpdateWidget(_FadingIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      // Slide + fade out, switch index, slide + fade in
      final bool goingRight = widget.index > oldWidget.index;
      setState(() {
        _opacity = 0.0;
        _slideOffset = Offset(goingRight ? 0.04 : -0.04, 0);
      });
      Future.delayed(const Duration(milliseconds: 130), () {
        if (mounted) {
          setState(() {
            _currentIndex = widget.index;
            _opacity = 1.0;
            _slideOffset = Offset.zero;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _slideOffset,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeIn,
        child: IndexedStack(
          index: _currentIndex,
          children: widget.children,
        ),
      ),
    );
  }
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
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                  Semantics(
                    label: '${items[i].label}, tab ${i + 1} dari ${items.length}',
                    selected: i == activeIndex,
                    button: true,
                    excludeSemantics: true,
                    child: _NavButton(
                      item: items[i],
                      isActive: i == activeIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem     item;
  final bool         isActive;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: widget.isActive
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
                widget.item.icon,
                size: widget.isActive ? 22 : 20,
                color: widget.isActive
                    ? AppTheme.accentGold
                    : AppTheme.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                widget.item.label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: widget.isActive
                      ? AppTheme.accentGold
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
