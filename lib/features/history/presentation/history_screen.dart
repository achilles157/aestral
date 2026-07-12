import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/shell_providers.dart';
import '../../../core/widgets/cosmic_loader.dart';
import '../../../core/services/analytics_service.dart';
import '../models/reading_entry.dart';
import '../services/reading_history_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<ReadingEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    AnalyticsService.logHistoryViewed().catchError((_) {});
    final entries = await ReadingHistoryService.load();
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Riwayat',
            style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16)),
        content: Text('Semua riwayat kosmis akan dihapus permanen.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ReadingHistoryService.clear();
      if (mounted) setState(() => _entries = []);
    }
  }

  void _navigateTo(String type) {
    final tabIndex = switch (type) {
      'weton' => 2,
      'bazi' => 4,
      'tarot' => 1,
      _ => 0,
    };
    Navigator.of(context).pop();
    ref.read(activeTabProvider.notifier).setTab(tabIndex);
  }

  // ── Group entries by date label ──────────────────────────────────────────────

  Map<String, List<ReadingEntry>> _grouped() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final grouped = <String, List<ReadingEntry>>{};
    for (final e in _entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(e.timestamp);
      final label = dateKey == today
          ? 'Hari Ini'
          : dateKey == yesterday
              ? 'Kemarin'
              : DateFormat('d MMMM yyyy', 'id_ID').format(e.timestamp);
      grouped.putIfAbsent(label, () => []).add(e);
    }
    return grouped;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Kosmis',
          style: GoogleFonts.cinzel(
            color: AppTheme.accentGold,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white38, size: 20),
              onPressed: _clearAll,
              tooltip: 'Hapus semua',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0D2E)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CosmicLoader())
            : _entries.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome,
              color: AppTheme.accentGold.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            'Belum ada jejak kosmis',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white38,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai bacaan Weton, Ba Zi, atau Tarot\nuntuk mencatat perjalananmu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white24,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped();
    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: sections.length,
      itemBuilder: (ctx, i) {
        final section = sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10),
              child: Text(
                section.key,
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...section.value.map((entry) => _EntryTile(
                  entry: entry,
                  onTap: () => _navigateTo(entry.type),
                )),
          ],
        );
      },
    );
  }
}

// ── Entry Tile ────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  final ReadingEntry entry;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, required this.onTap});

  IconData get _icon => switch (entry.type) {
        'weton' => Icons.brightness_medium_rounded,
        'bazi' => Icons.grid_4x4_rounded,
        'tarot' => Icons.auto_awesome,
        _ => Icons.stars_rounded,
      };

  String get _timeLabel {
    final now = DateTime.now();
    final diff = now.difference(entry.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('HH:mm').format(entry.timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(entry.accentColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: accent, width: 3),
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06), width: 1),
                  right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06), width: 1),
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(_icon, color: accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.subtitle,
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeLabel,
                        style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.chevron_right_rounded,
                          color: accent.withValues(alpha: 0.5), size: 16),
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
