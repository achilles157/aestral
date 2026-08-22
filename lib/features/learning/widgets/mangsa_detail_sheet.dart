import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../weton/domain/pranata_mangsa.dart';

/// Bottom sheet detail per Pranata Mangsa — tampilkan dari [KnowledgeHubScreen].
class MangsaDetailSheet extends StatelessWidget {
  final PranataMangsaModel mangsa;

  const MangsaDetailSheet({super.key, required this.mangsa});

  static Future<void> show(BuildContext context, PranataMangsaModel mangsa) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangsaDetailSheet(mangsa: mangsa),
    );
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
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldToPurpleGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${mangsa.id}',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mangsa ${mangsa.namaMangsa}',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                mangsa.tanggalSiklus,
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

                    const SizedBox(height: 16),

                    // Core info cards
                    _buildInfoRow('Candra', mangsa.candraMangsa),
                    _buildInfoRow('Arketipe', mangsa.arketipeModern),
                    _buildInfoRow('Tanda Alam', mangsa.tandaAlam),
                    _buildInfoRow('Karakter Energi', mangsa.karakterEnergi),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),

                    // Life insights
                    const SizedBox(height: 8),
                    _buildSection('Karier', mangsa.ramalanKarier),
                    _buildSection('Asmara', mangsa.ramalanAsmara),
                    _buildSection('Pesan Kesadaran', mangsa.pesanKesadaran),

                    const SizedBox(height: 8),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),

                    _buildSection(
                      'Saran Aktivitas',
                      mangsa.saranAktivitas.map((s) => '• $s').join('\n'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentGold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body.isNotEmpty ? body : '—',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
