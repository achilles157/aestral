import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'glass_card.dart';
import '../../features/ai/models/chat_message.dart';
import '../../features/ai/services/chat_cache_service.dart';

class AiAstrologerDialog extends StatefulWidget {
  final String prompt;
  final String contextTitle;
  final String authHeader;
  final Map<String, dynamic>? aiContext;

  const AiAstrologerDialog({
    super.key,
    required this.prompt,
    required this.contextTitle,
    required this.authHeader,
    this.aiContext,
  });

  @override
  State<AiAstrologerDialog> createState() => _AiAstrologerDialogState();
}

class _AiAstrologerDialogState extends State<AiAstrologerDialog> {
  bool _isThinking = true;
  String _aiResponse = '';
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _generateResponse();
  }

  Future<void> _generateResponse() async {
    try {
      final result = await ApiService.generateAiChat(
        prompt: widget.prompt,
        authHeader: widget.authHeader,
        aiContext: widget.aiContext,
      );
      if (!mounted) return;

      final responseText =
          result['response'] as String? ?? _getFallbackResponse();

      // Cache the response locally — errors are swallowed intentionally
      ChatCacheService.saveMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: widget.prompt,
        response: responseText,
        timestamp: DateTime.now(),
        contextTitle: widget.contextTitle,
      ));

      setState(() {
        _isThinking = false;
        _aiResponse = responseText;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _aiResponse = _getFallbackResponse();
        _isOffline = true;
      });
    }
  }

  /// Respons fallback ketika koneksi ke orakel tidak tersedia.
  String _getFallbackResponse() {
    final title = widget.contextTitle;
    if (title.contains('Jam') ||
        widget.prompt.toLowerCase().contains('jam') ||
        widget.prompt.toLowerCase().contains('saat pitu')) {
      return 'Energi pada waktu ini ($title) memiliki pengaruh kuat terhadap fokus dan getaran mental Anda.\n\n'
          'Secara astrologi Jawa, perputaran jam ini membawa aliran spiritual yang memengaruhi keputusan impulsif. '
          'Saran saya: hadapi jam ini dengan kesadaran penuh. Tarik napas dalam-dalam sebelum mulai berbicara atau mengambil keputusan penting. '
          'Gunakan vibrasi kosmis saat ini untuk menata kembali niat terdalam Anda.';
    }
    return 'Misteri batin Anda terungkap melalui weton $title.\n\n'
        'Sebagai seorang $title, Anda diberkahi dengan kekuatan spiritual alami yang kuat, '
        'namun ada \'sisi bayang\' (ego death) yang sering menuntut pelepasan hal-toxic.\n\n'
        'Keseimbangan energi Anda saat ini menunjukkan perlunya menjaga batasan diri agar tidak rentan dimanfaatkan orang lain. '
        'Dengarkan intuisi terdalam Anda hari ini, karena suara itu adalah pembimbing kosmis yang paling murni.';
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
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppTheme.accentGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'TANYAKAN KEBINGUNGAN ANDA',
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
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
            // AI Response area
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
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
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
              // Offline indicator
              if (_isOffline) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off,
                          color: Colors.orange, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Mode Offline — respons kosmis terbatas',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            // Close button
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
