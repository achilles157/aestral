import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/bazi_chart.dart';
import '../widgets/bazi_pillar_column.dart';

/// Horizontal scrollable strip showing Da Yun (大運) luck pillar decades.
///
/// Replaces the previous circular pie wheel. Da Yun is a linear timeline
/// (birth → old age), so a horizontal strip is both more readable and
/// conceptually accurate.
class DaYunStripWidget extends StatefulWidget {
  const DaYunStripWidget({
    super.key,
    required this.pillars,
    required this.selectedIdx,
    required this.onDecadeSelected,
  });

  final List<LuckPillar> pillars;
  final int selectedIdx;
  final ValueChanged<int> onDecadeSelected;

  @override
  State<DaYunStripWidget> createState() => _DaYunStripWidgetState();
}

class _DaYunStripWidgetState extends State<DaYunStripWidget> {
  late final ScrollController _scrollCtrl;

  static const double _cardW = 84.0;
  static const double _activeCardW = 100.0;
  static const double _cardH = 76.0;
  static const double _spacing = 8.0;
  static const double _hPad = 16.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(DaYunStripWidget old) {
    super.didUpdateWidget(old);
    if (old.selectedIdx != widget.selectedIdx) {
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    if (!_scrollCtrl.hasClients) return;
    // All cards before selectedIdx have width _cardW + _spacing
    final offset = _hPad + widget.selectedIdx * (_cardW + _spacing);
    final viewportWidth = _scrollCtrl.position.viewportDimension;
    final target = (offset - viewportWidth / 2 + _activeCardW / 2)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pillars.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _cardH + 24, // extra for glow + shadow overflow
      child: ListView.separated(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 8),
        itemCount: widget.pillars.length,
        separatorBuilder: (_, _) => const SizedBox(width: _spacing),
        itemBuilder: (_, i) => _DecadeCard(
          luckPillar: widget.pillars[i],
          isActive: i == widget.selectedIdx,
          onTap: () => widget.onDecadeSelected(i),
        ),
      ),
    );
  }
}

class _DecadeCard extends StatelessWidget {
  const _DecadeCard({
    required this.luckPillar,
    required this.isActive,
    required this.onTap,
  });

  final LuckPillar luckPillar;
  final bool isActive;
  final VoidCallback onTap;

  static const double _cardW = 84.0;
  static const double _activeCardW = 100.0;
  static const double _cardH = 76.0;

  @override
  Widget build(BuildContext context) {
    final elementColor =
        kBaziElementColors[luckPillar.pillar.element] ?? Colors.white;
    final cardWidth = isActive ? _activeCardW : _cardW;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: cardWidth,
        height: _cardH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Ambient glow underneath active card
            if (isActive)
              Positioned(
                bottom: -4,
                left: 10,
                right: 10,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: elementColor.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            // Glassmorphic card body
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: cardWidth,
                  height: _cardH,
                  decoration: BoxDecoration(
                    color: isActive
                        ? elementColor.withValues(alpha: 0.13)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? elementColor.withValues(alpha: 0.65)
                          : Colors.white12,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stem + Branch hanzi symbols
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: elementColor.withValues(
                            alpha: isActive ? 1.0 : 0.50,
                          ),
                          fontSize: isActive ? 21 : 17,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        child: Text(
                          '${luckPillar.pillar.stemSymbol}${luckPillar.pillar.branchSymbol}',
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Age range
                      Text(
                        '${luckPillar.startAge}–${luckPillar.endAge}',
                        style: GoogleFonts.outfit(
                          color: isActive
                              ? elementColor.withValues(alpha: 0.85)
                              : Colors.white38,
                          fontSize: isActive ? 11 : 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Active indicator dot — bottom center
            if (isActive)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elementColor,
                    boxShadow: [
                      BoxShadow(
                        color: elementColor.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
