import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/utils/weton_utils.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import 'widgets/seasonal_banner.dart';
import '../domain/pranata_mangsa.dart';
import '../data/pranata_mangsa_repository.dart';
import 'widgets/astrological_planner_calendar_grid.dart';
import 'widgets/astrological_planner_timeline.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/astrological_dial_timepiece.dart';
import '../../../core/widgets/cosmic_auth_bottom_sheet.dart';
import '../../../core/widgets/glass_button.dart';

class AstrologicalPlannerScreen extends ConsumerStatefulWidget {
  const AstrologicalPlannerScreen({super.key});

  @override
  ConsumerState<AstrologicalPlannerScreen> createState() => _AstrologicalPlannerScreenState();
}

class _AstrologicalPlannerScreenState extends ConsumerState<AstrologicalPlannerScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _birthDate;
  bool _isLoadingCalendar = false;
  bool _isUsingFallbackDate = false;
  Map<String, dynamic>? _calendarData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileAndFetch();
  }

  Future<void> _loadProfileAndFetch() async {
    final authState = ref.read(authProvider);
    final isGuest = authState == null || authState.isMock;
    if (isGuest) {
      setState(() {
        _isLoadingCalendar = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoadingCalendar = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(birthProfileProvider.future);
      if (profile.dobDate != null) {
        _birthDate = profile.dobDate;
        _isUsingFallbackDate = false;
      } else {
        // No birth profile saved — use placeholder so the calendar can still
        // render, but flag it so the UI can warn the user.
        _birthDate = DateTime(1995, 10, 25);
        _isUsingFallbackDate = true;
      }
      await _fetchCalendarData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat profil. Pastikan profilmu sudah dilengkapi dan internet tersambung.';
          _isLoadingCalendar = false;
        });
      }
    }
  }

  Future<void> _fetchCalendarData() async {
    if (_birthDate == null) return;

    setState(() {
      _isLoadingCalendar = true;
      _errorMessage = null;
    });

    final birthStr = DateFormat('yyyy-MM-dd').format(_birthDate!);
    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

    try {
      final response = await ApiService.getCalendarMonth(
        birthDate: birthStr,
        targetYear: _currentMonth.year,
        targetMonth: _currentMonth.month,
        authHeader: authHeader,
      );

      if (mounted) {
        setState(() {
          _calendarData = response;
          _isLoadingCalendar = false;
        });
      }
    } catch (e) {
      debugPrint('Planner API gagal: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi ke backend gagal. Fitur kalender memerlukan koneksi online.';
          _isLoadingCalendar = false;
        });
      }
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      _calendarData = null;
    });
    _fetchCalendarData();
  }

  void _presentDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AstrologicalDialTimepiece(
          initialDateTime: _birthDate ?? DateTime(2000, 1, 1),
          showTime: false,
          onDateTimeSelected: (dt) {
            if (dt != _birthDate) {
              setState(() {
                _birthDate = dt;
                _calendarData = null;
              });
              _fetchCalendarData();
            }
          },
        );
      },
    );
  }



  Widget _buildHeaderSection() {
    return GlassCard(
      borderColor: AppTheme.accentGold.withValues(alpha: 0.25),
      borderWidth: 1.0,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.accentGold),
            onPressed: () => _changeMonth(-1),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_birthDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Profil Lahir: ${DateFormat('dd MMM yyyy').format(_birthDate!)}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.accentGold.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.accentGold),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildPranataHeader(AsyncValue<List<PranataMangsaModel>> pranataListAsync) {
    final pranataInfo = _calendarData!['pranata_mangsa'] as Map<String, dynamic>?;
    if (pranataInfo == null) return const SizedBox.shrink();

    final mangsaId = pranataInfo['id'] as int? ?? 1;

    return pranataListAsync.when(
      data: (list) {
        final activeMangsa = list.firstWhere(
          (m) => m.id == mangsaId,
          orElse: () => list.first,
        );
        return SeasonalBanner(mangsa: activeMangsa);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
      error: (e, _) => const SizedBox.shrink(),
    );
  }



  void _showDayDetailSheet(Map<String, dynamic> dayData) {
    final dateStr = dayData['date'] as String;
    final date = DateTime.parse(dateStr);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(date),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Weton: ${dayData['weton_hari_ini']} (Neptu ${dayData['neptu']})',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AstrologicalPlannerTimeline(
                    dayData: dayData,
                    scrollController: scrollController,
                    birthDate: _birthDate,
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
    final pranataListAsync = ref.watch(pranataMangsaListProvider);
    final authState = ref.watch(authProvider);
    final isGuest = authState == null || authState.isMock;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Astrological Planner',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: isGuest
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.cake_outlined, color: AppTheme.accentGold),
                  onPressed: _presentDatePicker,
                  tooltip: 'Sesuaikan Tanggal Lahir',
                )
              ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  Color(0xFF130E30),
                  Color(0xFF0A0618),
                ],
              ),
            ),
          ),
          // Cosmic star overlay for glassmorphism depth
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/planner_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          isGuest
              ? _buildGuestPreview()
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 16),
                    if (_isLoadingCalendar) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60.0),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.accentGold),
                        ),
                      ),
                    ] else if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              GlassButton(
                                onPressed: _fetchCalendarData,
                                icon: const Icon(Icons.refresh, color: AppTheme.textLight, size: 20),
                                label: const Text('Coba Lagi'),
                                glowColor: AppTheme.accentPurple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_calendarData != null) ...[
                      // Warn user if birth date is a placeholder, not their real profile
                      if (_isUsingFallbackDate)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.40),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Kalender ini menggunakan tanggal lahir contoh. '
                                  'Isi profil lahir Anda untuk hasil yang akurat.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.orange.shade200,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _presentDatePicker,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Isi Profil',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildPranataHeader(pranataListAsync),
                      const SizedBox(height: 16),
                      AstrologicalPlannerCalendarGrid(
                        calendarData: _calendarData!,
                        currentMonth: _currentMonth,
                        onDayTapped: _showDayDetailSheet,
                        birthWetonStr: _birthDate != null
                            ? () {
                                final w = WetonUtils.calculateWeton(_birthDate!);
                                return '${w.saptawara} ${w.pancawara}';
                              }()
                            : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Preview berembun untuk tamu — kalender statis diblur + CTA di bawah.
  Widget _buildGuestPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred mock calendar
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: IgnorePointer(child: _buildMockCalendar()),
        ),
        // Gradient fade to bottom
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE60D0D1A)],
              stops: [0.25, 0.75],
            ),
          ),
        ),
        // Compact CTA
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hari baikmu menunggumu',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Simpan profil kosmismu untuk membuka kalender keberuntungan personal.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final success =
                                await CosmicAuthBottomSheet.show(context);
                            if (success == true) _loadProfileAndFetch();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE5C07B), Color(0xFFBA8B32)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGold
                                      .withValues(alpha: 0.30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Simpan & Buka Planner',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kalender statis palsu — hanya untuk efek preview blur pada tamu.
  Widget _buildMockCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    // Pola deterministik: hari ke-7 & ke-5 = emas, hari ke-3 = merah
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.accentGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: daysInMonth,
            itemBuilder: (_, i) {
              final day = i + 1;
              final color = (day % 7 == 0 || day % 5 == 0)
                  ? AppTheme.accentGold.withValues(alpha: 0.55)
                  : (day % 3 == 0)
                      ? Colors.red.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.07);
              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

