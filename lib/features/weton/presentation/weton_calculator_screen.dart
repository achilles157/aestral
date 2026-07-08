import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/models/birth_profile.dart';
import '../../auth/services/auth_service.dart';
import '../services/weton_dictionary_service.dart';
import '../../../core/services/api_service.dart';
import '../data/pranata_mangsa_repository.dart';
import 'widgets/seasonal_banner.dart';
import 'components/weton_detail_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/ai/presentation/oracle_chat_screen.dart';
import 'widgets/javanese_astrological_gear_dial.dart';
import 'widgets/weton_element_mandala.dart';
import 'widgets/daily_insight_card.dart';
import 'weton_compatibility_screen.dart';

class WetonCalculatorScreen extends ConsumerStatefulWidget {
  const WetonCalculatorScreen({super.key});

  @override
  ConsumerState<WetonCalculatorScreen> createState() => _WetonCalculatorScreenState();
}

class _WetonCalculatorScreenState extends ConsumerState<WetonCalculatorScreen> {
  DateTime? _selectedDate;
  
  WetonInfo? _result;
  bool _isSaving = false;
  Map<String, dynamic>? _dailyInsightData;
  bool _isLoadingDaily = false;

  /// Safely parses a hex color string (e.g. "#RRGGBB") into a [Color].
  /// Returns null if the string is null, malformed, or not exactly 6 hex digits.
  Color? _parseHexColor(String? hexWithHash) {
    if (hexWithHash == null) return null;
    try {
      final hex = hexWithHash.replaceAll('#', '');
      if (hex.length != 6) return null;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      debugPrint('_parseHexColor: invalid value "$hexWithHash"');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedProfileAndCalculate();
  }

  Future<void> _loadSavedProfileAndCalculate() async {
    final profile = await ref.read(birthProfileProvider.future);
    if (profile.dobDate != null) {
      if (mounted) {
        setState(() {
          _selectedDate = profile.dobDate!;
        });
        _handleCalculate();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentPurple,
            onPrimary: Colors.white,
            surface: AppTheme.cardBg,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleCalculate() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Pilih tanggal lahir terlebih dahulu!'),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    
    final dob = _selectedDate!;
    setState(() {
      _result = WetonUtils.calculateWeton(dob);
      _isLoadingDaily = true;
    });

    final session = ref.read(authProvider);
    String authHeader = 'Guest anonymous';
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
          debugPrint('Error getting ID token: $e');
        }
      }
    }

    final birthDateStr = "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";

    try {
      final response = await ApiService.getWetonDaily(
        birthDate: birthDateStr,
        authHeader: authHeader,
      );

      if (mounted) {
        setState(() {
          _dailyInsightData = response['data'] as Map<String, dynamic>?;
          _isLoadingDaily = false;
        });
      }
    } catch (e) {
      debugPrint('Weton daily API failed, using offline calculation: $e');
      final birthWeton = WetonUtils.calculateWeton(dob);
      final todayWeton = WetonUtils.calculateWeton(DateTime.now());
      final sisaBagi = (birthWeton.totalNeptu + todayWeton.totalNeptu) % 5;
      final targetWukuIndex = WetonUtils.wukuNames.indexOf(todayWeton.wuku);
      final birthPranataId = WetonUtils.calculatePranataMangsaId(dob);
      final targetPranataId = WetonUtils.calculatePranataMangsaId(DateTime.now());

      if (mounted) {
        setState(() {
          _dailyInsightData = {
            'birthWeton': {
              'pranataMangsaId': birthPranataId,
            },
            'targetWeton': {
              'pranataMangsaId': targetPranataId,
            },
            'daily': {
              'sisaBagi': sisaBagi,
              'fase': sisaBagi == 1
                  ? 'Sandang'
                  : sisaBagi == 2
                      ? 'Pangan'
                      : sisaBagi == 3
                          ? 'Gedhong'
                          : sisaBagi == 4
                              ? 'Loro'
                              : 'Pati',
            },
            'weekly': {
              'wukuIndex': targetWukuIndex + 1,
              'wukuName': todayWeton.wuku,
            }
          };
          _isLoadingDaily = false;
        });
      }
    }

    // Persist birth date to profile so other features auto-fill
    final current = ref.read(birthProfileProvider).value ?? const BirthProfile();
    ref.read(birthProfileProvider.notifier).saveAll(
      dob: dob,
      birthHour: current.birthHour,
      latitude: current.latitude ?? 0.0,
      longitude: current.longitude ?? 0.0,
      cityName: current.cityName ?? '',
      gender: current.gender,
    ).catchError((e) {
      debugPrint('WetonCalculatorScreen: auto-save birth profile error: $e');
    });
  }

  void _handleSaveProfile() async {
    if (_result == null || _selectedDate == null) return;
    
    setState(() => _isSaving = true);
    
    bool success = false;
    try {
      final current = ref.read(birthProfileProvider).value ?? const BirthProfile();
      await ref.read(birthProfileProvider.notifier).saveAll(
        dob: _selectedDate!,
        birthHour: current.birthHour,
        latitude: current.latitude ?? 0.0,
        longitude: current.longitude ?? 0.0,
        cityName: current.cityName ?? '',
        gender: current.gender,
      );
      success = true;
    } catch (e) {
      debugPrint('WetonCalculatorScreen: save error — $e');
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Profil berhasil disimpan ke takdir Anda!' : 'Gagal menyimpan profil.'),
            ],
          ),
          backgroundColor: success ? AppTheme.accentPurple : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dictionaryAsync = ref.watch(wetonDictionaryProvider);
    final sisaBagiAsync = ref.watch(sisaBagiProvider);
    final wukuAsync = ref.watch(wukuProvider);
    final pranataMangsaAsync = ref.watch(pranataMangsaListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Primbon Weton',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          // Starry space image background layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/weton_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient dark overlay to keep high visual readability and glassmorphism contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.82),
                    const Color(0xFF130E30).withValues(alpha: 0.88),
                    const Color(0xFF0A0618).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                    Text(
                      'Pahami watak bawaan lahir dan elemen spiritual Anda berdasarkan keselarasan kalender Jawa.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Date picker card (replaces stepped wizard)
                    GlassCard(
                      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
                      borderWidth: 1.2,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_outline, color: AppTheme.accentGold, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'TANGGAL LAHIR KOSMIS',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pilih tanggal lahir untuk menyelaraskan energi Weton Anda.',
                            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Date display & button
                          GestureDetector(
                            onTap: _presentDatePicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.accentPurple.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: AppTheme.accentGold, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Tentukan Tanggal Lahir...'
                                          : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                                      style: GoogleFonts.outfit(
                                        color: _selectedDate == null ? Colors.white38 : AppTheme.textLight,
                                        fontSize: 15,
                                        fontWeight: _selectedDate == null ? FontWeight.w400 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.edit, color: AppTheme.accentPurple, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _handleCalculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPurple,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hitung Primbon Weton',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.auto_awesome, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Calculation Results
                    if (_result != null)
                      dictionaryAsync.when(
                        data: (dictionary) {
                          final wetonName = '${_result!.saptawara} ${_result!.pancawara}';
                          final entry = lookupWetonEntry(dictionary, wetonName);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Weton Header Title
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'WETON LAHIR',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          wetonName,
                                          style: textTheme.displayLarge?.copyWith(
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                        if (entry?.warnaHarmoni != null) ...[
                                          const SizedBox(width: 12),
                                          Builder(
                                            builder: (context) {
                                              Color? harmoniColor = _parseHexColor(entry!.warnaHarmoni);
                                              if (harmoniColor == null) return const SizedBox.shrink();
                                              return Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: harmoniColor,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: harmoniColor.withValues(alpha: 0.8),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (entry != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '"${entry.headline}"',
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.accentGold.withValues(alpha: 0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              WetonElementMandala(
                                saptawara: _result!.saptawara,
                                pancawara: _result!.pancawara,
                              ),
                              const SizedBox(height: 20),
                              // Technical Details (Direct Display)
                              GlassCard(
                                borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
                                borderWidth: 1.2,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📜 Sandi Angka Kelahiran',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 16,
                                        color: AppTheme.accentPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    JavaneseAstrologicalGearDial(
                                      saptawara: _result!.saptawara,
                                      pancawara: _result!.pancawara,
                                      wuku: _result!.wuku,
                                      totalNeptu: _result!.totalNeptu,
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: Color(0xFF2E2452), height: 20, thickness: 1.5),
                                    const SizedBox(height: 16),
                                    _DetailRow(
                                      label: 'Kalender Jawa Asapon',
                                      value: '${_result!.javaneseDay} ${_result!.javaneseMonth} ${_result!.javaneseYear} (${_result!.javaneseYearName})',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: 'Wuku', value: _result!.wuku),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: 'Neptu Saptawara', value: '${_result!.saptawara} (${_result!.neptuSaptawara})'),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: 'Neptu Pancawara', value: '${_result!.pancawara} (${_result!.neptuPancawara})'),
                                    const SizedBox(height: 20),
                                    Text(
                                      'TOTAL NEPTU: ${_result!.totalNeptu} / 18',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: AppTheme.accentGold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: _result!.totalNeptu / 18,
                                        backgroundColor: AppTheme.background,
                                        color: AppTheme.accentPurple,
                                        minHeight: 10,
                                      ),
                                    ),
                                    const Divider(color: Color(0xFF2E2452), height: 40, thickness: 1.5),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _AnalysisBadge(label: 'Pangarasan', value: _result!.pangarasan, color: AppTheme.accentPurple),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _AnalysisBadge(label: 'Pancasuda', value: _result!.pancasuda, color: AppTheme.accentPink),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              if (entry != null) ...[
                                // 3 Main Cards — sejajar di layar lebar, vertikal di layar sempit
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final useRow = constraints.maxWidth >= 380;
                                    final cards = [
                                      WetonDetailCard(
                                        title: 'Karier & Rezeki',
                                        content: entry.karirRezeki,
                                        icon: Icons.work_outline,
                                        accentColor: AppTheme.accentGold,
                                        margin: EdgeInsets.zero,
                                      ),
                                      WetonDetailCard(
                                        title: 'Asmara & Hubungan',
                                        content: entry.asmaraHubungan,
                                        icon: Icons.favorite_border,
                                        accentColor: AppTheme.accentPink,
                                        margin: EdgeInsets.zero,
                                      ),
                                      WetonDetailCard(
                                        title: 'Sisi Gelap & Peringatan',
                                        content: entry.sisiGelapPeringatan,
                                        icon: Icons.warning_amber_outlined,
                                        accentColor: const Color(0xFFF87171),
                                        margin: EdgeInsets.zero,
                                      ),
                                    ];
                                    if (useRow) {
                                      return IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(child: cards[0]),
                                            const SizedBox(width: 12),
                                            Expanded(child: cards[1]),
                                            const SizedBox(width: 12),
                                            Expanded(child: cards[2]),
                                          ],
                                        ),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        cards[0],
                                        const SizedBox(height: 12),
                                        cards[1],
                                        const SizedBox(height: 12),
                                        cards[2],
                                      ],
                                    );
                                  },
                                ),
                                 if (entry.saranHarian != null && entry.saranHarian!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Builder(
                                      builder: (context) {
                                        final Color? harmoniColor = _parseHexColor(entry.warnaHarmoni);
                                        final themeColor = harmoniColor ?? AppTheme.accentGold;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: themeColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: themeColor.withValues(alpha: 0.3),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.lightbulb_outline, color: themeColor, size: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  entry.saranHarian!,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    height: 1.4,
                                                    color: AppTheme.textLight.withValues(alpha: 0.9),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                 const SizedBox(height: 16),
                                 ElevatedButton.icon(
                                   onPressed: () async {
                                     final session = ref.read(authProvider);
                                     String authHeader;
                                     if (session == null || session.isMock) {
                                       authHeader = 'Guest ${session?.uid ?? 'anonymous'}';
                                     } else {
                                       // Firebase ID Token (signed JWT) — never send plain UID as bearer
                                       final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
                                       authHeader = idToken != null ? 'Bearer $idToken' : 'Guest ${session.uid}';
                                     }
                                     
                                     if (!context.mounted) return;
                                     Navigator.of(context).push(
                                       MaterialPageRoute(
                                         builder: (_) => OracleChatScreen(
                                           oracleType: 'weton',
                                           authHeader: authHeader,
                                           aiContext: {
                                             'wetonLahir': {
                                               'nama': '${_result!.saptawara} ${_result!.pancawara}',
                                               'neptu': _result!.totalNeptu,
                                               'elemen': '',
                                               'karakter': _result!.characterSummary,
                                             },
                                             'pangarasan': _result!.pangarasan,
                                           },
                                         ),
                                       ),
                                     );
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.2),
                                     foregroundColor: Colors.white,
                                     side: BorderSide(
                                       color: _parseHexColor(entry.warnaHarmoni) ?? AppTheme.accentPurple,
                                       width: 1.5,
                                     ),
                                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(16),
                                     ),
                                     elevation: 0,
                                   ),
                                   icon: Icon(
                                     Icons.auto_awesome,
                                     color: _parseHexColor(entry.warnaHarmoni) ?? AppTheme.accentGold,
                                     size: 18,
                                   ),
                                   label: Text(
                                     'Tanyakan Orakel Weton Lahir Anda',
                                     style: GoogleFonts.outfit(
                                       fontSize: 14,
                                       fontWeight: FontWeight.bold,
                                       letterSpacing: 1.0,
                                     ),
                                   ),
                                 ),
                                 const SizedBox(height: 24),
                               ],
                              const SizedBox(height: 12),
                              // Daily Insight Section
                              if (_isLoadingDaily) ...[
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: CircularProgressIndicator(color: AppTheme.accentGold),
                                  ),
                                ),
                              ] else if (_dailyInsightData != null) ...[
                                // Semua provider dimuat — tampilkan satu spinner terpadu
                                // hingga ketiganya siap, lalu reveal sekaligus
                                Builder(
                                  builder: (context) {
                                    final allLoading = sisaBagiAsync.isLoading ||
                                        wukuAsync.isLoading ||
                                        pranataMangsaAsync.isLoading;
                                    final anyError = sisaBagiAsync.hasError ||
                                        wukuAsync.hasError ||
                                        pranataMangsaAsync.hasError;

                                    if (allLoading) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 32.0),
                                          child: CircularProgressIndicator(
                                            color: AppTheme.accentPurple,
                                          ),
                                        ),
                                      );
                                    }

                                    if (anyError) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Text(
                                            'Gagal memuat data harian.',
                                            style: GoogleFonts.outfit(
                                              color: AppTheme.accentPink,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final sisaBagiList = sisaBagiAsync.value!;
                                    final wukuList = wukuAsync.value!;
                                    final pranataList = pranataMangsaAsync.value!;

                                    final dailyInfo = _dailyInsightData!['daily'] as Map<String, dynamic>;
                                    final weeklyInfo = _dailyInsightData!['weekly'] as Map<String, dynamic>;
                                    final targetWetonInfo = _dailyInsightData!['targetWeton'] as Map<String, dynamic>?;

                                    final sisaBagiVal = dailyInfo['sisaBagi'] as int;
                                    final wukuIndex = weeklyInfo['wukuIndex'] as int;
                                    final wukuName = weeklyInfo['wukuName'] as String;

                                    final sisaBagiEntry = sisaBagiList.firstWhere(
                                      (s) => s['sisa_bagi'] == sisaBagiVal,
                                      orElse: () => sisaBagiList.first,
                                    );
                                    final wukuEntry = wukuList.firstWhere(
                                      (w) =>
                                          w['id'] == wukuIndex ||
                                          w['id'] == wukuIndex + 1 ||
                                          w['nama_wuku'].toString().toLowerCase() == wukuName.toLowerCase(),
                                      orElse: () => wukuList.first,
                                    );
                                    final targetPranataId = targetWetonInfo?['pranataMangsaId'] as int? ?? 1;
                                    final targetPranata = pranataList.firstWhere(
                                      (m) => m.id == targetPranataId,
                                      orElse: () => pranataList.first,
                                    );

                                    return Column(
                                      children: [
                                        DailyInsightCard(sisaBagi: sisaBagiEntry, wuku: wukuEntry),
                                        const SizedBox(height: 20),
                                        SeasonalBanner(mangsa: targetPranata),
                                      ],
                                    );
                                  },
                                ),
                              ],
                              // Save profile button (Cloud Sync / SharedPreferences)
                              _isSaving
                                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
                                  : ElevatedButton.icon(
                                      onPressed: _handleSaveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentPurple,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      icon: const Icon(Icons.cloud_upload_outlined),
                                      label: const Text('Simpan Profil Saya'),
                                    ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const WetonCompatibilityScreen(),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.accentGold, width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: AppTheme.accentGold,
                                ),
                                icon: const Icon(Icons.favorite_rounded, size: 18),
                                label: Text(
                                  'Kompatibilitas Pasangan',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(color: AppTheme.accentPurple),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'Gagal memuat kamus weton: $err',
                            style: const TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ),
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalysisBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}


