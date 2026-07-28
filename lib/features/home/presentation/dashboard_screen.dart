import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/services/city_service.dart';
import '../../../core/widgets/city_search_sheet.dart';
import '../../auth/services/auth_service.dart';
import 'widgets/starry_background.dart';
import 'widgets/dashboard_profile_header.dart';
import 'widgets/dashboard_identity_card.dart';
import 'widgets/dashboard_quick_nav_grid.dart';
import 'widgets/dashboard_sesepuh_card.dart';
import 'widgets/dashboard_guest_upsell_card.dart';
import 'widgets/dashboard_footer.dart';
import 'widgets/edit_profile_dialog.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/shell_providers.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/utils/weton_utils.dart';
import '../../history/presentation/history_screen.dart';
import '../../hari_baik/presentation/hari_baik_screen.dart';
import '../../profiles/presentation/saved_profiles_screen.dart';
import 'widgets/cosmic_calibration_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<CityPreset> _allCities = [];
  // Cached wuku urgency — computed once in initState, not on every build.
  String? _todayWuku;
  int _wukuDaysLeft = 7;
  bool _isHariWeton = false;
  String _hariWetonName = '';

  @override
  void initState() {
    super.initState();
    _loadCitiesFromCsv();
    _computeWukuUrgency();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkProfileAndPrompt(),
    );
  }

  void _computeWukuUrgency() {
    final today = DateTime.now();
    final wuku = WetonUtils.calculateWeton(today).wuku;
    int days = 7;
    for (int i = 1; i <= 7; i++) {
      if (WetonUtils.calculateWeton(today.add(Duration(days: i))).wuku !=
          wuku) {
        days = i;
        break;
      }
    }
    _todayWuku = wuku;
    _wukuDaysLeft = days;
  }

  void _checkProfileAndPrompt() async {
    final profile = await ref.read(birthProfileProvider.future);
    if (!mounted) return;
    if (profile.dobDate == null) {
      showEditProfileDialog(context, ref, _allCities);
    } else {
      _checkHariWeton(profile.dobDate!);
      _checkMorningForecast(profile.dobDate!);
    }
  }

  void _checkHariWeton(DateTime dob) {
    final birthWeton = WetonUtils.calculateWeton(dob);
    final todayWeton = WetonUtils.calculateWeton(DateTime.now());
    if (!mounted) return;
    setState(() {
      _isHariWeton =
          birthWeton.saptawara == todayWeton.saptawara &&
          birthWeton.pancawara == todayWeton.pancawara;
      _hariWetonName = '${birthWeton.saptawara} ${birthWeton.pancawara}';
    });
  }

  Future<void> _checkMorningForecast(DateTime dob) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final prefKey = 'morning_forecast_shown_$todayStr';

      if (prefs.getBool(prefKey) == true) return;

      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final now = DateTime.now();
      final dobStr = DateFormat('yyyy-MM-dd').format(dob);

      final response = await ApiService.getCalendarMonth(
        birthDate: dobStr,
        targetYear: now.year,
        targetMonth: now.month,
        authHeader: authHeader,
      );

      if (!mounted) return;

      final days = response['days'] as List<dynamic>?;
      if (days == null || days.isEmpty) return;

      final todayData = days.firstWhere(
        (d) => d['date'] == todayStr,
        orElse: () => null,
      );

      if (todayData == null) return;

      // Mark as shown today
      await prefs.setBool(prefKey, true);

      // Show custom dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _buildMorningForecastDialog(ctx, todayData),
      );
    } catch (e) {
      debugPrint('DashboardScreen: Error checking morning forecast — $e');
      // Offline fallback: compute locally with WetonUtils so dialog still shows
      if (!mounted) return;
      try {
        final prefs = await SharedPreferences.getInstance();
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final prefKey = 'morning_forecast_shown_$todayStr';
        if (prefs.getBool(prefKey) == true) return;

        final birthWeton = WetonUtils.calculateWeton(dob);
        final todayWeton = WetonUtils.calculateWeton(DateTime.now());
        final isDinoWas = WetonUtils.checkIsDinoWas(dob, DateTime.now());
        final sisaBagi = (birthWeton.totalNeptu + todayWeton.totalNeptu) % 5;
        final pranataId = WetonUtils.calculatePranataMangsaId(DateTime.now());

        final offlineData = <String, dynamic>{
          'weton_hari_ini': '${todayWeton.saptawara} ${todayWeton.pancawara}',
          'wuku': todayWeton.wuku,
          'neptu': todayWeton.totalNeptu,
          'is_dino_was': isDinoWas,
          'is_wuku_rawan': false,
          'is_mangsa_rawan': pranataId == 4 || pranataId == 9,
          'is_bazi_clash': false,
          'is_bazi_harmony': false,
          'is_bazi_yong_shen': false,
          'sisa_bagi': sisaBagi,
        };

        await prefs.setBool(prefKey, true);
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => _buildMorningForecastDialog(ctx, offlineData),
        );
      } catch (_) {
        // Silently skip — forecast is a nice-to-have, not critical
      }
    }
  }

  Widget _buildMorningForecastDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final wetonStr = data['weton_hari_ini'] as String? ?? '';
    final wukuName = data['wuku'] as String? ?? '';
    final neptu = data['neptu'] as int? ?? 10;

    final bool isDinoWas = data['is_dino_was'] as bool? ?? false;
    final bool isWukuRawan = data['is_wuku_rawan'] as bool? ?? false;
    final bool isMangsaRawan = data['is_mangsa_rawan'] as bool? ?? false;
    final bool isBaziClash = data['is_bazi_clash'] as bool? ?? false;
    final bool isBaziHarmony = data['is_bazi_harmony'] as bool? ?? false;
    final bool isBaziYongShen = data['is_bazi_yong_shen'] as bool? ?? false;

    String energyTitle = 'Energi Stabil';
    String energyDesc =
        'Hari berjalan dengan harmoni wajar. Lakukan aktivitas harian Anda dengan ketenangan dan fokus penuh.';
    Color energyColor = Colors.white70;
    IconData energyIcon = Icons.wb_cloudy_outlined;

    if (isDinoWas) {
      energyTitle = 'Hari Refleksi Batin (Dino Was)';
      energyDesc =
          'Hari ini memancarkan energi yang mengajak Anda melambat dan berefleksi. Tunda keputusan bisnis yang tergesa-gesa, hindari perdebatan, dan prioritaskan menjaga kedamaian batin.';
      energyColor = const Color(0xFFF87171);
      energyIcon = Icons.spa_outlined;
    } else if (isBaziClash) {
      energyTitle = 'Hari Clash (Ciong) Ba Zi';
      energyDesc =
          'Pilar zodiak hari ini bertentangan dengan pilar lahir Anda. Energi berfluktuasi tinggi; disarankan bertindak sabar dan kurangi aktivitas berisiko.';
      energyColor = const Color(0xFFF87171);
      energyIcon = Icons.flash_on_rounded;
    } else if (isBaziHarmony) {
      energyTitle = 'Hari Harmoni (He) Ba Zi';
      energyDesc =
          'Energi zodiak harian bersinergi sangat manis dengan Anda. Komunikasi, negosiasi, dan pertemuan sosial diprediksi berjalan sangat lancar.';
      energyColor = const Color(0xFF34D399);
      energyIcon = Icons.handshake_outlined;
    } else if (isBaziYongShen) {
      energyTitle = 'Hari Energi Penyeimbang (Yong Shen)';
      energyDesc =
          'Hari ini memancarkan elemen penyeimbang lahir Anda. Vitalitas tubuh meningkat, pikiran lebih tajam, dan daya kreativitas berada di puncaknya!';
      energyColor = AppTheme.accentGold;
      energyIcon = Icons.wb_sunny_outlined;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        borderColor: AppTheme.accentGold.withValues(alpha: 0.35),
        borderWidth: 1.2,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_rounded,
                  color: AppTheme.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'PRAKIRAAN PAGI KOSMIS',
                  style: GoogleFonts.cinzel(
                    color: AppTheme.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              wetonStr,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Neptu $neptu • Wuku $wukuName',
              style: GoogleFonts.lato(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: energyColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: energyColor.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(energyIcon, color: energyColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          energyTitle,
                          style: GoogleFonts.outfit(
                            color: energyColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          energyDesc,
                          style: GoogleFonts.lato(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isWukuRawan || isMangsaRawan) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  if (isWukuRawan)
                    _buildWarningMicroRow(
                      icon: Icons.shield_outlined,
                      color: const Color(0xFFFB923C),
                      text:
                          'Pekan Rawan Wuku: Hindari spekulasi bisnis penting.',
                    ),
                  if (isWukuRawan && isMangsaRawan) const SizedBox(height: 6),
                  if (isMangsaRawan)
                    _buildWarningMicroRow(
                      icon: Icons.thermostat_outlined,
                      color: const Color(0xFFFB923C),
                      text:
                          'Musim Rawan Mangsa: Jaga vitalitas & imunitas tubuh.',
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.cinzel(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(activeTabProvider.notifier).setTab(3);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buka Planner',
                      style: GoogleFonts.cinzel(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningMicroRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(color: Colors.white54, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Loads all cities from CSV via shared [CityService].
  void _loadCitiesFromCsv() async {
    try {
      final cities = await CityService.loadCitiesFromCsv();
      if (mounted) setState(() => _allCities = cities);
    } catch (e) {
      debugPrint('_loadCitiesFromCsv error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);
    final hasProfile = ref.watch(birthProfileProvider).value?.dobDate != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/app_bg.png'),
                fit: BoxFit.cover,
                opacity: 0.20,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background.withValues(alpha: 0.85),
                  const Color(0xFF160E36).withValues(alpha: 0.95),
                  const Color(0xFF0C071C),
                ],
              ),
            ),
          ),
          const StarryBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 40 : 20,
                    isDesktop ? 32 : 12,
                    isDesktop ? 40 : 20,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: isDesktop
                          ? _buildDesktopLayout(session, hasProfile: hasProfile)
                          : _buildMobileLayout(session, hasProfile: hasProfile),
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

  Widget _buildMobileLayout(UserSession? session, {required bool hasProfile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardProfileHeader(session: session),
        const SizedBox(height: 20),
        DashboardIdentityCard(
          onEditTap: () => showEditProfileDialog(context, ref, _allCities),
        ),
        if (_isHariWeton) ...[
          const SizedBox(height: 12),
          _buildHariWetonBanner(),
        ],
        if (hasProfile) ...[
          const SizedBox(height: 12),
          CosmicCalibrationCard(
            birthDate: ref.watch(birthProfileProvider).value!.dobDate!,
          ),
        ],
        if (session == null || session.isMock) ...[
          const SizedBox(height: 12),
          const DashboardGuestUpsellCard(),
          if (hasProfile) ...[
            const SizedBox(height: 8),
            _buildGuestDataWarning(),
            const SizedBox(height: 6),
            _buildReadingHistoryHint(),
          ],
          _buildWukuUrgencyBanner(),
        ],
        const SizedBox(height: 20),
        const DashboardQuickNavGrid(crossAxisCount: 2, childAspectRatio: 1.6),
        if (hasProfile) ...[const SizedBox(height: 12), _buildHariBaikCard()],
        const SizedBox(height: 12),
        _buildHistoryButton(),
        const SizedBox(height: 8),
        _buildProfilesButton(),
        const SizedBox(height: 16),
        DashboardSesepuhCard(hasProfile: hasProfile),
        const SizedBox(height: 24),
        DashboardFooter(session: session),
      ],
    );
  }

  Widget _buildDesktopLayout(UserSession? session, {required bool hasProfile}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardProfileHeader(session: session),
              const SizedBox(height: 24),
              DashboardIdentityCard(
                onEditTap: () =>
                    showEditProfileDialog(context, ref, _allCities),
              ),
              if (hasProfile) ...[
                const SizedBox(height: 12),
                CosmicCalibrationCard(
                  birthDate: ref.watch(birthProfileProvider).value!.dobDate!,
                ),
              ],
              if (session == null || session.isMock) ...[
                const SizedBox(height: 12),
                const DashboardGuestUpsellCard(),
                if (hasProfile) ...[
                  const SizedBox(height: 8),
                  _buildGuestDataWarning(),
                  const SizedBox(height: 6),
                  _buildReadingHistoryHint(),
                ],
                _buildWukuUrgencyBanner(),
              ],
              if (hasProfile) ...[
                const SizedBox(height: 12),
                _buildHariBaikCard(),
              ],
              const SizedBox(height: 12),
              _buildHistoryButton(),
              const SizedBox(height: 8),
              _buildProfilesButton(),
              const SizedBox(height: 16),
              DashboardSesepuhCard(hasProfile: hasProfile),
              const SizedBox(height: 24),
              DashboardFooter(session: session),
            ],
          ),
        ),
        const SizedBox(width: 32),
        const Expanded(
          flex: 5,
          child: DashboardQuickNavGrid(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestDataWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data kosmismu belum tersimpan permanen — tutup app, data hilang.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.orange.shade200,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWukuUrgencyBanner() {
    if (_todayWuku == null || _wukuDaysLeft > 3) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFFD4AF37),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Energi Wuku $_todayWuku berakhir dalam $_wukuDaysLeft hari — simpan profilmu sebelum periode ini berlalu.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHariBaikCard() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HariBaikScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentGold.withValues(alpha: 0.12),
              const Color(0xFF9C27B0).withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentGold.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hari Baik Finder',
                    style: GoogleFonts.cinzel(
                      color: AppTheme.accentGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Temukan hari terbaik untuk rencanamu',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.accentGold.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesButton() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SavedProfilesScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profil Tersimpan',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: AppTheme.accentGold.withValues(alpha: 0.8),
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Riwayat Kosmis',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHariWetonBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withValues(alpha: 0.15),
            const Color(0xFF9C27B0).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Text(
            '✦',
            style: TextStyle(color: AppTheme.accentGold, fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rahayu — Hari Wetonmu',
                  style: GoogleFonts.cinzel(
                    color: AppTheme.accentGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Weton $_hariWetonName kembali hari ini. Momen sakral untuk refleksi dan syukur.',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingHistoryHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Riwayat bacaanmu akan otomatis tersimpan setelah masuk.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ),
          const Icon(Icons.lock_outline, color: Colors.white24, size: 14),
        ],
      ),
    );
  }
}
