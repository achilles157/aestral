import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class CarouselItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  CarouselItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}

class DashboardCarouselCard extends StatefulWidget {
  final CarouselItem item;
  final bool isActive;

  const DashboardCarouselCard({
    super.key,
    required this.item,
    required this.isActive,
  });

  @override
  State<DashboardCarouselCard> createState() => _DashboardCarouselCardState();
}

class _DashboardCarouselCardState extends State<DashboardCarouselCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowRadius = widget.isActive ? _glowAnimation.value : 0.0;
        return GlassCard(
          borderRadius: 24,
          borderColor: widget.item.accentColor.withValues(alpha: widget.isActive ? 0.35 : 0.15),
          borderWidth: widget.isActive ? 1.5 : 1.0,
          boxShadow: [
            if (widget.isActive) ...[
              BoxShadow(
                color: widget.item.accentColor.withValues(alpha: 0.35),
                blurRadius: glowRadius,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: widget.item.accentColor.withValues(alpha: 0.15),
                blurRadius: glowRadius * 2,
                spreadRadius: 6,
              ),
            ],
          ],
          child: InkWell(
            onTap: widget.item.onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: widget.item.accentColor.withValues(alpha: 0.15),
            highlightColor: widget.item.accentColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Glowing Icon Container
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.item.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.item.accentColor.withValues(alpha: 0.15),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(
                        color: widget.item.accentColor.withValues(alpha: 0.4),
                        width: 2.0,
                      ),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: widget.item.accentColor,
                      size: 36,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Title
                  Text(
                    widget.item.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    widget.item.subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // Action button style indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.item.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.item.accentColor.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Jelajahi',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.item.accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right,
                          color: widget.item.accentColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
