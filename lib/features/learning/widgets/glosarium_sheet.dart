import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../models/glosarium_item.dart';

/// Bottom sheet glosarium istilah astrologi — searchable + filter per domain.
/// Data dari `assets/glosarium.json` (offline, zero API).
class GlosariumSheet extends StatefulWidget {
  const GlosariumSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlosariumSheet(),
    );
  }

  @override
  State<GlosariumSheet> createState() => _GlosariumSheetState();
}

const _domainLabels = <String, String>{
  'weton': 'Weton',
  'bazi': 'Ba Zi',
  'tarot': 'Tarot',
  'mangsa': 'Mangsa & Wuku',
};

class _GlosariumSheetState extends State<GlosariumSheet> {
  List<GlosariumItem>? _items;
  bool _loading = true;
  String _query = '';
  String? _domain; // null = semua

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/glosarium.json');
      final list = (json.decode(raw) as List)
          .map((j) => GlosariumItem.fromJson(j as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<GlosariumItem> get _filtered {
    final items = _items ?? const <GlosariumItem>[];
    final q = _query.trim().toLowerCase();
    return items.where((it) {
      final matchesDomain = _domain == null || it.domain == _domain;
      final matchesQuery = q.isEmpty ||
          it.istilah.toLowerCase().contains(q) ||
          it.definisi.toLowerCase().contains(q) ||
          it.alias.any((a) => a.toLowerCase().contains(q));
      return matchesDomain && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Glosarium Astrologi',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 10),
            _buildSearchField(),
            const SizedBox(height: 8),
            _buildDomainChips(),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              )
            else if (_items == null)
              Text(
                'Gagal memuat data glosarium.',
                style: GoogleFonts.outfit(color: AppTheme.textMuted),
              )
            else
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada istilah yang cocok.',
                          style: GoogleFonts.outfit(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _GlosariumEntry(item: _filtered[i]),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Cari istilah…',
        hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDomainChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _domainChip(null, 'Semua'),
          for (final entry in _domainLabels.entries)
            _domainChip(entry.key, entry.value),
        ],
      ),
    );
  }

  Widget _domainChip(String? domain, String label) {
    final selected = _domain == domain;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _domain = domain),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: AppTheme.accentPurple.withValues(alpha: 0.35),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          color: selected ? AppTheme.textLight : AppTheme.textMuted,
        ),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _GlosariumEntry extends StatelessWidget {
  final GlosariumItem item;
  const _GlosariumEntry({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.istilah,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _domainLabels[item.domain] ?? item.domain,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.definisi,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
            if (item.contoh.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Contoh: ${item.contoh}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppTheme.accentGold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
