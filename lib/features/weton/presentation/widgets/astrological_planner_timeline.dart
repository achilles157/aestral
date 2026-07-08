import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/ai/presentation/oracle_chat_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../services/weton_dictionary_service.dart';
import 'circadian_rhythm_wave_painter.dart';
import '../../../auth/services/auth_service.dart';
import '../../../../core/utils/weton_utils.dart';

class AstrologicalPlannerTimeline extends ConsumerStatefulWidget {
  final Map<String, dynamic> dayData;
  final ScrollController scrollController;
  final DateTime? birthDate;

  const AstrologicalPlannerTimeline({
    super.key,
    required this.dayData,
    required this.scrollController,
    this.birthDate,
  });

  @override
  ConsumerState<AstrologicalPlannerTimeline> createState() => _AstrologicalPlannerTimelineState();
}

class _AstrologicalPlannerTimelineState extends ConsumerState<AstrologicalPlannerTimeline> {
  SharedPreferences? _prefs;
  final Map<String, bool> _checklists = {};
  bool _isPrefsLoading = true;

  @override
  void initState() {
    super.initState();
    _initPreferences();
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
        _isPrefsLoading = false;
      });
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
    final dayData = widget.dayData;
    final dateStr = dayData['date'] as String;
    final pancasuda = dayData['pancasuda'] as Map<String, dynamic>;
    final vibeColor = _getPancasudaColor(pancasuda['vibe_warna'] as String);
    final wukuName = dayData['wuku'] as String;
    final timetable = dayData['timetable'] as Map<String, dynamic>?;
    // Dino Was: personal naas day — overrides Pancasuda in planner hierarchy
    final bool isDinoWas = dayData['is_dino_was'] as bool? ?? false;

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

    final wukuListAsync = ref.watch(wukuProvider);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Dino Was warning banner — shown when this day is the user's personal naas day
        if (isDinoWas) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF87171).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF87171).withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DINO WAS — Hari Naas Personal',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF87171),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hari ini adalah hari naas pribadimu. Tunda keputusan penting, hindari konfrontasi, dan prioritaskan restorasi diri.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white60,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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

        _isPrefsLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
            : Stack(
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
                  // Timeline Items — menggunakan Row+CrossAxisAlignment.start
                  // menggantikan IntrinsicHeight untuk menghindari double layout pass
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

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline dot — top-aligned, offset dengan padding agar sejajar header card
                          SizedBox(
                            width: 32,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Align(
                                alignment: isBaik
                                    ? const Alignment(0.5, 0.0)
                                    : const Alignment(-0.5, 0.0),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cardColor,
                                    border: Border.all(
                                      color: AppTheme.accentGold,
                                      width: 1.5,
                                    ),
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
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Card konten
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
                                      data: Theme.of(context).copyWith(
                                        unselectedWidgetColor: Colors.white30,
                                      ),
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
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: cardColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
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
                                            onPressed: () async {
                                              final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
                                              final birthDate = widget.birthDate;
                                              final WetonInfo? birthWeton = birthDate != null
                                                  ? WetonUtils.calculateWeton(birthDate)
                                                  : null;
                                              final birthWetonName = birthWeton != null
                                                  ? '${birthWeton.saptawara} ${birthWeton.pancawara}'
                                                  : (dayData['weton_hari_ini'] ?? 'Minggu Legi');
                                              final neptuVal = birthWeton != null
                                                  ? birthWeton.totalNeptu
                                                  : (dayData['neptu'] ?? 10);
                                              final karakterVal = birthWeton?.characterSummary ?? '';
                                              final pangarasanVal = birthWeton?.pangarasan ?? '';

                                              // Elemen weton berdasarkan saptawara (Naga Dina)
                                              const saptawaraElemenMap = {
                                                'Ahad': 'Api', 'Minggu': 'Api',
                                                'Senin': 'Air',
                                                'Selasa': 'Api',
                                                'Rabu': 'Tanah',
                                                'Kamis': 'Kayu',
                                                'Jumat': 'Air',
                                                'Sabtu': 'Tanah',
                                              };
                                              final wetonElemen = birthWeton != null
                                                  ? (saptawaraElemenMap[birthWeton.saptawara] ?? '')
                                                  : '';

                                              if (!context.mounted) return;
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => OracleChatScreen(
                                                    oracleType: 'weton',
                                                    authHeader: authHeader,
                                                    aiContext: {
                                                      'wetonLahir': {
                                                        'nama': birthWetonName,
                                                        'neptu': neptuVal,
                                                        'elemen': wetonElemen,
                                                        if (karakterVal.isNotEmpty) 'karakter': karakterVal,
                                                      },
                                                      'wukuBerjalan': {
                                                        'nama': dayData['wuku'] ?? '',
                                                        'elemen': dayData['wuku_elemen'] ?? '',
                                                      },
                                                      if (pangarasanVal.isNotEmpty) 'pangarasan': pangarasanVal,
                                                      'plannerHour': {
                                                        'label': label,
                                                        'range': range,
                                                      }
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: cardColor.withValues(alpha: 0.5),
                                                width: 1.0,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: Icon(
                                              Icons.auto_awesome,
                                              size: 12,
                                              color: cardColor,
                                            ),
                                            label: Text(
                                              '✨ Tanya AI Orakel',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: cardColor,
                                                fontWeight: FontWeight.bold,
                                              ),
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
  }
}
