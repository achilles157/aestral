import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class AiAstrologerDialog extends StatefulWidget {
  final String prompt;
  final String contextTitle;

  const AiAstrologerDialog({
    super.key,
    required this.prompt,
    required this.contextTitle,
  });

  @override
  State<AiAstrologerDialog> createState() => _AiAstrologerDialogState();
}

class _AiAstrologerDialogState extends State<AiAstrologerDialog> {
  bool _isThinking = true;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    _generateResponse();
  }

  void _generateResponse() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final title = widget.contextTitle;
    String response = '';

    if (title.contains('Jam') || widget.prompt.toLowerCase().contains('jam') || widget.prompt.toLowerCase().contains('saat pitu')) {
      response = "Energi pada waktu ini ($title) memiliki pengaruh kuat terhadap fokus dan getaran mental Anda.\n\n"
          "Secara astrologi Jawa, perputaran jam ini membawa aliran spiritual yang memengaruhi keputusan impulsif. "
          "Saran saya: hadapi jam ini dengan kesadaran penuh. Tarik napas dalam-dalam sebelum mulai berbicara atau mengambil keputusan penting. "
          "Gunakan vibrasi kosmis saat ini untuk menata kembali niat terdalam Anda.";
    } else {
      response = "Misteri batin Anda terungkap melalui weton $title.\n\n"
          "Sebagai seorang $title, Anda diberkahi dengan kekuatan spiritual alami yang kuat, namun ada 'sisi bayang' (ego death) yang sering menuntut pelepasan hal-toxic.\n\n"
          "Keseimbangan energi Anda saat ini menunjukkan perlunya menjaga batasan diri agar tidak rentan dimanfaatkan orang lain. "
          "Dengarkan intuisi terdalam Anda hari ini, karena suara itu adalah pembimbing kosmis yang paling murni.";
    }

    setState(() {
      _isThinking = false;
      _aiResponse = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        borderRadius: 24,
        borderColor: AppTheme.accentGold.withValues(alpha: 0.35),
        borderWidth: 1.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'KONSULTASI AI ASTROLOG',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2E2452), height: 32, thickness: 1),
            // User prompt box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      widget.prompt,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textLight.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // AI Response
            if (_isThinking)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.accentGold),
                      SizedBox(height: 12),
                      Text(
                        'Menghubungkan dengan vibrasi kosmis...',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    _aiResponse,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.6,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Action button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Tutup Portal'),
            ),
          ],
        ),
      ),
    );
  }
}
