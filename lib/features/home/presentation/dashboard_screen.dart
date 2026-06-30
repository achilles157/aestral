import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/profile_service.dart';
import '../../tarot/presentation/tarot_draw_screen.dart';
import '../../weton/presentation/weton_calculator_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptBirthdate();
    });
  }

  Future<void> _checkAndPromptBirthdate() async {
    final profile = await ref.read(profileProvider).loadProfile();
    if (profile == null || profile['biometric_anchor']?['dob_utc_ms'] == null) {
      if (mounted) {
        _showBirthdatePrompt(context);
      }
    }
  }

  Future<void> _showBirthdatePrompt(BuildContext context) async {
    DateTime? selectedDate;
    
    await showDialog(
      context: context,
      barrierDismissible: false, // Must fill it
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    'Identitas Kosmis',
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Untuk menganalisis Weton lahir dan kartu Tarot personal Anda secara konsisten, silakan masukkan tanggal kelahiran Anda.',
                    style: TextStyle(color: AppTheme.textLight, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: AppTheme.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      selectedDate == null
                          ? 'Pilih Tanggal Lahir'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime(2000, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.accentPurple,
                                onPrimary: AppTheme.textLight,
                                surface: AppTheme.cardBg,
                                onSurface: AppTheme.textLight,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: selectedDate == null
                      ? null
                      : () async {
                          final weton = WetonUtils.calculateWeton(selectedDate!);
                          await ref.read(profileProvider).saveProfile(
                            dob: selectedDate!,
                            latitude: -6.2088,
                            longitude: 106.8456,
                            weton: weton,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Identitas kosmis berhasil diselaraskan!'),
                                backgroundColor: AppTheme.accentPurple,
                              ),
                            );
                          }
                        },
                  child: Text(
                    'Simpan & Lanjutkan',
                    style: TextStyle(
                      color: selectedDate == null
                          ? AppTheme.textMuted
                          : AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background image with dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/app_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.25, // subtle celestial blending
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background.withOpacity(0.85),
                  const Color(0xFF160E36).withOpacity(0.95),
                  const Color(0xFF0C071C),
                ],
              ),
            ),
          ),
          // Star overlay simulation (subtle decoration)
          const _StarryBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 30),
                            // App Logo & Header
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.accentGold.withOpacity(0.2),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        )
                                      ]
                                    ),
                                    child: Image.asset(
                                      'assets/images/aestral_logo.png',
                                      height: 120,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'A E S T R A L',
                                    style: textTheme.displayLarge?.copyWith(
                                      letterSpacing: 6,
                                      color: AppTheme.accentGold,
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pintu Gerbang Takdir & Misteri Kosmis',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (session != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Aktif: ${session.displayName}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.accentGold.withOpacity(0.8),
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentGold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
                                          tooltip: 'Keluar',
                                          onPressed: () {
                                            ref.read(authProvider.notifier).signOut();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
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
                  ),
                );
              }
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
