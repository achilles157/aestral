import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

/// Data satu wuku dari JSON.
class WukuItem {
  final int id;
  final String namaWuku;
  final String dewaPenaung;
  final String arketipeModern;
  final String karakterDasar;
  final String pesanKesadaran;

  const WukuItem({
    required this.id,
    required this.namaWuku,
    required this.dewaPenaung,
    required this.arketipeModern,
    required this.karakterDasar,
    required this.pesanKesadaran,
  });

  factory WukuItem.fromJson(Map<String, dynamic> json) => WukuItem(
    id: json['id'] as int,
    namaWuku: json['nama_wuku'] as String,
    dewaPenaung: json['dewa_penaung'] as String,
    arketipeModern: json['arketipe_modern'] as String,
    karakterDasar: json['karakter_dasar'] as String,
    pesanKesadaran: json['pesan_kesadaran'] as String,
  );
}

/// Bottom sheet glosarium 30 Wuku — dari Sinta hingga Watugunung.
/// Data dari `assets/weton/wuku.json` (offline, zero API).
class WukuGlossarySheet extends StatefulWidget {
  const WukuGlossarySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WukuGlossarySheet(),
    );
  }

  @override
  State<WukuGlossarySheet> createState() => _WukuGlossarySheetState();
}

class _WukuGlossarySheetState extends State<WukuGlossarySheet> {
  List<WukuItem>? _wukuList;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/weton/wuku.json');
      final list = (json.decode(raw) as List)
          .map((j) => WukuItem.fromJson(j as Map<String, dynamic>))
          .toList();
      if (mounted)
        setState(() {
          _wukuList = list;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            // Drag handle
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
              '30 Wuku',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              )
            else if (_wukuList == null)
              Text(
                'Gagal memuat data Wuku.',
                style: GoogleFonts.outfit(color: AppTheme.textMuted),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _wukuList!.length,
                  itemBuilder: (_, i) => _WukuEntry(item: _wukuList![i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WukuEntry extends StatelessWidget {
  final WukuItem item;
  const _WukuEntry({required this.item});

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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleFadeGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.id}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaWuku,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        item.dewaPenaung,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.arketipeModern,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppTheme.accentPurple.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.karakterDasar,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.pesanKesadaran,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.accentGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
