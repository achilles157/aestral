import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import 'widgets/seasonal_banner.dart';
import '../domain/pranata_mangsa.dart';
import '../data/pranata_mangsa_repository.dart';
import 'widgets/astrological_planner_calendar_grid.dart';
import 'widgets/astrological_planner_timeline.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/astrological_dial_timepiece.dart';
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
  Map<String, dynamic>? _calendarData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileAndFetch();
  }

  Future<void> _loadProfileAndFetch() async {
    setState(() {
      _isLoadingCalendar = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(birthProfileProvider.future);
      if (profile.dobDate != null) {
        _birthDate = profile.dobDate;
      }
      
      _birthDate ??= DateTime(1995, 10, 25);
      await _fetchCalendarData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat profil atau kalender: $e';
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
    final session = ref.read(authProvider);
    String authHeader = 'Guest guest_user_123';
    
    if (session != null) {
      if (session.isMock) {
        authHeader = 'Guest ${session.uid}';
      } else {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) {
            authHeader = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('Planner: Gagal mendapatkan token Firebase: $e');
        }
      }
    }

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
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_birthDate != null)
                Text(
                  'Profil Lahir: ${DateFormat('dd MMM yyyy').format(_birthDate!)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.accentGold.withValues(alpha: 0.8),
                  ),
                ),
            ],
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
        actions: [
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
                'assets/images/app_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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
                      _buildPranataHeader(pranataListAsync),
                      const SizedBox(height: 16),
                      AstrologicalPlannerCalendarGrid(
                        calendarData: _calendarData!,
                        currentMonth: _currentMonth,
                        onDayTapped: _showDayDetailSheet,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

