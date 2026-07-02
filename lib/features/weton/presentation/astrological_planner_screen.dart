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
  
  // Local checklists state map: "date_type_index" -> isChecked
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
      
      // Default fallback if no saved profile date
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

  void _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
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

    if (pickedDate != null && pickedDate != _birthDate) {
      setState(() {
        _birthDate = pickedDate;
        _calendarData = null;
      });
      _fetchCalendarData();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.cake_outlined, color: AppTheme.accentGold),
            onPressed: _presentDatePicker,
            tooltip: 'Sesuaikan Tanggal Lahir',
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
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
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
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

    // Days of week header
    final weekdays = ['Ming', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Determine JDN offsets
    final firstDayStr = days[0]['date'] as String;
    final firstDate = DateTime.parse(firstDayStr);
    final prefixBlankCells = firstDate.weekday == 7 ? 0 : firstDate.weekday; // Sunday=7/0, Mon=1, etc.

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Weekday label row
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
                final pasaran = wetonStr.split(' ').last; // Get "Pon", "Legi", etc.
                
                final pancasuda = dayData['pancasuda'] as Map<String, dynamic>;
                final vibe = pancasuda['vibe_warna'] as String;
                final statusColor = _getPancasudaColor(vibe);

                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return InkWell(
                  onTap: () => _showDayDetailSheet(dayData),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppTheme.accentPurple.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? AppTheme.accentPurple.withValues(alpha: 0.5)
                            : Colors.white10,
                        width: isToday ? 1.5 : 1.0,
                      ),
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
                        const SizedBox(height: 4),
                        // Pancasuda dot
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ]
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Drag handle
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
                  // Header
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
                  TabBar(
                    indicatorColor: AppTheme.accentGold,
                    labelColor: AppTheme.accentGold,
                    unselectedLabelColor: Colors.white38,
                    tabs: [
                      Tab(
                        child: Text(
                          'Insight & Wuku',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Timetable Harian',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildInsightTab(dayData, scrollController),
                        _buildTimetableTab(dayData, scrollController),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInsightTab(Map<String, dynamic> dayData, ScrollController scrollController) {
    final pancasuda = dayData['pancasuda'] as Map<String, dynamic>;
    final vibeColor = _getPancasudaColor(pancasuda['vibe_warna'] as String);
    final wukuName = dayData['wuku'] as String;

    return Consumer(
      builder: (context, ref, child) {
        final wukuListAsync = ref.watch(wukuProvider);
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Pancasuda Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: vibeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: vibeColor.withValues(alpha: 0.3), width: 1.5),
              ),
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
            const SizedBox(height: 24),
            // Wuku Info
            wukuListAsync.when(
              data: (list) {
                final wukuEntry = list.firstWhere(
                  (w) => w['nama_wuku'].toString().toLowerCase() == wukuName.toLowerCase(),
                  orElse: () => list.first,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siklus Pawukon: Wuku ${wukuEntry['nama_wuku']}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dewa Pelindung: ${wukuEntry['dewa']}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      wukuEntry['karakter'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pantangan / Peringatan Wuku:',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            wukuEntry['pantangan'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              height: 1.4,
                              color: const Color(0xFFF87171),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
              error: (err, _) => Center(child: Text('Gagal memuat detail wuku: $err')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimetableTab(Map<String, dynamic> dayData, ScrollController scrollController) {
    final dateStr = dayData['date'] as String;
    final timetable = dayData['timetable'] as Map<String, dynamic>?;
    if (timetable == null) return const SizedBox.shrink();

    final List<dynamic> jamBaik = timetable['jam_baik'] as List<dynamic>? ?? [];
    final List<dynamic> jamNaas = timetable['jam_naas'] as List<dynamic>? ?? [];

    // Sort or merge list of hours for unified display
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

    // Sort by range start hour
    slots.sort((a, b) {
      final rangeA = a['data']['range'] as String;
      final rangeB = b['data']['range'] as String;
      return rangeA.compareTo(rangeB);
    });

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final data = slot['data'];
              final isBaik = slot['type'] == 'baik';
              final range = data['range'] as String;
              final label = data['label'] as String;
              final rec = data['rekomendasi'] as String;

              final taskKey = 'planner_task_${dateStr}_${slot['type']}_${slot['index']}';
              final isChecked = _checklists[taskKey] ?? false;

              final cardColor = isBaik ? const Color(0xFF10B981) : AppTheme.accentPink;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardColor.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox for interactive list
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cardColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      label,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: cardColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rec,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Export Schedule Button
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
          ),
        )
      ],
    );
  }
}
