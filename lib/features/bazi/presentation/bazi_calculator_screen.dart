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
import '../services/bazi_cache_service.dart';
import '../services/bazi_data_service.dart';
import '../../history/models/reading_entry.dart';
import '../../history/services/reading_history_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/cosmic_share.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screenshot/screenshot.dart';
import '../../../features/ai/presentation/oracle_chat_screen.dart';
import 'widgets/bazi_date_picker_step.dart';
import 'widgets/bazi_input_step.dart';
import 'widgets/bazi_results_view.dart';
import '../../../core/widgets/cosmic_auth_bottom_sheet.dart';

class BaziCalculatorScreen extends ConsumerStatefulWidget {
  const BaziCalculatorScreen({super.key});

  @override
  ConsumerState<BaziCalculatorScreen> createState() =>
      _BaziCalculatorScreenState();
}

class _BaziCalculatorScreenState extends ConsumerState<BaziCalculatorScreen> {
  int _step = 0;
  final ScreenshotController _baziScreenshotCtrl = ScreenshotController();
  DateTime? _birthDate;
  int? _birthHour;
  bool _includeHour = false;
  CityPreset _selectedCity = const CityPreset(
    name: 'Jakarta',
    latitude: -6.2088,
    longitude: 106.8456,
  );
  List<CityPreset> _allCities = [];

  bool _isLoading = false;
  String? _errorMsg;
  bool? _isMale; // user input: needed for Luck Pillars direction
  _BaziResultData? _result; // null = chart not yet calculated

  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCitiesAndProfile(); // Sequential: cities first, then profile match
  }

  /// Loads cities then profile sequentially to avoid race condition where
  /// _loadSavedProfile matches city before _allCities is populated.
  Future<void> _loadCitiesAndProfile() async {
    await _loadCitiesFromCsv();
    await _loadSavedProfile();
  }

  /// Loads all cities from CSV via shared [CityService].
  Future<void> _loadCitiesFromCsv() async {
    try {
      final cities = await CityService.loadCitiesFromCsv();
      if (mounted) setState(() => _allCities = cities);
    } catch (e) {
      debugPrint('_loadCitiesFromCsv error: $e');
    }
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
              (c) =>
                  (c.latitude - lat).abs() < 0.001 &&
                  (c.longitude - lng).abs() < 0.001,
              orElse: () => CityPreset(
                name: profile.cityName ?? 'Lokasi Tersimpan',
                latitude: lat,
                longitude: lng,
              ),
            )
          : CityPreset(
              name: profile.cityName ?? 'Lokasi Tersimpan',
              latitude: lat,
              longitude: lng,
            );

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
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentGold,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('Pilih tanggal lahir terlebih dahulu.'),
            ],
          ),
          backgroundColor: AppTheme.cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.accentGold, width: 1),
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
        _errorMsg = null;
        _result = null;
      });
    }
  }

  // ─── Calculate ────────────────────────────────────────────────────────

  Future<void> _calculate() async {
    if (_birthDate == null) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _result = null;
    });

    final String dateStr =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
    final double? lng = _selectedCity.longitude != 0.0
        ? _selectedCity.longitude
        : null;
    final double? lat = _selectedCity.latitude != 0.0
        ? _selectedCity.latitude
        : null;
    final int? hour = _includeHour ? _birthHour : null;

    BaziChart? chart;
    try {
      final cacheKey = BaziCacheService.cacheKey(dateStr, hour, lat, lng);
      final cached = await BaziCacheService.get(cacheKey);
      if (cached != null) {
        chart = BaziChart.fromJson(cached);
      } else {
        final authHeader = await ref
            .read(authProvider.notifier)
            .getAuthHeader();
        final apiResult = await ApiService.getBaziChart(
          birthDate: dateStr,
          birthHour: hour,
          latitude: lat,
          longitude: lng,
          authHeader: authHeader,
        );
        final data = apiResult['data'] as Map<String, dynamic>;
        await BaziCacheService.save(cacheKey, data);
        chart = BaziChart.fromJson(data);
      }
    } catch (e) {
      debugPrint('BaziCalculatorScreen: API failed, fallback offline — $e');
      chart = BaziUtils.calculateBaziChart(
        _birthDate!,
        birthHour: hour,
        longitude: lng,
      );
    } finally {
      setState(() => _isLoading = false);
    }

    // Persist birth data (fire-and-forget)
    ref
        .read(birthProfileProvider.notifier)
        .saveAll(
          dob: _birthDate!,
          birthHour: _includeHour ? _birthHour : null,
          latitude: _selectedCity.latitude,
          longitude: _selectedCity.longitude,
          cityName: _selectedCity.name,
          gender: _isMale == null ? null : (_isMale! ? 'male' : 'female'),
        )
        .catchError((e) {
          debugPrint('BaziCalculatorScreen: error saving birth profile: $e');
        });
    // Banner untuk tamu — ingatkan data in-memory, hilang jika app ditutup
    final authState = ref.read(authProvider);
    if ((authState?.isMock ?? true) && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Data tersimpan sementara — tutup app, data hilang.',
            ),
            action: SnackBarAction(
              label: 'Simpan',
              onPressed: () => CosmicAuthBottomSheet.show(context),
            ),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    // Compute Luck Pillars if gender is known
    List<LuckPillar>? luckPillars;
    bool luckForward = true;
    if (_isMale != null) {
      final bool isYang = chart.yearPillar.stemIndex % 2 == 0;
      luckForward = _isMale! == isYang;
      luckPillars = BaziUtils.calculateLuckPillars(
        birthDate: _birthDate!,
        monthPillar: chart.monthPillar,
        yearStemIndex: chart.yearPillar.stemIndex,
        isMale: _isMale!,
      );
    }

    // Compute all derived state and consolidate into _BaziResultData
    final annual = BaziUtils.getCurrentAnnualPillar();
    setState(() {
      _result = _BaziResultData(
        chart: chart!,
        luckPillars: luckPillars,
        luckForward: luckForward,
        dmStrength: chart.dmStrength.label,
        yongShen: chart.dmStrength.yongShen,
        jiShen: chart.dmStrength.jiShen,
        emptyBranches: BaziUtils.getEmptyBranches(chart.dayPillar),
        branchRelations: BaziUtils.detectBranchRelations(chart.allPillars),
        annualPillar: annual,
        annualRelations: BaziUtils.detectBranchRelations([
          ...chart.allPillars,
          annual,
        ]),
        noblemen: BaziUtils.getNobleman(chart.dayPillar.stemIndex),
      );
    });
    // Save to reading history (fire-and-forget)
    ReadingHistoryService.save(
      ReadingEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'bazi',
        title:
            '${chart.dayPillar.stemNameId} ${chart.dayPillar.branchZodiacId}',
        subtitle: '${chart.dayMasterElement} · Ba Zi Chart',
        timestamp: DateTime.now(),
        accentColor: 0xFF00BFA5,
      ),
    ).then((_) {}, onError: (Object _) {});
    AnalyticsService.logBaziCalculated(chart.dayMasterId).catchError((_) {});
    // Save to Firestore for logged-in users (cross-device history)
    final baziSession = ref.read(authProvider);
    if (baziSession != null && !baziSession.isMock) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(baziSession.uid)
          .collection('bazi_history')
          .add({
            'dayMasterId': chart.dayMasterId,
            'dayMasterElement': chart.dayMasterElement,
            'dayPillar':
                '${chart.dayPillar.stemNameId} ${chart.dayPillar.branchZodiacId}',
            'birthDate': dateStr,
            'calculatedAt': FieldValue.serverTimestamp(),
          })
          .then((_) {}, onError: (Object _) {});
    }
  }

  // ─── AI Oracle ────────────────────────────────────────────────────────

  Future<void> _consultOracle() async {
    if (_result == null || _birthDate == null) return;

    final mastersAsync = ref.read(baziDayMastersProvider);
    final masterData = mastersAsync.asData?.value.findById(
      _result!.chart.dayMasterId,
    );
    final arketipe = masterData?['arketipe_modern'] as String?;

    // Hitung Da Yun aktif dari luck pillars berdasarkan usia saat ini
    String? daYunAktifStr;
    if (_result!.luckPillars != null && _result!.luckPillars!.isNotEmpty) {
      final currentAge = DateTime.now().year - _birthDate!.year;
      try {
        final activeLp = _result!.luckPillars!.firstWhere(
          (lp) => currentAge >= lp.startAge && currentAge <= lp.endAge,
        );
        daYunAktifStr =
            'Da Yun: ${activeLp.pillar.stemNameId} ${activeLp.pillar.branchZodiacId}'
            ' (usia ${activeLp.startAge}–${activeLp.endAge})';
      } catch (_) {
        // Usia di luar range pilar yang dihitung — pakai pilar terakhir
        final lastLp = _result!.luckPillars!.last;
        daYunAktifStr =
            'Da Yun terakhir: ${lastLp.pillar.stemNameId} ${lastLp.pillar.branchZodiacId}'
            ' (usia ${lastLp.startAge}+)';
      }
    }
    // Gabungkan dengan pilar tahunan sebagai konteks timing tambahan
    if (_result!.annualPillar != null) {
      final annualStr =
          'Pilar Tahun ${DateTime.now().year}: ${_result!.annualPillar!.stemNameId} ${_result!.annualPillar!.branchZodiacId}';
      daYunAktifStr = daYunAktifStr != null
          ? '$daYunAktifStr · $annualStr'
          : annualStr;
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
              'yearPillar':
                  '${_result!.chart.yearPillar.stemNameId} ${_result!.chart.yearPillar.branchZodiacId}',
              'monthPillar':
                  '${_result!.chart.monthPillar.stemNameId} ${_result!.chart.monthPillar.branchZodiacId}',
              'dayPillar':
                  '${_result!.chart.dayPillar.stemNameId} ${_result!.chart.dayPillar.branchZodiacId}',
              'hourPillar': _result!.chart.hourPillar != null
                  ? '${_result!.chart.hourPillar!.stemNameId} ${_result!.chart.hourPillar!.branchZodiacId}'
                  : null,
              'dayMasterId': _result!.chart.dayMasterId,
              'dayMasterLabel': arketipe != null
                  ? '${_result!.chart.dayMasterId} — ${_result!.chart.dayMasterElement} — $arketipe'
                  : _result!.chart.dayMasterId,
              'wuXingBalance':
                  'Kayu:${_result!.chart.wuXingBalance.kayu} Api:${_result!.chart.wuXingBalance.api} Tanah:${_result!.chart.wuXingBalance.tanah} Logam:${_result!.chart.wuXingBalance.logam} Air:${_result!.chart.wuXingBalance.air}',
              if (_result!.dmStrength != null)
                'dmStrength': [
                  _result!.dmStrength!,
                  if (_result!.yongShen?.isNotEmpty == true)
                    'Yong Shen: ${_result!.yongShen}',
                  if (_result!.jiShen?.isNotEmpty == true)
                    'Ji Shen: ${_result!.jiShen}',
                ].join(' · '),
              if (_result!.chart.tenGods.year.isNotEmpty ||
                  _result!.chart.tenGods.month.isNotEmpty)
                'tenGods': [
                  if (_result!.chart.tenGods.year.isNotEmpty)
                    'Tahun: ${_result!.chart.tenGods.year}',
                  if (_result!.chart.tenGods.month.isNotEmpty)
                    'Bulan: ${_result!.chart.tenGods.month}',
                  if (_result!.chart.tenGods.hour?.isNotEmpty == true)
                    'Jam: ${_result!.chart.tenGods.hour}',
                ].join(', '),
              if (daYunAktifStr != null) 'daYunAktif': daYunAktifStr,
            },
          },
        ),
      ),
    );
  }

  void _shareBaziResult() {
    if (_result == null) return;
    final chart = _result!.chart;
    shareCosmicImage(
      context: context,
      controller: _baziScreenshotCtrl,
      shareText:
          '\u2726 Ba Zi Chart saya dari Aestral\n'
          'Day Master: ${chart.dayMasterElement} (${chart.dayMasterId})\n'
          'Pilar Hari: ${chart.dayPillar.stemNameId} ${chart.dayPillar.branchZodiacId}\n\n'
          'Temukan chart kosmismu di:\naestral.web.app',
      fileName: 'bazi_${chart.dayMasterId}.png',
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold,
                  size: 18,
                ),
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
          chart: _result?.chart,
          birthDate: _birthDate,
          isLoading: _isLoading,
          errorMsg: _errorMsg,
          dmStrength: _result?.dmStrength,
          yongShen: _result?.yongShen,
          jiShen: _result?.jiShen,
          noblemen: _result?.noblemen,
          emptyBranches: _result?.emptyBranches,
          branchRelations: _result?.branchRelations,
          annualPillar: _result?.annualPillar,
          annualRelations: _result?.annualRelations,
          luckPillars: _result?.luckPillars,
          luckForward: _result?.luckForward ?? true,
          onRetry: _calculate,
          onConsultOracle: _consultOracle,
          onRecalculate: _prevStep,
          screenshotController: _baziScreenshotCtrl,
          onShare: _result != null ? _shareBaziResult : null,
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

// ── Result data container ─────────────────────────────────────────────────

/// All Ba Zi calculation results consolidated into one immutable object.
/// [_BaziCalculatorScreenState._result] is null before the first calculation.
class _BaziResultData {
  final BaziChart chart;
  final List<LuckPillar>? luckPillars;
  final bool luckForward;
  final String? dmStrength;
  final List<String>? yongShen;
  final List<String>? jiShen;
  final List<int>? emptyBranches;
  final BaziRelations? branchRelations;
  final BaziPillar? annualPillar;
  final BaziRelations? annualRelations;
  final List<int>? noblemen;

  const _BaziResultData({
    required this.chart,
    this.luckPillars,
    this.luckForward = true,
    this.dmStrength,
    this.yongShen,
    this.jiShen,
    this.emptyBranches,
    this.branchRelations,
    this.annualPillar,
    this.annualRelations,
    this.noblemen,
  });
}
