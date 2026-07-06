import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bazi_utils.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/profile_service.dart';
import '../domain/bazi_chart.dart';
import '../services/bazi_data_service.dart';
import 'widgets/bazi_four_pillars_chart.dart';
import 'widgets/bazi_day_master_card.dart';
import 'widgets/bazi_element_balance_card.dart';
import 'widgets/bazi_pillar_column.dart';
import 'widgets/bazi_luck_pillars_widget.dart';
import 'widgets/bazi_ten_gods_widget.dart';

// Simple city preset — coordinates for True Solar Time correction
class _CityPreset {
  final String name;
  final double latitude;
  final double longitude;
  const _CityPreset(this.name, this.latitude, this.longitude);
}

const List<_CityPreset> _kCities = [
  _CityPreset('Jakarta',     -6.2088,  106.8456),
  _CityPreset('Surabaya',    -7.2575,  112.7521),
  _CityPreset('Bandung',     -6.9175,  107.6191),
  _CityPreset('Medan',        3.5952,   98.6722),
  _CityPreset('Makassar',    -5.1477,  119.4327),
  _CityPreset('Yogyakarta',  -7.7956,  110.3695),
  _CityPreset('Denpasar',    -8.6500,  115.2167),
  _CityPreset('Semarang',    -6.9932,  110.4203),
  _CityPreset('Palembang',   -2.9761,  104.7754),
  _CityPreset('Manado',       1.4748,  124.8421),
  _CityPreset('Jayapura',    -2.5337,  140.7181),
  _CityPreset('Lainnya',      0.0,       0.0),
];

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
  _CityPreset _selectedCity = _kCities.first;

  BaziChart? _chart;
  bool _isLoading = false;
  String? _errorMsg;

  // AI Oracle
  bool _isAiLoading = false;
  String? _aiInsight;

  // Luck Pillars
  bool? _isMale;
  List<LuckPillar>? _luckPillars;
  bool _luckForward = true;

  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  /// Pre-fills tanggal lahir & kota dari profil tersimpan (parity dengan WetonCalculatorScreen).
  Future<void> _loadSavedProfile() async {
    await Future.delayed(Duration.zero); // tunggu widget fully mounted
    final profile = await ref.read(profileProvider).loadProfile();
    if (profile == null) return;

    final dobUtcMs = profile['biometric_anchor']?['dob_utc_ms'] as int?;
    if (dobUtcMs == null) return;

    final dob = DateTime.fromMillisecondsSinceEpoch(dobUtcMs);
    final coords =
        profile['biometric_anchor']?['coordinates'] as Map<String, dynamic>?;
    final lat = coords?['lat'] as double? ?? 0.0;
    final lng = coords?['lng'] as double? ?? 0.0;

    if (!mounted) return;
    setState(() {
      _birthDate = dob;
      // Cocokkan ke preset kota; fallback ke 'Lainnya' bila tidak ada yang cocok
      _selectedCity = _kCities.firstWhere(
        (c) =>
            (c.latitude - lat).abs() < 0.0001 &&
            (c.longitude - lng).abs() < 0.0001,
        orElse: () => _kCities.last,
      );
      // Restore gender for Luck Pillars direction
      final String? genderStr =
          profile['biometric_anchor']?['gender'] as String?;
      if (genderStr != null) _isMale = genderStr == 'male';
    });
  }

  // ─── Step navigation ──────────────────────────────────────────────────

  void _nextStep() {
    if (_step == 0 && _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir terlebih dahulu.')),
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
        _aiInsight = null;
        _errorMsg = null;
        _luckPillars = null;
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
      final authHeader = authToken != null && !authToken.isMock
          ? 'Bearer ${authToken.uid}'
          : 'Guest ${authToken?.uid ?? 'anonymous'}';

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
      ref.read(profileProvider).saveBirthData(
        dob: _birthDate!,
        latitude: _selectedCity.latitude,
        longitude: _selectedCity.longitude,
        gender: _isMale == null ? null : (_isMale! ? 'male' : 'female'),
      );
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
  }

  // ─── AI Oracle ────────────────────────────────────────────────────────

  Future<void> _consultOracle() async {
    if (_chart == null || _birthDate == null) return;
    setState(() => _isAiLoading = true);

    final String dateStr =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
    final double? lng =
        _selectedCity.longitude != 0.0 ? _selectedCity.longitude : null;
    final double? lat =
        _selectedCity.latitude != 0.0 ? _selectedCity.latitude : null;

    // Get Day Master arketipe from loaded data
    final mastersAsync = ref.read(baziDayMastersProvider);
    final masterData = mastersAsync.asData?.value.findById(_chart!.dayMasterId);
    final arketipe = masterData?['arketipe_modern'] as String?;

    try {
      final authToken = ref.read(authProvider);
      final authHeader = authToken != null && !authToken.isMock
          ? 'Bearer ${authToken.uid}'
          : 'Guest ${authToken?.uid ?? 'anonymous'}';

      final result = await ApiService.getBaziInsight(
        birthDate: dateStr,
        birthHour: _includeHour ? _birthHour : null,
        latitude: lat,
        longitude: lng,
        dayMasterArketipe: arketipe,
        authHeader: authHeader,
      );
      setState(() => _aiInsight = result['response'] as String?);
    } catch (e) {
      setState(() => _aiInsight =
          'Orakel kosmis sedang beristirahat. Coba lagi sebentar.');
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.accentGold, size: 18),
                onPressed: _prevStep,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppTheme.accentGold, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          '四柱八字  Ba Zi',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildStep(),
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
                  activeColor: AppTheme.accentPurple,
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

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_CityPreset>(
                value: _selectedCity,
                isExpanded: true,
                dropdownColor: AppTheme.cardBg,
                icon: const Icon(Icons.expand_more_rounded,
                    color: AppTheme.accentGold),
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 14),
                items: _kCities
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (c) {
                  if (c != null) setState(() => _selectedCity = c);
                },
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

    final masterData = mastersAsync.asData?.value
        .findById(_chart!.dayMasterId);
    final pillarData = pillarsAsync.asData?.value
        .findById(_chart!.dayPillar.id);

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

          // Ten Gods row
          BaziTenGodsWidget(chart: _chart!, elementColor: elementColor),
          const SizedBox(height: 16),

          // Day Master Card
          BaziDayMasterCard(
            dayPillar: _chart!.dayPillar,
            masterData: masterData,
          ),
          const SizedBox(height: 16),

          // Element Balance Card
          BaziElementBalanceCard(balance: _chart!.wuXingBalance),
          const SizedBox(height: 16),

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
                  pillars: _luckPillars!,
                  elementColor: elementColor,
                  isForward: _luckForward,
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
    if (_aiInsight != null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppTheme.accentGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Oracle Ba Zi',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiInsight!,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.65),
            ),
          ],
        ),
      );
    }

    return _isAiLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  color: AppTheme.accentGold, strokeWidth: 2),
            ),
          )
        : Column(
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
                '✦ Konsultasi AI Oracle',
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
              color: elementColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: elementColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: elementColor.withOpacity(0.7),
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
            color: selected ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withOpacity(0.6) : Colors.white12,
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
              ? btnColor.withOpacity(0.85)
              : Colors.white12,
          boxShadow: onTap != null
              ? [BoxShadow(color: btnColor.withOpacity(0.35), blurRadius: 16)]
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
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
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
