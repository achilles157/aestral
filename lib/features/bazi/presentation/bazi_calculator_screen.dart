import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bazi_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/city_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/city_search_sheet.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../domain/bazi_chart.dart';
import '../services/bazi_data_service.dart';
import 'widgets/bazi_four_pillars_chart.dart';
import 'widgets/bazi_day_master_card.dart';
import 'widgets/bazi_element_balance_card.dart';
import 'widgets/bazi_pillar_column.dart';
import 'widgets/bazi_luck_pillars_widget.dart';
import 'widgets/bazi_ten_gods_widget.dart';
import 'widgets/bazi_strength_card.dart';
import 'widgets/bazi_relations_card.dart';
import 'widgets/bazi_annual_pillar_card.dart';
import '../../../features/ai/presentation/oracle_chat_screen.dart';

class BaziCalculatorScreen extends ConsumerStatefulWidget {
  const BaziCalculatorScreen({super.key});

  @override
  ConsumerState<BaziCalculatorScreen> createState() =>
      _BaziCalculatorScreenState();
}

class _BaziCalculatorScreenState
    extends ConsumerState<BaziCalculatorScreen> {
  int _step = 0;
  DateTime? _birthDate;
  int? _birthHour;
  bool _includeHour = false;
  CityPreset _selectedCity =
      const CityPreset(name: 'Jakarta', latitude: -6.2088, longitude: 106.8456);
  List<CityPreset> _allCities = [];

  BaziChart? _chart;
  bool _isLoading = false;
  String? _errorMsg;

  // Luck Pillars
  bool? _isMale;
  List<LuckPillar>? _luckPillars;
  bool _luckForward = true;

  // Derived analytical state (computed from chart after calculation)
  String? _dmStrength;
  List<String>? _yongShen;
  List<String>? _jiShen;
  List<int>? _emptyBranches;
  BaziRelations? _branchRelations;
  BaziPillar? _annualPillar;
  BaziRelations? _annualRelations;
  List<int>? _noblemen;

  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCitiesFromCsv();
    _loadSavedProfile();
  }

  /// Loads all cities from CSV via shared [CityService].
  void _loadCitiesFromCsv() async {
    final cities = await CityService.loadCitiesFromCsv();
    if (mounted) setState(() => _allCities = cities);
  }

  /// Pre-fills tanggal lahir, jam lahir, gender, & kota dari profil tersimpan.
  Future<void> _loadSavedProfile() async {
    final profile = await ref.read(birthProfileProvider.future);
    if (profile.dobDate == null) return;

    final dob = profile.dobDate!;
    final lat = profile.latitude ?? 0.0;
    final lng = profile.longitude ?? 0.0;

    if (!mounted) return;
    setState(() {
      _birthDate = dob;
      _selectedCity = _allCities.isNotEmpty
          ? _allCities.firstWhere(
              (c) => (c.latitude - lat).abs() < 0.001 &&
                  (c.longitude - lng).abs() < 0.001,
              orElse: () => CityPreset(
                  name: profile.cityName ?? 'Lokasi Tersimpan', latitude: lat, longitude: lng),
            )
          : CityPreset(
              name: profile.cityName ?? 'Lokasi Tersimpan', latitude: lat, longitude: lng);
      
      if (profile.gender != null) {
        _isMale = profile.gender == 'male';
      }
      
      if (profile.birthHour != null) {
        _birthHour = profile.birthHour;
        _includeHour = true;
      }
    });
  }

  // ─── Step navigation ──────────────────────────────────────────────────

  void _nextStep() {
    if (_step == 0 && _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.accentGold, size: 16),
              const SizedBox(width: 8),
              const Text('Pilih tanggal lahir terlebih dahulu.'),
            ],
          ),
          backgroundColor: AppTheme.cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
                color: AppTheme.accentGold, width: 1),
          ),
        ),
      );
      return;
    }
    if (_step < 2) setState(() => _step++);
    if (_step == 2) _calculate();
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() {
        _step--;
        _chart = null;
        _errorMsg = null;
        _luckPillars = null;
        _dmStrength = null;
        _yongShen = null;
        _jiShen = null;
        _emptyBranches = null;
        _branchRelations = null;
        _annualPillar = null;
        _annualRelations = null;
        _noblemen = null;
      });
    }
  }

  // ─── Calculate ────────────────────────────────────────────────────────

  Future<void> _calculate() async {
    if (_birthDate == null) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final String dateStr =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
    final double? lng =
        _selectedCity.longitude != 0.0 ? _selectedCity.longitude : null;
    final double? lat =
        _selectedCity.latitude != 0.0 ? _selectedCity.latitude : null;
    final int? hour = _includeHour ? _birthHour : null;

    try {
      final authToken = ref.read(authProvider);
      String authHeader;
      if (authToken != null && !authToken.isMock) {
        // Firebase ID Token is the signed JWT — never send the plain UID as a bearer token.
        final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
        authHeader = idToken != null ? 'Bearer $idToken' : 'Guest ${authToken.uid}';
      } else {
        authHeader = 'Guest ${authToken?.uid ?? 'anonymous'}';
      }

      final result = await ApiService.getBaziChart(
        birthDate: dateStr,
        birthHour: hour,
        latitude: lat,
        longitude: lng,
        authHeader: authHeader,
      );
      final data = result['data'] as Map<String, dynamic>;
      setState(() => _chart = BaziChart.fromJson(data));
    } catch (_) {
      // Offline fallback — pure Dart calculation
      final offline = BaziUtils.calculateBaziChart(
        _birthDate!,
        birthHour: hour,
        longitude: lng,
      );
      setState(() => _chart = offline);
    } finally {
      setState(() => _isLoading = false);
    }

    // Persist birth data so other features (Weton, Tarot) can auto-fill (fire-and-forget)
    if (_chart != null) {
      ref.read(birthProfileProvider.notifier).saveAll(
        dob: _birthDate!,
        birthHour: _includeHour ? _birthHour : null,
        latitude: _selectedCity.latitude,
        longitude: _selectedCity.longitude,
        cityName: _selectedCity.name,
        gender: _isMale == null ? null : (_isMale! ? 'male' : 'female'),
      ).catchError((e) {
        debugPrint('BaziCalculatorScreen: error saving birth profile: $e');
      });
    }

    // Compute Luck Pillars if gender is known
    if (_chart != null && _isMale != null) {
      final bool isYang = _chart!.yearPillar.stemIndex % 2 == 0;
      _luckForward = _isMale! == isYang;
      setState(() {
        _luckPillars = BaziUtils.calculateLuckPillars(
          birthDate: _birthDate!,
          monthPillar: _chart!.monthPillar,
          yearStemIndex: _chart!.yearPillar.stemIndex,
          isMale: _isMale!,
        );
      });
    }

    // Compute derived analytical state (strength, elements, relations, annual)
    if (_chart != null) {
      final annual = BaziUtils.getCurrentAnnualPillar();
      setState(() {
        _dmStrength      = _chart!.dmStrength.label;
        _yongShen        = _chart!.dmStrength.yongShen;
        _jiShen          = _chart!.dmStrength.jiShen;
        _emptyBranches   = BaziUtils.getEmptyBranches(_chart!.dayPillar);
        _branchRelations = BaziUtils.detectBranchRelations(_chart!.allPillars);
        _annualPillar    = annual;
        _annualRelations = BaziUtils.detectBranchRelations(
            [..._chart!.allPillars, annual]);
        _noblemen        = BaziUtils.getNobleman(_chart!.dayPillar.stemIndex);
      });
    }
  }

  // ─── AI Oracle ────────────────────────────────────────────────────────

  Future<void> _consultOracle() async {
    if (_chart == null || _birthDate == null) return;

    final double? lng =
        _selectedCity.longitude != 0.0 ? _selectedCity.longitude : null;
    final double? lat =
        _selectedCity.latitude != 0.0 ? _selectedCity.latitude : null;

    final mastersAsync = ref.read(baziDayMastersProvider);
    final masterData = mastersAsync.asData?.value.findById(_chart!.dayMasterId);
    final arketipe = masterData?['arketipe_modern'] as String?;

    final authToken = ref.read(authProvider);
    String authHeader;
    if (authToken != null && !authToken.isMock) {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      authHeader = idToken != null ? 'Bearer $idToken' : 'Guest ${authToken.uid}';
    } else {
      authHeader = 'Guest ${authToken?.uid ?? 'anonymous'}';
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OracleChatScreen(
          oracleType: 'bazi',
          authHeader: authHeader,
          aiContext: {
            'baziChart': {
              'yearPillar': '${_chart!.yearPillar.stemNameId} ${_chart!.yearPillar.branchZodiacId}',
              'monthPillar': '${_chart!.monthPillar.stemNameId} ${_chart!.monthPillar.branchZodiacId}',
              'dayPillar': '${_chart!.dayPillar.stemNameId} ${_chart!.dayPillar.branchZodiacId}',
              'hourPillar': _chart!.hourPillar != null
                  ? '${_chart!.hourPillar!.stemNameId} ${_chart!.hourPillar!.branchZodiacId}'
                  : null,
              'dayMasterId': _chart!.dayMasterId,
              'dayMasterLabel': arketipe != null
                  ? '${_chart!.dayMasterId} — ${_chart!.dayMasterElement} — $arketipe'
                  : _chart!.dayMasterId,
              'wuXingBalance':
                  'Kayu:${_chart!.wuXingBalance.kayu} Api:${_chart!.wuXingBalance.api} Tanah:${_chart!.wuXingBalance.tanah} Logam:${_chart!.wuXingBalance.logam} Air:${_chart!.wuXingBalance.air}',
            },
            if (lat != null) 'latitude': lat,
            if (lng != null) 'longitude': lng,
          },
        ),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.accentGold, size: 18),
                onPressed: _prevStep,
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '四柱八字  Ba Zi',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Langkah ${_step + 1} dari 3',
              style: GoogleFonts.outfit(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/bazi_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Date selection ───────────────────────────────────────────

  Widget _buildStep0() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepIndicator(0),
          const SizedBox(height: 32),
          Text(
            'Tanggal Lahir',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digunakan untuk menghitung 4 Pilar Ba Zi berdasarkan siklus kalender surya.',
            style: GoogleFonts.outfit(
                fontSize: 13, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _pickDate,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.accentGold, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _birthDate == null
                          ? 'Ketuk untuk memilih tanggal...'
                          : '${_birthDate!.day} / ${_birthDate!.month} / ${_birthDate!.year}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: _birthDate == null
                            ? Colors.white38
                            : Colors.white,
                        fontWeight: _birthDate == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_birthDate != null)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4ADE80), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          _primaryButton('Lanjut →', _birthDate != null ? _nextStep : null),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990, 1, 1),
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
    if (picked != null) setState(() => _birthDate = picked);
  }

  // ─── Step 1: Hour + City ──────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepIndicator(1),
          const SizedBox(height: 32),

          // Hour section
          Text(
            'Jam Lahir (Opsional)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Menambah Pilar Jam meningkatkan akurasi peta kosmis. Jika tidak tahu, lewati.',
            style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Switch(
                  value: _includeHour,
                  onChanged: (v) => setState(() => _includeHour = v),
                  activeThumbColor: AppTheme.accentPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  _includeHour ? 'Sertakan jam lahir' : 'Lewati — jam tidak diketahui',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),

          if (_includeHour) ...[
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jam lahir (waktu lokal setempat)',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppTheme.accentPurple, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _birthHour == null
                            ? '--:--'
                            : '${_birthHour.toString().padLeft(2, '0')}:00',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickHour,
                        child: Text(
                          'Pilih',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // City section
          Text(
            'Kota Kelahiran (Opsional)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digunakan untuk mengoreksi jam lahir ke True Solar Time (TST) agar akurasi pilar jam meningkat.',
            style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () async {
              final picked = await showModalBottomSheet<CityPreset>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.cardBg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => CitySearchSheet(cityPresets: _allCities),
              );
              if (picked != null) setState(() => _selectedCity = picked);
            },
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCity.name,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.search_rounded,
                      color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Gender — needed for Luck Pillars direction
          Text(
            'Jenis Kelamin (Opsional)',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Diperlukan untuk menghitung siklus 10 tahun Luck Pillars (大運).',
            style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.white60, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _genderChip('Pria', true),
              const SizedBox(width: 10),
              _genderChip('Wanita', false),
            ],
          ),

          const SizedBox(height: 40),
          _primaryButton('Hitung Peta Ba Zi ✦', _nextStep),
        ],
      ),
    );
  }

  Future<void> _pickHour() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _birthHour ?? 12, minute: 0),
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
    if (picked != null) setState(() => _birthHour = picked.hour);
  }

  // ─── Step 2: Results ──────────────────────────────────────────────────

  Widget _buildStep2() {
    if (_isLoading) {
      return Center(
        key: const ValueKey('loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.accentGold),
            const SizedBox(height: 20),
            Text(
              'Memetakan langit kelahiranmu...',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_chart == null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMsg ?? 'Gagal menghitung peta Ba Zi.',
              style: GoogleFonts.outfit(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _calculate,
              child: const Text('Coba lagi',
                  style: TextStyle(color: AppTheme.accentGold)),
            ),
          ],
        ),
      );
    }

    final mastersAsync = ref.watch(baziDayMastersProvider);
    final pillarsAsync = ref.watch(baziPillarsProvider);
    final godsAsync         = ref.watch(baziGodsProvider);
    final strengthAsync     = ref.watch(baziStrengthLevelsProvider);

    final masterData = mastersAsync.asData?.value.findById(_chart!.dayMasterId);
    final pillarData = pillarsAsync.asData?.value.findById(_chart!.dayPillar.id);
    final godsData      = godsAsync.asData?.value;
    final strengthData  = strengthAsync.asData?.value;

    final Color elementColor =
        kBaziElementColors[_chart!.dayMasterElement] ?? AppTheme.accentGold;

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  'Peta Langit Kelahiran',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_birthDate!.day} / ${_birthDate!.month} / ${_birthDate!.year}',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Four Pillars Chart
          BaziFourPillarsChart(chart: _chart!),
          const SizedBox(height: 8),

          // Ten Gods row — tap any chip for detail sheet
          BaziTenGodsWidget(
            chart: _chart!,
            elementColor: elementColor,
            godsData: godsData,
          ),
          const SizedBox(height: 16),

          // Day Master Strength + 用神/忌神 + 天乙貴人
          if (_dmStrength != null) ...[
            BaziStrengthCard(
              dayPillar:   _chart!.dayPillar,
              monthPillar: _chart!.monthPillar,
              dmStrength:  _dmStrength!,
              yongShen:    _yongShen ?? [],
              jiShen:      _jiShen ?? [],
              noblemen:    _noblemen ?? [],
              allPillars:  _chart!.allPillars,
              elementColor: elementColor,
              strengthData: strengthData,
            ),
            const SizedBox(height: 16),
          ],

          // Day Master archetype card
          BaziDayMasterCard(
            dayPillar: _chart!.dayPillar,
            masterData: masterData,
          ),
          const SizedBox(height: 16),

          // Wu Xing Pentagon Radar
          BaziElementBalanceCard(balance: _chart!.wuXingBalance),
          const SizedBox(height: 16),

          // Branch Relations 六冲/六合/三合/空亡
          if (_branchRelations != null && _emptyBranches != null) ...[
            BaziBranchRelationsCard(
              relations:     _branchRelations!,
              emptyBranches: _emptyBranches!,
              pillars:       _chart!.allPillars,
            ),
            const SizedBox(height: 16),
          ],

          // Annual Pillar 流年
          if (_annualPillar != null && _annualRelations != null) ...[
            BaziAnnualPillarCard(
              annualPillar:    _annualPillar!,
              natalChart:      _chart!,
              annualRelations: _annualRelations!,
            ),
            const SizedBox(height: 16),
          ],

          // Day Pillar detail from bazi-pillars.json
          if (pillarData != null) _buildPillarDetailCard(pillarData, elementColor),

          // AI Oracle section
          const SizedBox(height: 16),
          _buildAiSection(elementColor,
              aiHook: masterData?['ai_hook'] as String?),

          // Luck Pillars — real widget if gender known, placeholder otherwise
          const SizedBox(height: 16),
          _luckPillars != null
              ? BaziLuckPillarsWidget(
                  pillars:     _luckPillars!,
                  elementColor: elementColor,
                  isForward:   _luckForward,
                  birthDate:   _birthDate!,
                )
              : _buildLuckPillarsPlaceholder(elementColor),

          // Recalculate
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white38, size: 16),
            label: Text(
              'Hitung ulang dengan data berbeda',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarDetailCard(
      Map<String, dynamic> data, Color elementColor) {
    final String summary = data['character_summary'] as String? ?? '';
    final List<String> career =
        (data['career_tendency'] as List<dynamic>?)?.cast<String>() ?? [];
    final List<String> tags =
        (data['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('日柱 ',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: elementColor,
                      fontWeight: FontWeight.bold)),
              Text(
                data['pillar_name'] as String? ?? '',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.isNotEmpty)
            Text(summary,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.5)),
          if (career.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: career
                  .map((c) => _smallChip(c, elementColor))
                  .toList(),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => _smallChip(t, Colors.white38))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiSection(Color elementColor, {String? aiHook}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (aiHook != null && aiHook.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              aiHook,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white38,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        _primaryButton(
          '✦ Bicara dengan Suhu Wang',
          _consultOracle,
          color: elementColor,
        ),
      ],
    );
  }


  // ─── Luck Pillars placeholder ─────────────────────────────────────────

  Widget _buildLuckPillarsPlaceholder(Color elementColor) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: elementColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: elementColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: elementColor.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '大運  Luck Pillars',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Siklus 10 tahun nasib segera hadir.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Segera',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, bool isMale) {
    final bool selected = _isMale == isMale;
    final Color color = isMale ? AppTheme.accentPurple : const Color(0xFFF472B6);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isMale = isMale),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.6) : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMale ? Icons.male_rounded : Icons.female_rounded,
                color: selected ? color : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.white38,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────────

  Widget _stepIndicator(int active) {
    return Row(
      children: List.generate(3, (i) {
        final bool done = i < active;
        final bool current = i == active;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: done
                  ? AppTheme.accentGold
                  : current
                      ? AppTheme.accentPurple
                      : Colors.white12,
            ),
          ),
        );
      }),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap,
      {Color? color}) {
    final Color btnColor = color ?? AppTheme.accentPurple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onTap != null
              ? btnColor.withValues(alpha: 0.85)
              : Colors.white12,
          boxShadow: onTap != null
              ? [BoxShadow(color: btnColor.withValues(alpha: 0.35), blurRadius: 16)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: onTap != null ? Colors.white : Colors.white30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallChip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500),
        ),
      );
}
