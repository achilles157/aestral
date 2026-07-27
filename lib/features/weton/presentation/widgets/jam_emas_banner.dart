import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

/// Internal data model for a single Jam Emas slot.
class _JamEmasSlot {
  final DateTime date;
  final String range;
  final String label;
  final String? zodiac;
  final String? condition;
  final bool isToday;
  final int score;

  const _JamEmasSlot({
    required this.date,
    required this.range,
    required this.label,
    this.zodiac,
    this.condition,
    required this.isToday,
    required this.score,
  });
}

/// Banner horizontal-scroll "3 Jam Emas Terdekat" untuk Astrological Planner.
///
/// Menampilkan top 3 slot Saat Rezeki/Gedhong terdekat dari hari ini ke depan.
/// Menggunakan data [calendarDays] dari _calendarData['days'] yang sudah di-fetch —
/// tanpa API call tambahan.
///
/// Scoring priority:
///   Rezeki + Yong Shen → 4 (double gold)
///   Rezeki + Harmoni   → 3 (gold)
///   Rezeki             → 2 (standard gold)
///   Gedhong            → 1 (silver fallback)
class JamEmasBanner extends StatelessWidget {
  final List<Map<String, dynamic>> calendarDays;
  final DateTime today;
  final void Function(DateTime date)? onDateTapped;

  const JamEmasBanner({
    super.key,
    required this.calendarDays,
    required this.today,
    this.onDateTapped,
  });

  int _slotScore(Map<String, dynamic> slot) {
    final label = slot['label'] as String? ?? '';
    final baziShi = slot['bazi_shi_chen'] as Map<String, dynamic>?;
    final condition = baziShi?['condition'] as String? ?? 'Netral';

    if (label == 'Saat Rezeki') {
      if (condition == 'Yong Shen') return 4;
      if (condition == 'Harmoni') return 3;
      return 2;
    }
    if (label == 'Saat Gedhong') return 1;
    return 0;
  }

  /// Returns true if the slot's end time has passed today.
  bool _isSlotPast(String range, DateTime slotDate, DateTime now) {
    final isToday =
        slotDate.year == now.year &&
        slotDate.month == now.month &&
        slotDate.day == now.day;
    if (!isToday) return false;

    final parts = range.split(' - ');
    if (parts.length < 2) return false;
    final endParts = parts[1].trim().split(':');
    if (endParts.length < 2) return false;

    final endHour = int.tryParse(endParts[0]) ?? 23;
    final endMin = int.tryParse(endParts[1]) ?? 59;

    // Detect midnight-crossing slot (end hour < start hour)
    final startParts = parts[0].trim().split(':');
    final startHour = int.tryParse(startParts[0]) ?? 0;
    if (endHour < startHour) return false; // Crosses midnight, not "past"

    final endTime = DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      endHour,
      endMin,
    );
    return now.isAfter(endTime);
  }

  List<_JamEmasSlot> _extractJamEmas() {
    final candidates = <_JamEmasSlot>[];
    final fmt = DateFormat('yyyy-MM-dd');
    final todayNormalized = DateTime(today.year, today.month, today.day);

    for (final dayData in calendarDays) {
      final dateStr = dayData['date'] as String?;
      if (dateStr == null) continue;

      DateTime dayDate;
      try {
        dayDate = fmt.parse(dateStr);
      } catch (_) {
        continue;
      }

      final diff = dayDate.difference(todayNormalized).inDays;
      if (diff < 0 || diff > 14) continue; // Only today + 14 days ahead

      final timetable = dayData['timetable'] as Map<String, dynamic>?;
      if (timetable == null) continue;

      final jamBaik = timetable['jam_baik'] as List<dynamic>? ?? [];
      final isToday = diff == 0;

      for (final slot in jamBaik) {
        final slotMap = slot as Map<String, dynamic>;
        final label = slotMap['label'] as String? ?? '';
        if (label != 'Saat Rezeki' && label != 'Saat Gedhong') continue;

        final range = slotMap['range'] as String? ?? '';
        if (_isSlotPast(range, dayDate, today)) continue;

        final baziShi = slotMap['bazi_shi_chen'] as Map<String, dynamic>?;
        candidates.add(
          _JamEmasSlot(
            date: dayDate,
            range: range,
            label: label,
            zodiac: baziShi?['zodiac'] as String?,
            condition: baziShi?['condition'] as String?,
            isToday: isToday,
            score: _slotScore(slotMap),
          ),
        );
      }
    }

    // Sort: score DESC → date ASC → range ASC (lexicographic works for HH:MM)
    candidates.sort((a, b) {
      final sd = b.score.compareTo(a.score);
      if (sd != 0) return sd;
      final dd = a.date.compareTo(b.date);
      if (dd != 0) return dd;
      return a.range.compareTo(b.range);
    });

    return candidates.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final slots = _extractJamEmas();
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '✦ ',
              style: TextStyle(color: AppTheme.accentGold, fontSize: 12),
            ),
            Text(
              'Jam Emas Terdekat',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: slots.asMap().entries.map((entry) {
              final i = entry.key;
              final slot = entry.value;
              return Padding(
                padding: EdgeInsets.only(right: i < slots.length - 1 ? 10 : 0),
                child: _JamEmasChip(
                  slot: slot,
                  onTap: onDateTapped != null
                      ? () => onDateTapped!(slot.date)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _JamEmasChip extends StatelessWidget {
  final _JamEmasSlot slot;
  final VoidCallback? onTap;

  const _JamEmasChip({required this.slot, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRezeki = slot.label == 'Saat Rezeki';
    final isDoubleGold = isRezeki && slot.condition == 'Yong Shen';
    final chipColor = isDoubleGold
        ? AppTheme.accentGold
        : isRezeki
        ? AppTheme.accentGold.withValues(alpha: 0.80)
        : Colors.amber.withValues(alpha: 0.65);

    final dateFmt = DateFormat('EEE, d MMM', 'id');
    final dateLabel = slot.isToday ? 'Hari Ini' : dateFmt.format(slot.date);
    final conditionToShow =
        (slot.condition != null && slot.condition != 'Netral')
        ? slot.condition
        : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 162,
        child: GlassCard(
          borderColor: chipColor.withValues(alpha: slot.isToday ? 0.90 : 0.45),
          borderWidth: slot.isToday ? 1.8 : 1.0,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: chipColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  isDoubleGold ? '✦✦ ${slot.label}' : '✦ ${slot.label}',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Date
              Text(
                dateLabel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.58),
                ),
              ),
              const SizedBox(height: 3),
              // Time range
              Text(
                slot.range,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Ba Zi condition row
              if (slot.zodiac != null || conditionToShow != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (slot.zodiac != null)
                      Flexible(
                        child: Text(
                          slot.zodiac!,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.50),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (slot.zodiac != null && conditionToShow != null)
                      Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    if (conditionToShow != null)
                      Text(
                        conditionToShow,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: conditionToShow == 'Yong Shen'
                              ? AppTheme.accentGold
                              : conditionToShow == 'Harmoni'
                              ? Colors.greenAccent.shade400
                              : Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
