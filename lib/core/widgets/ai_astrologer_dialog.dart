import 'dart:math' show min;

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        // Batasi tinggi maksimal 80% layar agar tidak overflow di respons panjang
        constraints: BoxConstraints(maxHeight: screenHeight * 0.80),
        child: GlassCard(
          borderRadius: 24,
          borderColor: AppTheme.accentGold.withValues(alpha: 0.35),
          borderWidth: 1.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header — fixed
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.accentGold, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✦ ORAKEL KOSMIS',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2E2452), height: 24, thickness: 1),
              
              // Scrollable area for prompt + loading/response
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textLight.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thinking State
                      if (_isThinking)
                        Semantics(
                          label: 'Orakel sedang memproses jawaban, mohon tunggu',
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExcludeSemantics(child: _ShimmerLine(width: double.infinity, height: 14)),
                                const SizedBox(height: 10),
                                ExcludeSemantics(child: _ShimmerLine(width: double.infinity, height: 14)),
                                const SizedBox(height: 10),
                                ExcludeSemantics(
                                  child: Builder(builder: (context) {
                                    final w = MediaQuery.of(context).size.width * 0.55;
                                    return _ShimmerLine(width: min(w, 240), height: 14);
                                  }),
                                ),
                                const SizedBox(height: 20),
                                const Center(
                                  child: Text(
                                    'Menghubungkan dengan vibrasi kosmis...',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // Response text
                        Semantics(
                          label: _isOffline
                              ? 'Respons orakel (mode offline): $_aiResponse'
                              : 'Respons orakel: $_aiResponse',
                          liveRegion: true,
                          child: Text(
                            _aiResponse,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              height: 1.6,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                        // Offline indicator
                        if (_isOffline) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Mode offline aktif — respons kosmis terbatas',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off, color: Colors.orange, size: 13),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mode Offline — respons kosmis terbatas',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Close button — fixed at bottom
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
      ),
    );
  }
}

// ── Shimmer skeleton line ──────────────────────────────────────────────────────

/// Animated shimmer placeholder line untuk loading state AI response.
/// Tidak butuh package eksternal — murni AnimationController + LinearGradient.
class _ShimmerLine extends StatefulWidget {
  const _ShimmerLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _anim = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Saat reduceMotion aktif, tampilkan static placeholder tanpa shimmer
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withValues(alpha: 0.07),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final v = _anim.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (v - 0.4).clamp(0.0, 1.0),
                v.clamp(0.0, 1.0),
                (v + 0.4).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
        );
      },
    );
  }
}
