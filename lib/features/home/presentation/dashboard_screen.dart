import 'dart:math';
import 'package:flutter/material.dart';
import '../../tarot/presentation/tarot_draw_screen.dart';
import '../../weton/presentation/weton_calculator_screen.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient with celestial shapes
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  Color(0xFF160E36),
                  Color(0xFF0C071C),
                ],
              ),
            ),
          ),
          // Star overlay simulation (subtle decoration)
          const _StarryBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // App Logo & Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'A E S T R A L',
                          style: textTheme.displayLarge?.copyWith(
                            letterSpacing: 6,
                            color: AppTheme.accentGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pintu Gerbang Takdir & Misteri Kosmis',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Dashboard cards / buttons
                  _DashboardCard(
                    title: 'Daily Tarot Draw',
                    subtitle: 'Tarik kartu tarot harian Anda untuk refleksi & panduan spiritual',
                    icon: Icons.auto_awesome,
                    accentColor: AppTheme.accentPink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TarotDrawScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _DashboardCard(
                    title: 'Primbon Weton Jawa',
                    subtitle: 'Temukan karakter bawaan, neptu, dan elemen berdasarkan penanggalan Asapon',
                    icon: Icons.calendar_month,
                    accentColor: AppTheme.accentPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WetonCalculatorScreen()),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                  // Footer info
                  Center(
                    child: Text(
                      'Aestral v1.0.0 • Zero-Budget High-Performance',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppTheme.textMuted.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered 
            ? (Matrix4.identity()..translate(0, -4, 0)) 
            : Matrix4.identity(),
        child: Card(
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.accentColor.withOpacity(0.15),
            highlightColor: widget.accentColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: textTheme.titleLarge?.copyWith(
                            color: _isHovered ? widget.accentColor : AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Chevron indicator
                  Icon(
                    Icons.chevron_right,
                    color: _isHovered ? widget.accentColor : AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarryBackground extends StatelessWidget {
  const _StarryBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarsPainter(),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Deterministic random generator so the stars don't flicker on repaint
    final random = Random(42);
    for (int i = 0; i < 40; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * 1.8 + 0.5;
      
      // Draw glow for some stars
      if (random.nextDouble() > 0.8) {
        final glowPaint = Paint()
          ..color = AppTheme.accentGold.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      }
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
