import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import '../../auth/services/profile_service.dart';
import '../../auth/services/auth_service.dart';
import '../services/weton_dictionary_service.dart';
import '../../../core/services/api_service.dart';
import 'components/weton_detail_card.dart';

class CityPreset {
  final String name;
  final double latitude;
  final double longitude;

  const CityPreset({required this.name, required this.latitude, required this.longitude});
}

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
    await Future.delayed(Duration.zero);
    final profile = await ref.read(profileProvider).loadProfile();
    if (profile != null) {
      final dobUtcMs = profile['biometric_anchor']?['dob_utc_ms'] as int?;
      if (dobUtcMs != null) {
        final dob = DateTime.fromMillisecondsSinceEpoch(dobUtcMs);
        final coords = profile['biometric_anchor']?['coordinates'] as Map<String, dynamic>?;
        final lat = coords?['lat'] as double? ?? 0.0;
        final lng = coords?['lng'] as double? ?? 0.0;
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
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _presentTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Widget _buildPickerTheme(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accentPurple,
          onPrimary: AppTheme.textLight,
          surface: AppTheme.cardBg,
          onSurface: AppTheme.textLight,
        ),
      ),
      child: child,
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

      if (mounted) {
        setState(() {
          _dailyInsightData = {
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
    
    // Calculate final DateTime combining date and time
    final hour = _selectedTime?.hour ?? 12;
    final minute = _selectedTime?.minute ?? 0;
    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );

    final success = await ref.read(profileProvider).saveProfile(
      dob: combinedDateTime,
      latitude: lat,
      longitude: lng,
      weton: _result!,
    );

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'PILIH PARAMETER LAHIR',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // Date Picker Button
                            OutlinedButton.icon(
                              onPressed: _presentDatePicker,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.accentPurple, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.calendar_month, color: AppTheme.accentPurple),
                              label: Text(
                                _selectedDate == null
                                    ? 'Pilih Tanggal Lahir'
                                    : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                                style: const TextStyle(color: AppTheme.textLight),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Time Picker Button
                            OutlinedButton.icon(
                              onPressed: _presentTimePicker,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.accentPurple, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.access_time, color: AppTheme.accentPurple),
                              label: Text(
                                _selectedTime == null
                                    ? 'Pilih Jam Lahir (Opsional)'
                                    : 'Jam ${_selectedTime!.format(context)}',
                                style: const TextStyle(color: AppTheme.textLight),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Birth Location Selector
                            InkWell(
                              onTap: () async {
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
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Lokasi Kelahiran',
                                  labelStyle: TextStyle(color: AppTheme.textMuted),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.accentPurple),
                                  ),
                                  suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.accentPurple),
                                ),
                                child: Text(
                                  _selectedCity.name,
                                  style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                                ),
                              ),
                            ),
                            // Manual coordinates inputs if Custom Coordinate selected
                            if (_selectedCity.name == 'Koordinat Kustom') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _latController,
                                      decoration: const InputDecoration(
                                        labelText: 'Latitude',
                                        labelStyle: TextStyle(color: AppTheme.textMuted),
                                      ),
                                      style: const TextStyle(color: AppTheme.textLight),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _lngController,
                                      decoration: const InputDecoration(
                                        labelText: 'Longitude',
                                        labelStyle: TextStyle(color: AppTheme.textMuted),
                                      ),
                                      style: const TextStyle(color: AppTheme.textLight),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            // Calculate Button
                            ElevatedButton(
                              onPressed: _handleCalculate,
                              child: const Text('Hitung Primbon'),
                            ),
                          ],
                        ),
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
                                    Text(
                                      wetonName,
                                      style: textTheme.displayLarge?.copyWith(
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    if (entry != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '"${entry.headline}"',
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.accentGold.withOpacity(0.9),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (entry != null) ...[
                                // 3 Main Cards
                                WetonDetailCard(
                                  title: 'Karier & Rezeki',
                                  content: entry.karirRezeki,
                                  icon: Icons.work_outline,
                                  accentColor: AppTheme.accentGold,
                                ),
                                WetonDetailCard(
                                  title: 'Asmara & Hubungan',
                                  content: entry.asmaraHubungan,
                                  icon: Icons.favorite_border,
                                  accentColor: AppTheme.accentPink,
                                ),
                                WetonDetailCard(
                                  title: 'Sisi Gelap & Peringatan',
                                  content: entry.sisiGelapPeringatan,
                                  icon: Icons.warning_amber_outlined,
                                  accentColor: const Color(0xFFF87171),
                                ),
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
                                        final dailyInfo = _dailyInsightData!['daily'] as Map<String, dynamic>;
                                        final weeklyInfo = _dailyInsightData!['weekly'] as Map<String, dynamic>;

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

                                        return _buildDailyInsightCard(sisaBagiEntry, wukuEntry);
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
                              const SizedBox(height: 20),
                              // Dropdown Accordion for Technical Details
                              Card(
                                child: ExpansionTile(
                                  title: Text(
                                    '🔬 Lihat Detail Perhitungan Teknis',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontSize: 16,
                                      color: AppTheme.accentPurple,
                                    ),
                                  ),
                                  collapsedIconColor: AppTheme.accentPurple,
                                  iconColor: AppTheme.accentPurple,
                                  childrenPadding: const EdgeInsets.all(20.0),
                                  children: [
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
                                    // Neptu composite progress bar
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
                                    _AnalysisBadge(label: 'Pangarasan', value: _result!.pangarasan, color: AppTheme.accentPurple),
                                    const SizedBox(height: 12),
                                    _AnalysisBadge(label: 'Pancasuda', value: _result!.pancasuda, color: AppTheme.accentPink),
                                    const Divider(color: Color(0xFF2E2452), height: 40, thickness: 1.5),
                                    // Firestore flat JSON preview
                                    _JsonPreviewSection(
                                      result: _result!,
                                      selectedDate: _selectedDate!,
                                      latitude: double.tryParse(_latController.text) ?? 0.0,
                                      longitude: double.tryParse(_lngController.text) ?? 0.0,
                                    ),
                                  ],
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

  void _loadCitiesFromCsv() async {
    try {
      final String csvString = await rootBundle.loadString('assets/data/lat_long_kota_kab.csv');
      final lines = csvString.split('\n');
      final List<CityPreset> loadedCities = [];
      
      // Add custom coordinate option at the top
      loadedCities.add(const CityPreset(name: 'Koordinat Kustom', latitude: 0.0, longitude: 0.0));
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final tokens = line.split(',');
        if (tokens.length >= 6) {
          final rawName = tokens[3].trim();
          final String name = _formatCityName(rawName);
          final double lat = double.tryParse(tokens[4].trim()) ?? 0.0;
          final double long = double.tryParse(tokens[5].trim()) ?? 0.0;
          
          loadedCities.add(CityPreset(name: name, latitude: lat, longitude: long));
        }
      }
      
      // Sort cities by name (keeping Custom Coordinate at index 0)
      if (loadedCities.length > 1) {
        final custom = loadedCities[0];
        final rest = loadedCities.sublist(1);
        rest.sort((a, b) => a.name.compareTo(b.name));
        loadedCities.clear();
        loadedCities.add(custom);
        loadedCities.addAll(rest);
      }
      
      if (mounted) {
        setState(() {
          _allCities = loadedCities;
        });
      }
    } catch (e) {
      debugPrint("Error loading cities CSV: $e");
    }
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
        return _CitySearchSheet(
          cityPresets: _allCities.isEmpty ? _cityPresets : _allCities,
        );
      },
    );
  }

  Widget _buildDailyInsightCard(Map<String, dynamic> sisaBagi, Map<String, dynamic> wuku) {
    final textTheme = Theme.of(context).textTheme;
    final String fase = sisaBagi['nama_fase'] ?? '';
    final String tingkatEnergi = sisaBagi['tingkat_energi'] ?? '';
    final String interpretasi = sisaBagi['interpretasi_harian'] ?? '';
    final List<dynamic> saran = sisaBagi['saran_aktivitas'] ?? [];

    final String namaWuku = wuku['nama_wuku'] ?? '';
    final String arketipe = wuku['arketipe_modern'] ?? '';
    final String dewa = wuku['dewa_penaung'] ?? '';
    final String karakter = wuku['karakter_dasar'] ?? '';
    final String pesan = wuku['pesan_kesadaran'] ?? '';

    Color energyColor = AppTheme.accentGold;
    if (tingkatEnergi.toLowerCase().contains('waspada')) {
      energyColor = const Color(0xFFF87171);
    } else if (tingkatEnergi.toLowerCase().contains('stabil')) {
      energyColor = const Color(0xFF60A5FA);
    }

    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'DAILY INSIGHT & PAWUKON',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Divider(color: const Color(0xFF2E2452), height: 30, thickness: 1.5),
            
            // Phase & Energy Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fase: $fase',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: energyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: energyColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    'Energi: $tingkatEnergi',
                    style: textTheme.bodyMedium?.copyWith(
                      color: energyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              interpretasi,
              style: textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: AppTheme.textLight.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 20),
            
            // Action Suggestions Title
            Text(
              'REKOMENDASI AKTIVITAS HARI INI',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.accentPink,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            ...saran.map((activity) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.accentPink, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity.toString(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight.withOpacity(0.95),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const Divider(color: const Color(0xFF2E2452), height: 40, thickness: 1.5),
            
            // Wuku Influence
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.accentPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PENGARUH WUKU MINGGUAN',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.accentPurple,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Wuku $namaWuku — $arketipe',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dinaungi oleh $dewa',
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              karakter,
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textLight.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Pesan Kesadaran Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesan Kesadaran:',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pesan,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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

class _JsonPreviewSection extends StatelessWidget {
  final WetonInfo result;
  final DateTime selectedDate;
  final double latitude;
  final double longitude;

  const _JsonPreviewSection({
    required this.result,
    required this.selectedDate,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Simulate final flat document output for visualization
    final finalJson = {
      'biometric_anchor': {
        'dob_utc_ms': selectedDate.millisecondsSinceEpoch,
        'coordinates': {
          'lat': latitude,
          'lng': longitude,
        }
      },
      'architectural_pillars': {
        'weton': result.toJson(),
      }
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(finalJson);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREVIEW DOKUMEN FIRESTORE (FLATTENED)',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2E2452)),
          ),
          child: SelectableText(
            jsonStr,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              color: AppTheme.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}

class _CitySearchSheet extends StatefulWidget {
  final List<CityPreset> cityPresets;

  const _CitySearchSheet({required this.cityPresets});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CityPreset> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.cityPresets;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = widget.cityPresets;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCities = widget.cityPresets.where((city) {
          if (city.name == 'Koordinat Kustom') return true;
          return city.name.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Kota Kelahiran',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppTheme.textLight),
              decoration: InputDecoration(
                hintText: 'Cari Kota atau Kabupaten...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.accentPurple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.background.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.accentPurple.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.accentPurple),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        'Kota tidak ditemukan',
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = _filteredCities[index];
                        final isCustom = city.name == 'Koordinat Kustom';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Icon(
                            isCustom ? Icons.my_location : Icons.location_city,
                            color: isCustom ? AppTheme.accentPink : AppTheme.accentPurple.withOpacity(0.7),
                          ),
                          title: Text(
                            city.name,
                            style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Lat: ${city.latitude.toStringAsFixed(4)} • Lng: ${city.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.pop(context, city);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
