import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/services/city_service.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/models/birth_profile.dart';
import '../../auth/services/auth_service.dart';
import '../services/weton_dictionary_service.dart';
import '../../../core/services/api_service.dart';
import '../data/pranata_mangsa_repository.dart';
import 'widgets/seasonal_banner.dart';
import 'components/weton_detail_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ai_astrologer_dialog.dart';
import '../../../core/widgets/astrological_dial_timepiece.dart';
import 'widgets/javanese_astrological_gear_dial.dart';
import 'widgets/weton_element_mandala.dart';
import '../../../core/widgets/city_search_sheet.dart';
import 'widgets/daily_insight_card.dart';
import 'widgets/weton_step_wizards.dart';

class WetonCalculatorScreen extends ConsumerStatefulWidget {
  const WetonCalculatorScreen({super.key});

  @override
  ConsumerState<WetonCalculatorScreen> createState() => _WetonCalculatorScreenState();
}

class _WetonCalculatorScreenState extends ConsumerState<WetonCalculatorScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  CityPreset _selectedCity = _cityPresets[0]; // Default to Jakarta
  List<CityPreset> _allCities = [];
  int _currentStep = 0;
  
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  
  WetonInfo? _result;
  bool _isSaving = false;
  Map<String, dynamic>? _dailyInsightData;
  bool _isLoadingDaily = false;

  static const List<CityPreset> _cityPresets = [
    CityPreset(name: 'Jakarta', latitude: -6.2088, longitude: 106.8456),
    CityPreset(name: 'Surabaya', latitude: -7.2575, longitude: 112.7521),
    CityPreset(name: 'Bandung', latitude: -6.9175, longitude: 107.6191),
    CityPreset(name: 'Medan', latitude: 3.5952, longitude: 98.6722),
    CityPreset(name: 'Makassar', latitude: -5.1477, longitude: 119.4327),
    CityPreset(name: 'Yogyakarta', latitude: -7.7956, longitude: 110.3695),
    CityPreset(name: 'Semarang', latitude: -6.9932, longitude: 110.4203),
    CityPreset(name: 'Denpasar', latitude: -8.6500, longitude: 115.2167),
    CityPreset(name: 'Koordinat Kustom', latitude: 0.0, longitude: 0.0),
  ];

  @override
  void initState() {
    super.initState();
    _latController.text = _selectedCity.latitude.toString();
    _lngController.text = _selectedCity.longitude.toString();
    _loadCitiesFromCsv();
    _loadSavedProfileAndCalculate();
  }

  Future<void> _loadSavedProfileAndCalculate() async {
    final profile = await ref.read(birthProfileProvider.future);
    if (profile.dobDate != null) {
      final dob = profile.dobDate!;
      final lat = profile.latitude ?? 0.0;
      final lng = profile.longitude ?? 0.0;
      if (mounted) {
        setState(() {
          _selectedDate = dob;
          _latController.text = lat.toString();
          _lngController.text = lng.toString();
          _selectedCity = _cityPresets.firstWhere(
            (c) => (c.latitude - lat).abs() < 0.0001 && (c.longitude - lng).abs() < 0.0001,
            orElse: () => _cityPresets.last,
          );
        });
        _handleCalculate();
      }
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AstrologicalDialTimepiece(
          initialDateTime: _selectedDate ?? DateTime(2000, 1, 1),
          showTime: false,
          onDateTimeSelected: (dt) {
            setState(() {
              _selectedDate = dt;
            });
          },
        );
      },
    );
  }

  void _presentTimePicker() {
    final now = DateTime.now();
    final initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime?.hour ?? 12,
      _selectedTime?.minute ?? 0,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AstrologicalDialTimepiece(
          initialDateTime: initialDateTime,
          showTime: true,
          onDateTimeSelected: (dt) {
            setState(() {
              _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
            });
          },
        );
      },
    );
  }

  Future<void> _handleCalculate() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir terlebih dahulu!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    final dob = _selectedDate!;
    setState(() {
      _result = WetonUtils.calculateWeton(dob);
      _isLoadingDaily = true;
    });

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
  }

  void _handleSaveProfile() async {
    if (_result == null || _selectedDate == null) return;
    
    final double? lat = double.tryParse(_latController.text);
    final double? lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat lintang/bujur tidak valid!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    bool success = false;
    try {
      final current = ref.read(birthProfileProvider).value ?? const BirthProfile();
      await ref.read(birthProfileProvider.notifier).saveAll(
        dob: _selectedDate!,
        birthHour: current.birthHour,
        latitude: lat,
        longitude: lng,
        cityName: _selectedCity.name,
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
          content: Text(success ? 'Profil berhasil disimpan ke takdir Anda!' : 'Gagal menyimpan profil.'),
          backgroundColor: success ? AppTheme.accentPurple : Colors.redAccent,
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
            child: SingleChildScrollView(
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
                    // Date & Time Picker Card
                    // Stepped Wizard (Ritus Langkah Lahir)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _currentStep == 0
                          ? WaktuKosmisStepCard(
                              selectedDate: _selectedDate,
                              selectedTime: _selectedTime,
                              onPresentDatePicker: _presentDatePicker,
                              onPresentTimePicker: _presentTimePicker,
                              onNextStep: () {
                                if (_selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pilih tanggal lahir terlebih dahulu!'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _currentStep = 1;
                                });
                              },
                            )
                          : KoordinatBumiStepCard(
                              selectedCity: _selectedCity,
                              latController: _latController,
                              lngController: _lngController,
                              onSelectCity: () async {
                                final selected = await _showCitySearchSheet(context);
                                if (selected != null) {
                                  setState(() {
                                    _selectedCity = selected;
                                    if (selected.name != 'Koordinat Kustom') {
                                      _latController.text = selected.latitude.toString();
                                      _lngController.text = selected.longitude.toString();
                                    }
                                  });
                                }
                              },
                              onBackPressed: () {
                                setState(() {
                                  _currentStep = 0;
                                });
                              },
                              onCalculate: _handleCalculate,
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
                                              final hexStr = entry!.warnaHarmoni!.replaceAll('#', '');
                                              Color? harmoniColor;
                                              if (hexStr.length == 6) {
                                                harmoniColor = Color(int.parse('FF$hexStr', radix: 16));
                                              }
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
                                // 3 Main Cards — sejajar
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: WetonDetailCard(
                                          title: 'Karier & Rezeki',
                                          content: entry.karirRezeki,
                                          icon: Icons.work_outline,
                                          accentColor: AppTheme.accentGold,
                                          margin: EdgeInsets.zero,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: WetonDetailCard(
                                          title: 'Asmara & Hubungan',
                                          content: entry.asmaraHubungan,
                                          icon: Icons.favorite_border,
                                          accentColor: AppTheme.accentPink,
                                          margin: EdgeInsets.zero,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: WetonDetailCard(
                                          title: 'Sisi Gelap & Peringatan',
                                          content: entry.sisiGelapPeringatan,
                                          icon: Icons.warning_amber_outlined,
                                          accentColor: const Color(0xFFF87171),
                                          margin: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                 if (entry.saranHarian != null && entry.saranHarian!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Builder(
                                      builder: (context) {
                                        Color? harmoniColor;
                                        if (entry.warnaHarmoni != null) {
                                          final hexStr = entry.warnaHarmoni!.replaceAll('#', '');
                                          if (hexStr.length == 6) {
                                            harmoniColor = Color(int.parse('FF$hexStr', radix: 16));
                                          }
                                        }
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
                                   onPressed: () {
                                     final session = ref.read(authProvider);
                                     final authHeader = session == null
                                         ? 'Guest anonymous'
                                         : session.isMock
                                             ? 'Guest ${session.uid}'
                                             : 'Bearer ${session.uid}';
                                     
                                     final aiHookText = 'Sebagai seorang dengan weton ${_result!.saptawara} ${_result!.pancawara} (Neptu ${_result!.totalNeptu}), bagaimana karakter dasar saya memengaruhi potensi diri saya dan apa saran orakel untuk hidup sehari-hari?';
                                     
                                     showDialog(
                                       context: context,
                                       builder: (context) => AiAstrologerDialog(
                                         prompt: aiHookText,
                                         contextTitle: 'Weton ${_result!.saptawara} ${_result!.pancawara}',
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
                                     );
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.2),
                                     foregroundColor: Colors.white,
                                     side: BorderSide(
                                       color: entry.warnaHarmoni != null
                                           ? Color(int.parse('FF${entry.warnaHarmoni!.replaceAll('#', '')}', radix: 16))
                                           : AppTheme.accentPurple,
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
                                     color: entry.warnaHarmoni != null
                                         ? Color(int.parse('FF${entry.warnaHarmoni!.replaceAll('#', '')}', radix: 16))
                                         : AppTheme.accentGold,
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
                                sisaBagiAsync.when(
                                  data: (sisaBagiList) {
                                    return wukuAsync.when(
                                      data: (wukuList) {
                                        return pranataMangsaAsync.when(
                                          data: (pranataList) {
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
                                              (w) => w['id'] == wukuIndex || w['id'] == wukuIndex + 1 || w['nama_wuku'].toString().toLowerCase() == wukuName.toLowerCase(),
                                              orElse: () => wukuList.first,
                                            );

                                            // Lookup target pranata mangsa ID
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
                                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
                                          error: (err, _) => Center(child: Text('Gagal memuat Pranata Mangsa: $err')),
                                        );
                                      },
                                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
                                      error: (err, _) => Center(child: Text('Gagal memuat wuku harian: $err')),
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
                                  error: (err, _) => Center(child: Text('Gagal memuat fase harian: $err')),
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
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loads all cities from CSV via shared [CityService].
  void _loadCitiesFromCsv() async {
    final cities = await CityService.loadCitiesFromCsv();
    if (mounted) setState(() => _allCities = cities);
  }

  String _formatCityName(String name) {
    if (name.isEmpty) return '';
    return name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<CityPreset?> _showCitySearchSheet(BuildContext context) {
    return showModalBottomSheet<CityPreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return CitySearchSheet(
          cityPresets: _allCities.isEmpty ? _cityPresets : _allCities,
        );
      },
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


