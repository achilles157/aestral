import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/birth_profile_provider.dart';
import '../../../ai/presentation/oracle_chat_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../tarot/services/tarot_data.dart';
import '../../../../core/widgets/cosmic_auth_bottom_sheet.dart';

/// Card "Sesepuh Kosmis" — Grand Reading synthesis dari Weton + Tarot.
/// Tombol aktif hanya ketika user punya profil lahir DAN sudah menarik Tarot.
class DashboardSesepuhCard extends ConsumerWidget {
  final bool hasProfile;

  const DashboardSesepuhCard({super.key, required this.hasProfile});

  static const Color _accent = Color(0xFF5C6BC0); // Deep Indigo

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarotDrawn = ref.read(drawnCardProvider)?.isNotEmpty ?? false;
    final canOpen    = hasProfile && tarotDrawn;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: hasProfile ? _accent.withValues(alpha: 0.45) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          if (hasProfile)
            BoxShadow(
              color: _accent.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: hasProfile ? _accent : AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Sesepuh Kosmis',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasProfile ? Colors.white : AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasProfile
                      ? _accent.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasProfile
                        ? _accent.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Text(
                  'Grand Reading',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasProfile ? _accent : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasProfile
                ? 'Hubungkan getaran Weton Jawa, arketipe Ba Zi, dan tebaran Tarot dalam satu pembacaan kosmis terintegrasi.'
                : 'Lengkapi profil kelahiran Anda untuk membuka Orakel Sintesis Sesepuh Kosmis.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              height: 1.45,
              color: hasProfile ? Colors.white70 : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canOpen
                  ? () async {
                      final authState = ref.read(authProvider);
                      final isGuest = authState == null || authState.isMock;
                      if (isGuest) {
                        CosmicAuthBottomSheet.show(
                          context,
                          message: 'Orakel Sintesis Sesepuh Kosmis mengintegrasikan seluruh sistem nasib Anda. Masuk sekarang untuk membuka Grand Reading.',
                        );
                        return;
                      }

                      final authHeader =
                          await ref.read(authProvider.notifier).getAuthHeader();
                      if (!context.mounted) return;

                      final weton =
                          ref.read(birthProfileProvider).value?.weton;
                      final drawnCards = ref.read(drawnCardProvider);

                      final synthesisContext = <String, dynamic>{
                        if (weton != null)
                          'wetonLahir': {
                            'nama':
                                '${weton.saptawara} ${weton.pancawara}',
                            'neptu': weton.totalNeptu,
                            'elemen': '',
                            'karakter': weton.characterSummary,
                          },
                        if (weton != null && weton.pangarasan.isNotEmpty)
                          'pangarasan': weton.pangarasan,
                        if (drawnCards != null && drawnCards.isNotEmpty)
                          'tarotCards': drawnCards
                              .map((c) => {
                                    'name': c.card.nameId,
                                    'label': c.label,
                                    'isReversed': c.isReversed,
                                    'archetype': c.card.archetypeId,
                                    'element': c.card.elementalId,
                                    'aiHook': c.card.aiHookId,
                                    'keywords': c.card.keywordsId,
                                  })
                              .toList(),
                      };

                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OracleChatScreen(
                            oracleType: 'synthesis',
                            authHeader: authHeader,
                            aiContext: synthesisContext.isEmpty
                                ? null
                                : synthesisContext,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canOpen ? _accent.withValues(alpha: 0.3) : Colors.white10,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: canOpen ? _accent : Colors.transparent,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                hasProfile
                    ? 'Mulai Dialog Sintesis'
                    : 'Lengkapi 2 dari 3 sistem untuk membuka Grand Reading',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
