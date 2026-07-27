import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/widgets/cosmic_loader.dart';
import '../../auth/services/auth_service.dart';
import '../../weton/presentation/widgets/astrological_planner_timeline.dart';
import '../models/hari_baik_result.dart';
import '../services/hari_baik_scorer.dart';

class _TujuanOption {
  final String id;
  final String emoji;
  final String label;
  const _TujuanOption(this.id, this.emoji, this.label);
}

class HariBaikScreen extends ConsumerStatefulWidget {
  const HariBaikScreen({super.key});

  @override
  ConsumerState<HariBaikScreen> createState() => _HariBaikScreenState();
}

class _HariBaikScreenState extends ConsumerState<HariBaikScreen> {
  String _tujuan = 'umum';
  int _rentang = 1;
  List<HariBaikResult> _results = [];
  bool _isLoading = false;
  String? _errorMsg;
  DateTime? _birthDate;

  static final _tujuanOptions = [
    _TujuanOption('umum', '\u2726', 'Umum'),
    _TujuanOption('karir_bisnis', '\u{1F4BC}', 'Karir & Bisnis'),
    _TujuanOption('pernikahan', '\u2764', 'Pernikahan'),
    _TujuanOption('kesehatan', '\u{1F331}', 'Kesehatan'),
    _TujuanOption('kontrak', '\u{1F4DD}', 'Kontrak / Deal'),
    _TujuanOption('peluncuran', '\u{1F680}', 'Peluncuran'),
    _TujuanOption('negosiasi', '\u{1F4AC}', 'Negosiasi'),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logHistoryViewed().catchError((_) {});
    Future.microtask(_loadAndFetch);
  }

  Future<void> _loadAndFetch() async {
    final profile = await ref.read(birthProfileProvider.future);
    if (!mounted) return;
    setState(() => _birthDate = profile.dobDate);
    if (_birthDate != null) await _fetch();
  }

  Future<void> _fetch() async {
    if (_birthDate == null) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final now = DateTime.now();
      final birthStr = DateFormat('yyyy-MM-dd').format(_birthDate!);

      final months = List.generate(
        _rentang,
        (i) => DateTime(now.year, now.month + i, 1),
      );

      final responses = await Future.wait(
        months.map(
          (m) => ApiService.getCalendarMonth(
            birthDate: birthStr,
            targetYear: m.year,
            targetMonth: m.month,
            authHeader: authHeader,
          ),
        ),
      );

      final allDays = <Map<String, dynamic>>[];
      for (final r in responses) {
        final days = r['days'] as List<dynamic>? ?? [];
        allDays.addAll(days.cast<Map<String, dynamic>>());
      }

      final results = HariBaikScorer.filter(allDays, _tujuan);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal memuat data. Pastikan internet tersambung.';
        _isLoading = false;
      });
    }
  }

  void _showDayDetail(Map<String, dynamic> dayData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          final dateStr = dayData['date'] as String? ?? '';
          final date = DateTime.tryParse(dateStr);
          final wetonStr = dayData['weton_hari_ini'] as String? ?? '';
          final neptu = dayData['neptu'] as int? ?? 0;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date != null
                                  ? DateFormat(
                                      'EEEE, dd MMMM yyyy',
                                      'id_ID',
                                    ).format(date)
                                  : dateStr,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$wetonStr (Neptu $neptu)',
                              style: GoogleFonts.outfit(
                                color: AppTheme.accentGold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: AstrologicalPlannerTimeline(
                    dayData: dayData,
                    scrollController: scrollController,
                    birthDate: _birthDate,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pencari Hari & Waktu',
          style: GoogleFonts.cinzel(
            color: AppTheme.accentGold,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0D2E)],
          ),
        ),
        child: _birthDate == null && !_isLoading
            ? _buildNoProfileState()
            : Column(
                children: [
                  _buildFilterSection(),
                  Expanded(child: _buildContent()),
                ],
              ),
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Profil belum dilengkapi',
              style: GoogleFonts.cinzel(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan tanggal lahir terlebih dahulu\nuntuk menemukan hari baikmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tujuan',
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _tujuanOptions.map((opt) {
                final isActive = _tujuan == opt.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _tujuan = opt.id);
                      _fetch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.accentGold.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.accentGold.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        '${opt.emoji} ${opt.label}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isActive
                              ? AppTheme.accentGold
                              : Colors.white60,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rentang',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              _RentangToggle(
                current: _rentang,
                onChanged: (v) {
                  setState(() => _rentang = v);
                  _fetch();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CosmicLoader(label: 'Membaca energi kosmis...'),
      );
    }
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white30,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetch,
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.outfit(color: AppTheme.accentGold),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hari baik yang ditemukan',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white38,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba perluas rentang waktu\natau ubah kategori tujuan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white24,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _HariBaikCard(
        result: _results[i],
        onTap: () => _showDayDetail(_results[i].dayData),
      ),
    );
  }
}

// ── Rentang Toggle ─────────────────────────────────────────────────────────

class _RentangToggle extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _RentangToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_item(1, 'Bulan Ini'), _item(3, '3 Bulan')],
      ),
    );
  }

  Widget _item(int value, String label) {
    final isActive = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isActive ? AppTheme.accentGold : Colors.white54,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Hari Baik Card ──────────────────────────────────────────────────────────

class _HariBaikCard extends StatelessWidget {
  final HariBaikResult result;
  final VoidCallback onTap;
  const _HariBaikCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Color(result.scoreColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: accent, width: 3),
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 1,
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.formattedDate,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${result.score}',
                          style: GoogleFonts.cinzel(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${result.wetonHariIni} \u00b7 Wuku ${result.wuku} \u00b7 Neptu ${result.neptu}',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: result.reasons.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          r,
                          style: GoogleFonts.outfit(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // ── Jam Terbaik ───────────────────────────────────────
                  Builder(
                    builder: (_) {
                      final timetable =
                          result.dayData['timetable'] as Map<String, dynamic>?;
                      final jamBaik =
                          timetable?['jam_baik'] as List<dynamic>? ?? [];
                      final best = jamBaik
                          .cast<Map<String, dynamic>>()
                          .where(
                            (s) =>
                                s['label'] == 'Saat Rezeki' ||
                                s['label'] == 'Saat Gedhong',
                          )
                          .toList();
                      if (best.isEmpty) return const SizedBox.shrink();
                      final slot = best.first;
                      final range = slot['range'] as String? ?? '';
                      final label = slot['label'] as String? ?? '';
                      final bazi =
                          slot['bazi_shi_chen'] as Map<String, dynamic>?;
                      final condition = bazi?['condition'] as String?;
                      final isRezeki = label == 'Saat Rezeki';
                      return Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: isRezeki
                                ? AppTheme.accentGold
                                : Colors.amber.shade300,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            range,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '· $label${condition != null && condition != 'Netral' ? ' · $condition' : ''}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isRezeki
                                  ? AppTheme.accentGold.withValues(alpha: 0.85)
                                  : Colors.white54,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Lihat Detail',
                        style: GoogleFonts.outfit(
                          color: accent.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: accent.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
