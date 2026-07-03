import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/profile_service.dart';
import '../../auth/services/auth_service.dart';
import '../services/weton_dictionary_service.dart';
import '../../../core/services/api_service.dart';
import 'widgets/seasonal_banner.dart';
import '../domain/pranata_mangsa.dart';
import '../data/pranata_mangsa_repository.dart';
import 'widgets/circadian_rhythm_wave_painter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/radial_glow_painter.dart';
import '../../../core/widgets/astrological_dial_timepiece.dart';
import '../../../core/widgets/ai_astrologer_dialog.dart';

class AstrologicalPlannerScreen extends ConsumerStatefulWidget {
  const AstrologicalPlannerScreen({super.key});

  @override
  ConsumerState<AstrologicalPlannerScreen> createState() => _AstrologicalPlannerScreenState();
}

class _AstrologicalPlannerScreenState extends ConsumerState<AstrologicalPlannerScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _birthDate;
  bool _isLoadingCalendar = false;
  Map<String, dynamic>? _calendarData;
  String? _errorMessage;
  SharedPreferences? _prefs;
  
  final Map<String, bool> _checklists = {};

  @override
  void initState() {
    super.initState();
    _initPreferences();
    _loadProfileAndFetch();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        for (final key in _prefs!.getKeys()) {
          if (key.startsWith('planner_task_')) {
            _checklists[key] = _prefs!.getBool(key) ?? false;
          }
        }
      });
    }
  }

  Future<void> _loadProfileAndFetch() async {
    setState(() {
      _isLoadingCalendar = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(profileProvider).loadProfile();
      if (profile != null) {
        final dobUtcMs = profile['biometric_anchor']?['dob_utc_ms'] as int?;
        if (dobUtcMs != null) {
          _birthDate = DateTime.fromMillisecondsSinceEpoch(dobUtcMs);
        }
      }
      
      _birthDate ??= DateTime(1995, 10, 25);
      await _fetchCalendarData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat profil atau kalender: $e';
          _isLoadingCalendar = false;
        });
      }
    }
  }

  Future<void> _fetchCalendarData() async {
    if (_birthDate == null) return;

    setState(() {
      _isLoadingCalendar = true;
      _errorMessage = null;
    });

    final birthStr = DateFormat('yyyy-MM-dd').format(_birthDate!);
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
          debugPrint('Planner: Gagal mendapatkan token Firebase: $e');
        }
      }
    }

    try {
      final response = await ApiService.getCalendarMonth(
        birthDate: birthStr,
        targetYear: _currentMonth.year,
        targetMonth: _currentMonth.month,
        authHeader: authHeader,
      );

      if (mounted) {
        setState(() {
          _calendarData = response;
          _isLoadingCalendar = false;
        });
      }
    } catch (e) {
      debugPrint('Planner API gagal: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Koneksi ke backend gagal. Fitur kalender memerlukan koneksi online.';
          _isLoadingCalendar = false;
        });
      }
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      _calendarData = null;
    });
    _fetchCalendarData();
  }

  void _presentDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AstrologicalDialTimepiece(
          initialDateTime: _birthDate ?? DateTime(2000, 1, 1),
          showTime: false,
          onDateTimeSelected: (dt) {
            if (dt != _birthDate) {
              setState(() {
                _birthDate = dt;
                _calendarData = null;
              });
              _fetchCalendarData();
            }
          },
        );
      },
    );
  }

  Color _getPancasudaColor(String vibe) {
    switch (vibe) {
      case 'green':
        return const Color(0xFF10B981);
      case 'gold':
        return AppTheme.accentGold;
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'orange':
        return const Color(0xFFFB923C);
      case 'purple':
        return AppTheme.accentPurple;
      default:
        return AppTheme.textLight;
    }
  }

  Widget _buildHeaderSection() {
    return GlassCard(
      borderColor: AppTheme.accentGold.withValues(alpha: 0.25),
      borderWidth: 1.0,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.accentGold),
            onPressed: () => _changeMonth(-1),
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_birthDate != null)
                Text(
                  'Profil Lahir: ${DateFormat('dd MMM yyyy').format(_birthDate!)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.accentGold.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.accentGold),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildPranataHeader(AsyncValue<List<PranataMangsaModel>> pranataListAsync) {
    final pranataInfo = _calendarData!['pranata_mangsa'] as Map<String, dynamic>?;
    if (pranataInfo == null) return const SizedBox.shrink();

    final mangsaId = pranataInfo['id'] as int? ?? 1;

    return pranataListAsync.when(
      data: (list) {
        final activeMangsa = list.firstWhere(
          (m) => m.id == mangsaId,
          orElse: () => list.first,
        );
        return SeasonalBanner(mangsa: activeMangsa);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _calendarData!['days'] as List<dynamic>? ?? [];
    if (days.isEmpty) return const SizedBox.shrink();

    final weekdays = ['Ming', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final firstDayStr = days[0]['date'] as String;
    final firstDate = DateTime.parse(firstDayStr);
    final prefixBlankCells = firstDate.weekday == 7 ? 0 : firstDate.weekday;

    return GlassCard(
      borderColor: AppTheme.accentPurple.withValues(alpha: 0.25),
      borderWidth: 1.0,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemCount: prefixBlankCells + days.length,
            itemBuilder: (context, index) {
              if (index < prefixBlankCells) {
                return const SizedBox.shrink();
              }

              final dayData = days[index - prefixBlankCells] as Map<String, dynamic>;
              final date = DateTime.parse(dayData['date'] as String);
              final wetonStr = dayData['weton_hari_ini'] as String;
              final pasaran = wetonStr.split(' ').last;
              
              final pancasuda = dayData['pancasuda'] as Map<String, dynamic>;
              final vibe = pancasuda['vibe_warna'] as String;
              final statusColor = _getPancasudaColor(vibe);

              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return InkWell(
                onTap: () => _showDayDetailSheet(dayData),
                borderRadius: BorderRadius.circular(12),
                child: GlassCard(
                  borderRadius: 12,
                  borderColor: isToday
                      ? AppTheme.accentPurple.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                  borderWidth: isToday ? 1.5 : 0.8,
                  color: isToday
                      ? AppTheme.accentPurple.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.03),
                  child: CustomPaint(
                    painter: RadialGlowPainter(
                      glowColor: statusColor,
                      radiusMultiplier: 0.8,
                      opacity: 0.2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pasaran,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: AppTheme.textLight.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayDetailSheet(Map<String, dynamic> dayData) {
    final dateStr = dayData['date'] as String;
    final date = DateTime.parse(dateStr);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(date),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Weton: ${dayData['weton_hari_ini']} (Neptu ${dayData['neptu']})',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildUnifiedTimeline(dayData, scrollController),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUnifiedTimeline(Map<String, dynamic> dayData, ScrollController scrollController) {
    final dateStr = dayData['date'] as String;
    final pancasuda = dayData['pancasuda'] as Map<String, dynamic>;
    final vibeColor = _getPancasudaColor(pancasuda['vibe_warna'] as String);
    final wukuName = dayData['wuku'] as String;
    final timetable = dayData['timetable'] as Map<String, dynamic>?;

    final List<dynamic> jamBaik = timetable?['jam_baik'] as List<dynamic>? ?? [];
    final List<dynamic> jamNaas = timetable?['jam_naas'] as List<dynamic>? ?? [];

    final List<Map<String, dynamic>> slots = [];
    for (var i = 0; i < jamBaik.length; i++) {
      slots.add({
        'data': jamBaik[i] as Map<String, dynamic>,
        'type': 'baik',
        'index': i,
      });
    }
    for (var i = 0; i < jamNaas.length; i++) {
      slots.add({
        'data': jamNaas[i] as Map<String, dynamic>,
        'type': 'naas',
        'index': i,
      });
    }
    slots.sort((a, b) {
      final rangeA = a['data']['range'] as String;
      final rangeB = b['data']['range'] as String;
      return rangeA.compareTo(rangeB);
    });

    return Consumer(
      builder: (context, ref, child) {
        final wukuListAsync = ref.watch(wukuProvider);

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            GlassCard(
              borderColor: vibeColor.withValues(alpha: 0.35),
              borderWidth: 1.5,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Petungan Hari: ${pancasuda['fase']}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: vibeColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: vibeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Energi: ${pancasuda['tingkat_energi']}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: vibeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pancasuda['saran_singkat'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            wukuListAsync.when(
              data: (list) {
                final wukuEntry = list.firstWhere(
                  (w) => w['nama_wuku'].toString().toLowerCase() == wukuName.toLowerCase(),
                  orElse: () => list.first,
                );
                return GlassCard(
                  borderColor: AppTheme.accentPink.withValues(alpha: 0.25),
                  borderWidth: 1.0,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wuku ${wukuEntry['nama_wuku']} (${wukuEntry['arketipe_modern'] ?? ''})',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dewa Penaung: ${wukuEntry['dewa_penaung'] ?? ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        wukuEntry['karakter_dasar'] ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.work_outline, color: AppTheme.accentGold, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Karir Wuku',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  wukuEntry['ramalan_mingguan_karier'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite_border, color: AppTheme.accentPink, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Asmara Wuku',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  wukuEntry['ramalan_mingguan_asmara'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
              error: (err, _) => Center(child: Text('Gagal memuat detail wuku: $err')),
            ),
            const SizedBox(height: 28),

            Text(
              'Jadwal Jam Saat Pitu (Timetable)',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 12),

            Stack(
              children: [
                // Circadian Rhythm Wave background painter
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CircadianRhythmWavePainter(
                        slots: slots.map((s) => s['type'] as String).toList(),
                      ),
                    ),
                  ),
                ),
                // Timeline Items
                Column(
                  children: List.generate(slots.length, (idx) {
                    final slot = slots[idx];
                    final data = slot['data'];
                    final isBaik = slot['type'] == 'baik';
                    final range = data['range'] as String;
                    final label = data['label'] as String;
                    final rec = data['rekomendasi'] as String;

                    final taskKey = 'planner_task_${dateStr}_${slot['type']}_${slot['index']}';
                    final isChecked = _checklists[taskKey] ?? false;

                    final cardColor = isBaik ? const Color(0xFF10B981) : AppTheme.accentPink;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline Node alignment (offset to match Circadian Wave)
                          Container(
                            width: 32,
                            alignment: isBaik ? const Alignment(0.5, 0.0) : const Alignment(-0.5, 0.0),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor,
                                border: Border.all(color: AppTheme.accentGold, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: cardColor.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Timeline Glass Card Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GlassCard(
                                borderColor: cardColor.withValues(alpha: 0.25),
                                borderWidth: 1.0,
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white30),
                                      child: Checkbox(
                                        value: isChecked,
                                        activeColor: cardColor,
                                        onChanged: (val) async {
                                          if (val != null && _prefs != null) {
                                            await _prefs!.setBool(taskKey, val);
                                            setState(() {
                                              _checklists[taskKey] = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                range,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: cardColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: cardColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            rec,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              final aiHookText = 'Sebagai seorang dengan weton ${dayData['weton_hari_ini']}, bagaimana pengaruh jam $label ($range) hari ini terhadap aktivitas dan keselarasan energi saya?';
                                              showDialog(
                                                context: context,
                                                builder: (context) => AiAstrologerDialog(
                                                  prompt: aiHookText,
                                                  contextTitle: '$label ($range)',
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: cardColor.withValues(alpha: 0.5), width: 1.0),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: Icon(Icons.auto_awesome, size: 12, color: cardColor),
                                            label: Text(
                                              'Tanya AI Astrolog',
                                              style: GoogleFonts.outfit(fontSize: 11, color: cardColor, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
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
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final buffer = StringBuffer();
                buffer.writeln('Astrological Schedule: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(dateStr))}');
                buffer.writeln('Weton: ${dayData['weton_hari_ini']} (Neptu ${dayData['neptu']})');
                buffer.writeln('----------------------------------------');
                for (final slot in slots) {
                  final data = slot['data'];
                  buffer.writeln('[${data['range']}] ${data['label']}');
                  buffer.writeln('${data['rekomendasi']}');
                  buffer.writeln();
                }
                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jadwal harian disalin ke clipboard!')),
                );
              },
              icon: const Icon(Icons.content_copy),
              label: const Text('Salin Seluruh Jadwal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pranataListAsync = ref.watch(pranataMangsaListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Astrological Planner',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cake_outlined, color: AppTheme.accentGold),
            onPressed: _presentDatePicker,
            tooltip: 'Sesuaikan Tanggal Lahir',
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 16),
                    if (_isLoadingCalendar) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60.0),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.accentGold),
                        ),
                      ),
                    ] else if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchCalendarData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                              )
                            ],
                          ),
                        ),
                      ),
                    ] else if (_calendarData != null) ...[
                      _buildPranataHeader(pranataListAsync),
                      const SizedBox(height: 16),
                      _buildCalendarGrid(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

