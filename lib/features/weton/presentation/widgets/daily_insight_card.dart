import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../components/weton_detail_card.dart';

class DailyInsightCard extends StatelessWidget {
  final Map<String, dynamic> sisaBagi;
  final Map<String, dynamic> wuku;

  const DailyInsightCard({
    super.key,
    required this.sisaBagi,
    required this.wuku,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String fase = sisaBagi['nama_fase'] ?? '';
    final String tingkatEnergi = sisaBagi['tingkat_energi'] ?? '';
    final String interpretasi = sisaBagi['interpretasi_harian'] ?? '';
    final List<dynamic> saran = sisaBagi['saran_aktivitas'] ?? [];

    final String namaWuku = wuku['nama_wuku'] ?? '';
    final String arketipe = wuku['arketipe_modern'] ?? '';
    final String dewa = wuku['dewa_penaung'] ?? '';
    final String karakter = wuku['karakter_dasar'] ?? '';
    final String pesan = wuku['pesan_kesadaran'] ?? '';

    Color energyColor = AppTheme.accentGold;
    if (tingkatEnergi.toLowerCase().contains('waspada')) {
      energyColor = const Color(0xFFF87171);
    } else if (tingkatEnergi.toLowerCase().contains('stabil')) {
      energyColor = const Color(0xFF60A5FA);
    }

    return GlassCard(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      borderColor: energyColor.withValues(alpha: 0.3),
      borderWidth: 1.2,
      borderRadius: 24,
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          energyColor.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.01),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: energyColor.withValues(alpha: 0.1),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ],
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Javanese Mandala Watermark
          Positioned(
            right: -25,
            bottom: -25,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(120, 120),
                painter: WatermarkMandalaPainter(color: energyColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: AppTheme.accentGold, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'DAILY INSIGHT & PAWUKON',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2E2452), height: 30, thickness: 1.5),
                
                // Phase & Energy Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fase: $fase',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: energyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: energyColor.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        'Energi: $tingkatEnergi',
                        style: textTheme.bodyMedium?.copyWith(
                          color: energyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  interpretasi,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: AppTheme.textLight.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Action Suggestions Title
                Text(
                  'REKOMENDASI AKTIVITAS HARI INI',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.accentPink,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                ...saran.map((activity) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.accentPink, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.toString(),
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const Divider(color: Color(0xFF2E2452), height: 40, thickness: 1.5),
                
                // Wuku Influence
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.accentPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PENGARUH WUKU MINGGUAN',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.accentPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Wuku $namaWuku — $arketipe',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dinaungi oleh $dewa',
                  style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  karakter,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pesan Kesadaran Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesan Kesadaran:',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pesan,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
