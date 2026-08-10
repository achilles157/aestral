import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../weton/data/pranata_mangsa_repository.dart';
import '../weton/domain/pranata_mangsa.dart';
import 'widgets/mangsa_detail_sheet.dart';
import 'widgets/wuku_glossary_sheet.dart';

/// Knowledge Hub — edukasi Pranata Mangsa & Wuku.
/// Konten 100% offline dari `assets/` JSON — zero API cost.
/// Membedakan Aestral dari kompetitor: bukan sekadar tampilkan data,
/// tetapi edukasi tradisi + rajut narasi.
class KnowledgeHubScreen extends ConsumerWidget {
  const KnowledgeHubScreen({super.key});

  static const String route = '/knowledge-hub';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangsaAsync = ref.watch(pranataMangsaListProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: mangsaAsync.when(
                  data: (mangsaList) => _buildContent(context, ref, mangsaList),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Gagal memuat data.',
                      style: GoogleFonts.outfit(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pustaka Kosmis',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pahami ritme alam & warisan leluhur',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<PranataMangsaModel> mangsaList,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pranata Mangsa ──────────────────────────────────────────
          _buildSectionTitle('12 Pranata Mangsa', 'Kalender musim Jawa'),
          const SizedBox(height: 10),
          ...mangsaList.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MangsaTile(
                mangsa: m,
                onTap: () => MangsaDetailSheet.show(context, m),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Wuku ────────────────────────────────────────────────────
          _buildSectionTitle(
            '30 Wuku',
            'Siklus 7-harian dalam penanggalan Jawa-Bali',
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => WukuGlossarySheet.show(context),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleFadeGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      color: AppTheme.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Glosarium 30 Wuku',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Dari Sinta hingga Watugunung — kenali arketipe,'
                          ' dewa penaung, dan pesan kesadaran tiap wuku.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Istilah ─────────────────────────────────────────────────
          _buildSectionTitle('Istilah Kunci', 'Neptu, Pasaran & lainnya'),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildGlossaryEntry(
                  'Neptu',
                  'Jumlah nilai hari (Saptawara + Pancawara).'
                      ' Digunakan untuk kalkulasi kecocokan weton,'
                      ' hari baik, dan pancasuda.',
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildGlossaryEntry(
                  'Pasaran',
                  'Siklus 5-hari Jawa: Kliwon, Legi, Pahing, Pon, Wage.'
                      ' Masing-masing punya nilai neptu dan karakter energi.',
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildGlossaryEntry(
                  'Pancasuda',
                  'Sisa pembagian Neptu Weton ÷ 5. Menentukan'
                      ' label arah energi: Sri (rejeki), Lungguh'
                      ' (kehormatan), Gedhong (kekayaan), Lara'
                      ' (rintangan), Pati (transformasi).',
                ),
                const Divider(color: Colors.white10, height: 20),
                _buildGlossaryEntry(
                  'Da Yun (大运)',
                  'Siklus 10-tahunan dalam Ba Zi — pilar'
                      ' keberuntungan yang bergeser tiap dekade,'
                      ' menentukan tema dominan fase hidup.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLight,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlossaryEntry(String term, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            term,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentGold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tile per Pranata Mangsa di list.
class _MangsaTile extends StatelessWidget {
  final PranataMangsaModel mangsa;
  final VoidCallback onTap;

  const _MangsaTile({required this.mangsa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.goldToPurpleGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${mangsa.id}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mangsa ${mangsa.namaMangsa}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mangsa.arketipeModern,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
