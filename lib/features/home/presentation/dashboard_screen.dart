import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weton_utils.dart';
import '../../../core/services/city_service.dart';
import '../../../core/providers/shell_providers.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/models/birth_profile.dart';
import '../../../core/widgets/city_search_sheet.dart';
import 'widgets/starry_background.dart';
import '../../../features/ai/presentation/oracle_chat_screen.dart';
import '../../../features/tarot/services/tarot_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      _showEditProfileDialog(context);
    }
  }

  /// Loads all cities from CSV via shared [CityService].
  void _loadCitiesFromCsv() async {
    final cities = await CityService.loadCitiesFromCsv();
    if (mounted) setState(() => _allCities = cities);
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final currentProfile = ref.read(birthProfileProvider).value ?? const BirthProfile();
    
    DateTime? selectedDate = currentProfile.dobDate;
    int? selectedHour = currentProfile.birthHour;
    String? selectedGender = currentProfile.gender;
    
    CityPreset selectedCity = _allCities.firstWhere(
      (c) => (c.latitude - (currentProfile.latitude ?? -6.2088)).abs() < 0.0001 &&
             (c.longitude - (currentProfile.longitude ?? 106.8456)).abs() < 0.0001,
      orElse: () => _allCities.isNotEmpty 
          ? _allCities.firstWhere((c) => c.name == 'Jakarta', orElse: () => _allCities.first)
          : const CityPreset(name: 'Jakarta', latitude: -6.2088, longitude: 106.8456),
    );

    await showDialog(
      context: context,
      barrierDismissible: currentProfile.dobDate != null,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentGold),
              const SizedBox(width: 8),
              Text(
                'Identitas Kosmis',
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sesuaikan data kelahiran Anda untuk menyelaraskan Weton, Ba Zi, dan Tarot.',
                  style: TextStyle(color: AppTheme.textLight, height: 1.4),
                ),
                const SizedBox(height: 20),
                
                // 1. Tanggal Lahir
                Text(
                  'Tanggal Lahir',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.background,
                    foregroundColor: AppTheme.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month, color: AppTheme.accentGold),
                  label: Text(
                    selectedDate == null
                        ? 'Pilih Tanggal'
                        : '${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime(2000, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.accentPurple,
                            onPrimary: AppTheme.textLight,
                            surface: AppTheme.cardBg,
                            onSurface: AppTheme.textLight,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 16),

                // 2. Jam Lahir (Opsional)
                Text(
                  'Jam Lahir',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      dropdownColor: AppTheme.cardBg,
                      value: selectedHour,
                      hint: const Text('Pilih Jam Lahir (Opsional)', style: TextStyle(color: AppTheme.textMuted)),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentGold),
                      style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tidak Tahu'),
                        ),
                        ...List.generate(24, (index) {
                          return DropdownMenuItem<int?>(
                            value: index,
                            child: Text('${index.toString().padLeft(2, '0')}:00'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedHour = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Gender (Opsional)
                Text(
                  'Jenis Kelamin (Gender)',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      dropdownColor: AppTheme.cardBg,
                      value: selectedGender,
                      hint: const Text('Pilih Jenis Kelamin (Opsional)', style: TextStyle(color: AppTheme.textMuted)),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentGold),
                      style: const TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Pilih...'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'male',
                          child: Text('Laki-laki'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'female',
                          child: Text('Perempuan'),
                        ),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedGender = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Tempat Lahir (Kota)
                Text(
                  'Kota Tempat Lahir',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.background,
                    foregroundColor: AppTheme.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon: const Icon(Icons.location_on, color: AppTheme.accentGold),
                  label: Text(
                    selectedCity.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final selected = await showModalBottomSheet<CityPreset>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => CitySearchSheet(
                        cityPresets: _allCities.isEmpty 
                            ? [const CityPreset(name: 'Jakarta', latitude: -6.2088, longitude: 106.8456)] 
                            : _allCities,
                      ),
                    );
                    if (selected != null) {
                      setDialogState(() => selectedCity = selected);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (currentProfile.dobDate != null)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
              ),
            TextButton(
              onPressed: selectedDate == null
                  ? null
                  : () async {
                      await ref.read(birthProfileProvider.notifier).saveAll(
                        dob: selectedDate!,
                        birthHour: selectedHour,
                        latitude: selectedCity.latitude,
                        longitude: selectedCity.longitude,
                        cityName: selectedCity.name,
                        gender: selectedGender,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Identitas kosmis berhasil diselaraskan!'),
                            backgroundColor: AppTheme.accentPurple,
                          ),
                        );
                      }
                    },
              child: Text(
                'Simpan',
                style: TextStyle(
                  color: selectedDate == null ? AppTheme.textMuted : AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _pranataMangsaName {
    final id = WetonUtils.calculatePranataMangsaId(DateTime.now());
    const names = [
      'Kasa', 'Karo', 'Katiga', 'Kapat', 'Kalima',
      'Kanem', 'Kapitu', 'Kawolu', 'Kasanga', 'Kadasa',
      'Desta', 'Saddha',
    ];
    if (id < 1 || id > 12) return 'Pergantian Mangsa';
    return names[id - 1];
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
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

          // Content
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
    final profileAsync = ref.watch(birthProfileProvider);
    final profile = profileAsync.value;
    final hasProfile = profile?.dobDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileHeader(session),
        const SizedBox(height: 20),
        _buildIdentityCard(),
        if (session == null || session.isMock) ...[
          const SizedBox(height: 12),
          _buildGuestUpsellCard(),
        ],
        const SizedBox(height: 20),
        _buildQuickNavGrid(crossAxisCount: 2, childAspectRatio: 1.6),
        const SizedBox(height: 16),
        _buildSesepuhCard(hasProfile: hasProfile, session: session),
        const SizedBox(height: 24),
        _buildFooter(session),
      ],
    );
  }

  Widget _buildDesktopLayout(UserSession? session) {
    final profileAsync = ref.watch(birthProfileProvider);
    final profile = profileAsync.value;
    final hasProfile = profile?.dobDate != null;

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — profile + identity
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(session),
                const SizedBox(height: 24),
                _buildIdentityCard(),
                if (session == null || session.isMock) ...[
                  const SizedBox(height: 12),
                  _buildGuestUpsellCard(),
                ],
                const SizedBox(height: 16),
                _buildSesepuhCard(hasProfile: hasProfile, session: session),
                const SizedBox(height: 24),
                _buildFooter(session),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Right — quick nav
          Expanded(
            flex: 5,
            child: _buildQuickNavGrid(crossAxisCount: 2, childAspectRatio: 1.5),
          ),
        ],
    );
  }

  Widget _buildProfileHeader(UserSession? session) {
    final name = session?.displayName ?? 'Penjelajah';
    final email = session?.email ?? '';
    final isGuest = session == null || session.isMock;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
            color: AppTheme.cardBg,
          ),
          child: session?.photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    session!.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarInitial(initial),
                  ),
                )
              : _avatarInitial(initial),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isGuest
                      ? AppTheme.textMuted.withValues(alpha: 0.15)
                      : AppTheme.accentPurple.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGuest
                        ? AppTheme.textMuted.withValues(alpha: 0.3)
                        : AppTheme.accentPurple.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  isGuest ? 'Mode Tamu' : 'Akun Aktif',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isGuest ? AppTheme.textMuted : AppTheme.accentPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial(String initial) => Center(
        child: Text(
          initial,
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.accentGold,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildIdentityCard() {
    final profileAsync = ref.watch(birthProfileProvider);
    final profile = profileAsync.value ?? const BirthProfile();
    final dob = profile.dobDate;
    final weton = profile.weton;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 16),
              const SizedBox(width: 8),
              Text(
                'Identitas Kosmis',
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (dob != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.accentGold, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditProfileDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!profileAsync.hasValue && profileAsync.isLoading)
            const Center(
              child: SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentGold,
                ),
              ),
            )
          else if (dob == null)
            _buildNoIdentityPrompt()
          else ...[
            _identityRow(
              Icons.cake_outlined,
              'Tanggal Lahir',
              '${dob.day} / ${dob.month} / ${dob.year}',
            ),
            const SizedBox(height: 12),
            _identityRow(
              Icons.brightness_medium_rounded,
              'Weton',
              weton != null ? '${weton.saptawara} ${weton.pancawara}' : '—',
              badge: weton != null ? 'Neptu ${weton.totalNeptu}' : null,
            ),
            const SizedBox(height: 12),
            _identityRow(
              Icons.rotate_right_rounded,
              'Wuku',
              weton?.wuku ?? '—',
            ),
            const SizedBox(height: 12),
            _identityRow(
              Icons.eco_outlined,
              'Pranata Mangsa',
              _pranataMangsaName,
              subtitle: 'Musim saat ini',
            ),
            if (profile.cityName != null && profile.cityName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _identityRow(
                Icons.location_on_outlined,
                'Tempat Lahir',
                profile.cityName!,
              ),
            ],
            if (profile.birthHour != null) ...[
              const SizedBox(height: 12),
              _identityRow(
                Icons.access_time_outlined,
                'Jam Lahir',
                '${profile.birthHour!.toString().padLeft(2, '0')}:00 WIB',
              ),
            ],
            if (profile.gender != null) ...[
              const SizedBox(height: 12),
              _identityRow(
                Icons.person_outline,
                'Jenis Kelamin',
                profile.gender == 'male' ? 'Laki-laki' : 'Perempuan',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNoIdentityPrompt() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          // Decorative icon cluster
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_outline_rounded,
                  color: AppTheme.accentGold.withValues(alpha: 0.35), size: 13),
              const SizedBox(width: 6),
              Icon(Icons.auto_awesome,
                  color: AppTheme.accentGold.withValues(alpha: 0.65), size: 18),
              const SizedBox(width: 6),
              Icon(Icons.star_outline_rounded,
                  color: AppTheme.accentGold.withValues(alpha: 0.35), size: 13),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Identitas Kosmis Belum Terisi',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textLight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan tanggal lahir untuk membuka\nweton, Ba Zi, dan wawasan kosmis Anda.',
            style: GoogleFonts.outfit(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(context),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Isi Identitas Kosmis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold.withValues(alpha: 0.15),
                foregroundColor: AppTheme.accentGold,
                side: const BorderSide(color: AppTheme.accentGold, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );

  Widget _identityRow(
    IconData icon,
    String label,
    String value, {
    String? badge,
    String? subtitle,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentGold.withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.40),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _buildQuickNavGrid({int crossAxisCount = 2, double childAspectRatio = 1.6}) {
    final items = [
      _QuickNavItem(
        icon: Icons.auto_awesome,
        label: 'Tarot',
        subtitle: 'Soul Card & Kosmis',
        color: AppTheme.accentPink,
        tabIndex: 1,
      ),
      _QuickNavItem(
        icon: Icons.brightness_medium_rounded,
        label: 'Weton',
        subtitle: 'Primbon Jawa',
        color: AppTheme.accentPurple,
        tabIndex: 2,
      ),
      _QuickNavItem(
        icon: Icons.calendar_month_rounded,
        label: 'Planner',
        subtitle: 'Kalender Kosmis',
        color: AppTheme.accentGold,
        tabIndex: 3,
      ),
      _QuickNavItem(
        icon: Icons.grid_4x4_rounded,
        label: 'Ba Zi',
        subtitle: '四柱八字',
        color: AppTheme.elementWater,
        tabIndex: 4,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jelajahi',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textLight.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: items.map(_buildNavTile).toList(),
        ),
      ],
    );
  }

  Widget _buildNavTile(_QuickNavItem item) {
    return GestureDetector(
      onTap: () => ref.read(activeTabProvider.notifier).setTab(item.tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: item.color.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: GoogleFonts.outfit(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              item.subtitle,
              style: GoogleFonts.outfit(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSesepuhCard({required bool hasProfile, UserSession? session}) {
    final Color accentColor = const Color(0xFF5C6BC0); // Deep Indigo
    // Gate: butuh minimal 2 dari 3 sistem (weton + tarot) — bazi tidak bisa dicek dari dashboard
    final tarotDrawn = ref.read(drawnCardProvider)?.isNotEmpty ?? false;
    final canOpenSesepuh = hasProfile && tarotDrawn;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: hasProfile ? accentColor.withValues(alpha: 0.45) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          if (hasProfile)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: hasProfile ? accentColor : AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Sesepuh Kosmis',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasProfile ? Colors.white : AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasProfile ? accentColor.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasProfile ? accentColor.withValues(alpha: 0.4) : Colors.white12,
                  ),
                ),
                child: Text(
                  'Grand Reading',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasProfile ? accentColor : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasProfile
                ? 'Hubungkan getaran Weton Jawa, arketipe Ba Zi, dan tebaran Tarot dalam satu pembacaan kosmis terintegrasi.'
                : 'Lengkapi profil kelahiran Anda untuk membuka Orakel Sintesis Sesepuh Kosmis.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              height: 1.45,
              color: hasProfile ? Colors.white70 : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canOpenSesepuh
                  ? () async {
                      String authHeader = 'Guest anonymous';
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
                      
                      if (!mounted) return;
                      // Build synthesis context from all available data sources
                      final weton = ref.read(birthProfileProvider).value?.weton;
                      final drawnCards = ref.read(drawnCardProvider);

                      final synthesisContext = <String, dynamic>{
                        if (weton != null)
                          'wetonLahir': {
                            'nama': '${weton.saptawara} ${weton.pancawara}',
                            'neptu': weton.totalNeptu,
                            'elemen': '',
                            'karakter': weton.characterSummary,
                          },
                        if (weton != null && weton.pangarasan.isNotEmpty)
                          'pangarasan': weton.pangarasan,
                        if (drawnCards != null && drawnCards.isNotEmpty)
                          'tarotCards': drawnCards
                              .map((c) => {
                                    'name': c.card.nameId,
                                    'label': c.label,
                                    'isReversed': c.isReversed,
                                    'archetype': c.card.archetypeId,
                                    'element': c.card.elementalId,
                                    'aiHook': c.card.aiHookId,
                                    'keywords': c.card.keywordsId,
                                  })
                              .toList(),
                      };

                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OracleChatScreen(
                            oracleType: 'synthesis',
                            authHeader: authHeader,
                            aiContext: synthesisContext.isEmpty ? null : synthesisContext,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canOpenSesepuh ? accentColor.withValues(alpha: 0.3) : Colors.white10,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: canOpenSesepuh ? accentColor : Colors.transparent,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                hasProfile ? 'Mulai Dialog Sintesis' : 'Lengkapi 2 dari 3 sistem untuk membuka Grand Reading',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestUpsellCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentPurple.withValues(alpha: 0.12),
              AppTheme.accentGold.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.accentPurple.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: AppTheme.accentPurple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simpan perjalanan kosmis Anda',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Masuk untuk sinkronisasi data & history bacaan lintas perangkat.',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  ref.read(authProvider.notifier).signInWithGoogle(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Masuk',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildFooter(UserSession? session) {
    return Column(
      children: [
        if (session != null && !session.isMock)
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
            label: const Text(
              'Keluar',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Aestral • Zero-Budget High-Performance',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuickNavItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int tabIndex;

  const _QuickNavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.tabIndex,
  });
}
