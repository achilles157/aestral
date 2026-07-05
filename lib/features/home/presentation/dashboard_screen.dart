import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/profile_service.dart';
import '../../tarot/presentation/tarot_draw_screen.dart';
import '../../weton/presentation/weton_calculator_screen.dart';
import '../../weton/presentation/astrological_planner_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import 'widgets/dashboard_carousel_card.dart';
import 'widgets/starry_background.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_rotationController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptBirthdate();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    super.dispose();
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

  Widget _buildCarouselDeck() {
    final items = [
      CarouselItem(
        title: 'Tarot & Soul Card',
        subtitle: 'Tarik Kartu Jiwa (statis) atau Tarot Mingguan (dinamis) berdasarkan siklus Wuku',
        icon: Icons.auto_awesome,
        accentColor: AppTheme.accentPink,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TarotDrawScreen()),
          );
        },
      ),
      CarouselItem(
        title: 'Primbon Weton Jawa',
        subtitle: 'Temukan karakter bawaan, neptu, dan elemen berdasarkan penanggalan Asapon',
        icon: Icons.brightness_medium,
        accentColor: AppTheme.accentPurple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WetonCalculatorScreen()),
          );
        },
      ),
      CarouselItem(
        title: 'Astrological Planner',
        subtitle: 'Kalender bulanan terintegrasi dan jadwal jam harian (timetable Saat Pitu)',
        icon: Icons.calendar_month,
        accentColor: AppTheme.accentGold,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AstrologicalPlannerScreen()),
          );
        },
      ),
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
        child: Column(
          children: [
            Row(
              children: [
                if (isDesktop)
                  IconButton(
                    iconSize: 28,
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.accentGold.withValues(alpha: _currentPage > 0 ? 1.0 : 0.2),
                    ),
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                Expanded(
                  child: SizedBox(
                    height: 380,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                            } else {
                              value = index == 0 ? 1.0 : 0.85;
                            }
                            
                            final double scale = value;
                            final double translation = (1 - value) * 15;

                            return Transform.translate(
                              offset: Offset(0, translation),
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            );
                          },
                          child: DashboardCarouselCard(
                            item: item,
                            isActive: _currentPage == index,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (isDesktop)
                  IconButton(
                    iconSize: 28,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.accentGold.withValues(alpha: _currentPage < items.length - 1 ? 1.0 : 0.2),
                    ),
                    onPressed: _currentPage < items.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 6,
                  width: isActive ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? items[index].accentColor 
                        : AppTheme.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
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
                  AppTheme.background.withValues(alpha: 0.85),
                  const Color(0xFF160E36).withValues(alpha: 0.95),
                  const Color(0xFF0C071C),
                ],
              ),
            ),
          ),
          // Star overlay simulation (subtle decoration)
          const StarryBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          // App Logo & Header
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    RotationTransition(
                                      turns: _rotationAnimation,
                                      child: CustomPaint(
                                        size: const Size(200, 200),
                                        painter: MandalaPainter(),
                                      ),
                                    ),
                                    // Golden Glowing Star Core in the center of Mandala
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentGold.withValues(alpha: 0.35),
                                            blurRadius: 24,
                                            spreadRadius: 3,
                                          )
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: AppTheme.accentGold,
                                        size: 36,
                                      ),
                                    ),
                                  ],
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
                                          color: AppTheme.accentGold.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.bold,
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
                          const SizedBox(height: 32),
                          // Celestial Carousel Deck
                          _buildCarouselDeck(),
                          const SizedBox(height: 40),
                          // Footer info
                          Center(
                            child: Text(
                              'Aestral v1.0.0 • Zero-Budget High-Performance',
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppTheme.textMuted.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
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


