import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/pranata_mangsa.dart';

class SeasonalBanner extends StatelessWidget {
  final PranataMangsaModel mangsa;

  const SeasonalBanner({
    super.key,
    required this.mangsa,
  });

  LinearGradient _getGradientForMangsa(int id) {
    switch (id) {
      case 1: // Kasa - Ego-Death & Decluttering
        return const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2: // Karo - Resilience
        return const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF9A3412), Color(0xFF451A03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3: // Katiga - Disiplin
        return const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF022C22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 4: // Kapat - Emotional Healing
        return const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFF831843), Color(0xFF3B0764)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 5: // Kalima - Abundance
        return const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF854D0E), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 6: // Kanem - Flow
        return const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF172554)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 7: // Kapitu - Cozy Boundaries
        return const LinearGradient(
          colors: [Color(0xFF581C87), Color(0xFF6B21A8), Color(0xFF3B0764)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 8: // Kawolu - Passion & Collaboration
        return const LinearGradient(
          colors: [Color(0xFF701A75), Color(0xFF86198F), Color(0xFF4A044E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 9: // Kasanga - Sharing
        return const LinearGradient(
          colors: [Color(0xFF134E5E), Color(0xFF0F9B0F), Color(0xFF0F2027)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 10: // Kasepuluh - Security
        return const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 11: // Dhesta - Apresiasi
        return const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFF9A3412), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 12: // Sada - Detachment & Refleksi
        return const LinearGradient(
          colors: [Color(0xFF03001E), Color(0xFF7303C0), Color(0xFFEC38BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [AppTheme.cardBg, Color(0xFF140D33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _getGradientForMangsa(mangsa.id),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background patterns
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: 150,
                  color: AppTheme.accentGold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.park, color: AppTheme.accentGold, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'PRANATA MANGSA',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        mangsa.tanggalSiklus,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mangsa ${mangsa.namaMangsa} (${mangsa.namaLain})',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mangsa.arketipeModern,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '“${mangsa.candraMangsa}”',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textLight.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Karakter Musim & Energi:',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mangsa.karakterEnergi,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textLight.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Expansion Tile for deeper seasonal horoscopes
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        'Lihat Ramalan Karir, Asmara & Saran Aktivitas',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      iconColor: AppTheme.accentGold,
                      collapsedIconColor: AppTheme.accentGold,
                      tilePadding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 8),
                        _buildSubInsight(
                          title: 'Ramalan Karir & Finansial',
                          content: mangsa.ramalanKarier,
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildSubInsight(
                          title: 'Ramalan Asmara & Hubungan',
                          content: mangsa.ramalanAsmara,
                          icon: Icons.favorite_border,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Saran Aktivitas Penyelarasan Energi:',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: mangsa.saranAktivitas
                              .map((activity) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: AppTheme.accentGold)),
                                        Expanded(
                                          child: Text(
                                            activity,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: AppTheme.textLight.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, color: AppTheme.accentGold, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mangsa.pesanKesadaran,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textLight.withValues(alpha: 0.9),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubInsight({required String title, required String content, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.accentGold, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
