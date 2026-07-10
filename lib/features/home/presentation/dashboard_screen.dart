import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../core/widgets/cosmic_auth_bottom_sheet.dart';

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
    final session = ref.watch(authProvider);

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
                          ? _buildDesktopLayout(session)
                          : _buildMobileLayout(session),
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
  Widget _buildMobileLayout(UserSession? session) {
    final hasProfile =
        ref.watch(birthProfileProvider).value?.dobDate != null;
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

  Widget _buildDesktopLayout(UserSession? session) {
    final hasProfile =
        ref.watch(birthProfileProvider).value?.dobDate != null;
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
}
