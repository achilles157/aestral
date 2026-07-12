import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/models/birth_profile.dart';
import '../../auth/services/auth_service.dart';
import '../services/weton_dictionary_service.dart';
import '../../../core/services/api_service.dart';
import 'widgets/weton_element_mandala.dart';
import 'widgets/weton_date_picker_card.dart';
import 'widgets/weton_result_header.dart';
import 'widgets/weton_technical_card.dart';
import 'widgets/weton_insight_section.dart';
import 'widgets/weton_oracle_button.dart';
import 'widgets/weton_daily_section.dart';
import 'weton_compatibility_screen.dart';
import '../../../core/widgets/cosmic_auth_bottom_sheet.dart';
import '../../history/models/reading_entry.dart';
import '../../history/services/reading_history_service.dart';
import '../../../core/services/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

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
    // Save to reading history (fire-and-forget)
    ReadingHistoryService.save(ReadingEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'weton',
      title: '${_result!.saptawara} ${_result!.pancawara}',
      subtitle: 'Neptu ${_result!.totalNeptu} · Wuku ${_result!.wuku}',
      timestamp: DateTime.now(),
      accentColor: 0xFFD4AF37,
    )).catchError((_) {});
    AnalyticsService.logWetonCalculated(
      '${_result!.saptawara} ${_result!.pancawara}',
      _result!.totalNeptu,
    ).catchError((_) {});
    // Save to Firestore for logged-in users (cross-device history)
    final wetonSession = ref.read(authProvider);
    if (wetonSession != null && !wetonSession.isMock) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(wetonSession.uid)
          .collection('weton_history')
          .add({
        'wetonName': '${_result!.saptawara} ${_result!.pancawara}',
        'neptu': _result!.totalNeptu,
        'wuku': _result!.wuku,
        'dobDate': '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        'calculatedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }

    final authHeader = await ref.read(authProvider.notifier).getAuthHeader();

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
    // Banner untuk tamu — ingatkan data in-memory, hilang jika app ditutup
    final authState = ref.read(authProvider);
    if ((authState?.isMock ?? true) && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Data tersimpan sementara — tutup app, data hilang.'),
          action: SnackBarAction(
            label: 'Simpan',
            onPressed: () => CosmicAuthBottomSheet.show(context),
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ));
    }
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

  void _shareWetonResult() {
    if (_result == null) return;
    final wetonName = '${_result!.saptawara} ${_result!.pancawara}';
    Share.share(
      '\u2726 Weton kosmis saya: $wetonName\n'
      'Neptu: ${_result!.totalNeptu} | Wuku: ${_result!.wuku}\n\n'
      'Temukan wetonmu di Aestral:\naestral.web.app',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dictionaryAsync = ref.watch(wetonDictionaryProvider);

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
          Positioned.fill(
            child: Image.asset('assets/images/weton_bg.png', fit: BoxFit.cover),
          ),
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
                            WetonDatePickerCard(
                              selectedDate: _selectedDate,
                              onPickDate: _presentDatePicker,
                              onCalculate: _handleCalculate,
                            ),
                            const SizedBox(height: 20),
                            if (_result != null)
                              dictionaryAsync.when(
                                data: (dictionary) {
                                  final wetonName = '${_result!.saptawara} ${_result!.pancawara}';
                                  final entry = lookupWetonEntry(dictionary, wetonName);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      WetonResultHeader(
                                        wetonName: wetonName,
                                        warnaHarmoni: entry?.warnaHarmoni,
                                        headline: entry?.headline,
                                      ),
                                      const SizedBox(height: 24),
                                      WetonElementMandala(
                                        saptawara: _result!.saptawara,
                                        pancawara: _result!.pancawara,
                                      ),
                                      const SizedBox(height: 20),
                                      WetonTechnicalCard(result: _result!),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: _shareWetonResult,
                                          icon: const Icon(
                                              Icons.share_rounded,
                                              size: 16,
                                              color: AppTheme.accentGold),
                                          label: Text(
                                            'Bagikan Hasil Weton',
                                            style: GoogleFonts.cinzel(
                                              color: AppTheme.accentGold,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (entry != null) ...[
                                        WetonInsightSection(entry: entry),
                                        const SizedBox(height: 16),
                                        WetonOracleButton(
                                          result: _result!,
                                          warnaHarmoni: entry.warnaHarmoni,
                                          dailyInsightData: _dailyInsightData,
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                      const SizedBox(height: 12),
                                      WetonDailySection(
                                        isLoading: _isLoadingDaily,
                                        dailyInsightData: _dailyInsightData,
                                      ),
                                      const SizedBox(height: 16),
                                      _isSaving
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                  color: AppTheme.accentPurple),
                                            )
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
                                          side: const BorderSide(
                                              color: AppTheme.accentGold, width: 1.2),
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
