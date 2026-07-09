import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bazi_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/city_service.dart';
import '../../../core/widgets/city_search_sheet.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../domain/bazi_chart.dart';
import '../services/bazi_data_service.dart';
import '../../../features/ai/presentation/oracle_chat_screen.dart';
import 'widgets/bazi_date_picker_step.dart';
import 'widgets/bazi_input_step.dart';
import 'widgets/bazi_results_view.dart';

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
      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

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

    final mastersAsync = ref.read(baziDayMastersProvider);
    final masterData = mastersAsync.asData?.value.findById(_chart!.dayMasterId);
    final arketipe = masterData?['arketipe_modern'] as String?;

    // Hitung Da Yun aktif dari luck pillars berdasarkan usia saat ini
    String? daYunAktifStr;
    if (_luckPillars != null && _luckPillars!.isNotEmpty) {
      final currentAge = DateTime.now().year - _birthDate!.year;
      try {
        final activeLp = _luckPillars!.firstWhere(
          (lp) => currentAge >= lp.startAge && currentAge <= lp.endAge,
        );
        daYunAktifStr =
            'Da Yun: ${activeLp.pillar.stemNameId} ${activeLp.pillar.branchZodiacId}'
            ' (usia ${activeLp.startAge}–${activeLp.endAge})';
      } catch (_) {
        // Usia di luar range pilar yang dihitung — pakai pilar terakhir
        final lastLp = _luckPillars!.last;
        daYunAktifStr =
            'Da Yun terakhir: ${lastLp.pillar.stemNameId} ${lastLp.pillar.branchZodiacId}'
            ' (usia ${lastLp.startAge}+)';
      }
    }
    // Gabungkan dengan pilar tahunan sebagai konteks timing tambahan
    if (_annualPillar != null) {
      final annualStr =
          'Pilar Tahun ${DateTime.now().year}: ${_annualPillar!.stemNameId} ${_annualPillar!.branchZodiacId}';
      daYunAktifStr =
          daYunAktifStr != null ? '$daYunAktifStr · $annualStr' : annualStr;
    }

    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

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
              if (_dmStrength != null)
                'dmStrength': [
                  _dmStrength!,
                  if (_yongShen?.isNotEmpty == true) 'Yong Shen: $_yongShen',
                  if (_jiShen?.isNotEmpty == true) 'Ji Shen: $_jiShen',
                ].join(' · '),
              if (_chart!.tenGods.year.isNotEmpty || _chart!.tenGods.month.isNotEmpty)
                'tenGods': [
                  if (_chart!.tenGods.year.isNotEmpty) 'Tahun: ${_chart!.tenGods.year}',
                  if (_chart!.tenGods.month.isNotEmpty) 'Bulan: ${_chart!.tenGods.month}',
                  if (_chart!.tenGods.hour?.isNotEmpty == true) 'Jam: ${_chart!.tenGods.hour}',
                ].join(', '),
              if (daYunAktifStr != null) 'daYunAktif': daYunAktifStr,
            },
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
        return BaziDatePickerStep(
          step: _step,
          birthDate: _birthDate,
          onPickDate: _pickDate,
          onNext: _birthDate != null ? _nextStep : null,
        );
      case 1:
        return BaziInputStep(
          step: _step,
          includeHour: _includeHour,
          birthHour: _birthHour,
          selectedCity: _selectedCity,
          allCities: _allCities,
          isMale: _isMale,
          onToggleHour: (v) => setState(() => _includeHour = v),
          onHourPicked: (h) => setState(() => _birthHour = h),
          onCityPicked: (city) => setState(() => _selectedCity = city),
          onGenderChanged: (male) => setState(() => _isMale = male),
          onNext: _nextStep,
        );
      case 2:
        return BaziResultsView(
          chart: _chart,
          birthDate: _birthDate,
          isLoading: _isLoading,
          errorMsg: _errorMsg,
          dmStrength: _dmStrength,
          yongShen: _yongShen,
          jiShen: _jiShen,
          noblemen: _noblemen,
          emptyBranches: _emptyBranches,
          branchRelations: _branchRelations,
          annualPillar: _annualPillar,
          annualRelations: _annualRelations,
          luckPillars: _luckPillars,
          luckForward: _luckForward,
          onRetry: _calculate,
          onConsultOracle: _consultOracle,
          onRecalculate: _prevStep,
        );
      default:
        return const SizedBox.shrink();
    }
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
}
