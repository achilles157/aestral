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
import '../../../core/utils/weton_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<CityPreset> _allCities = [];

  @override
  void initState() {
    super.initState();
    _loadCitiesFromCsv();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileAndPrompt());
  }

  void _checkProfileAndPrompt() async {
    final profile = await ref.read(birthProfileProvider.future);
    if (!mounted) return;
    if (profile.dobDate == null) {
      showEditProfileDialog(context, ref, _allCities);
    }
  }

  /// Loads all cities from CSV via shared [CityService].
  void _loadCitiesFromCsv() async {
    final cities = await CityService.loadCitiesFromCsv();
    if (mounted) setState(() => _allCities = cities);
  }


  @override
  Widget build(BuildContext context) {
    final session    = ref.watch(authProvider);
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
          onEditTap: () =>
              showEditProfileDialog(context, ref, _allCities),
        ),
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
        const DashboardQuickNavGrid(
            crossAxisCount: 2, childAspectRatio: 1.6),
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
              crossAxisCount: 2, childAspectRatio: 1.5),
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
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
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
            onPressed: () =>
                ref.read(authProvider.notifier).signInWithGoogle(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWukuUrgencyBanner() {
    final today = DateTime.now();
    final todayWuku = WetonUtils.calculateWeton(today).wuku;
    int daysLeft = 7;
    for (int i = 1; i <= 7; i++) {
      if (WetonUtils.calculateWeton(today.add(Duration(days: i))).wuku != todayWuku) {
        daysLeft = i;
        break;
      }
    }
    if (daysLeft > 3) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              color: Color(0xFFD4AF37), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Energi Wuku $todayWuku berakhir dalam $daysLeft hari — simpan profilmu sebelum periode ini berlalu.',
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
