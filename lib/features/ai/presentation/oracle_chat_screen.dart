import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../providers/oracle_chat_provider.dart';
import '../models/chat_message.dart';
import '../../tarot/services/tarot_data.dart';
import 'oracle_card_widgets.dart';

/// Layar obrolan kosmis utama — mitra dialog spiritual Aestral Oracle.
/// Mendukung 4 persona: weton (Ki Sabdo), bazi (Suhu Wang), tarot (Madame Sophia), synthesis (Sesepuh Kosmis).
class OracleChatScreen extends ConsumerStatefulWidget {
  final String oracleType;

  /// [authHeader] token autentikasi — 'Bearer <token>' atau 'Guest <uid>'.
  final String authHeader;

  /// [aiContext] berisi data astrologi user untuk di-inject ke system prompt oracle.
  final Map<String, dynamic>? aiContext;

  const OracleChatScreen({
    super.key,
    required this.oracleType,
    required this.authHeader,
    this.aiContext,
  });

  @override
  ConsumerState<OracleChatScreen> createState() => _OracleChatScreenState();
}

class _OracleChatScreenState extends ConsumerState<OracleChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final AnimationController _glowCtrl;
  late final OracleConfig _config;

  // Cross-oracle suggestion prompt after session
  bool _showSesepuhHint = false;

  @override
  void initState() {
    super.initState();
    _config = kOracleConfigs[widget.oracleType] ?? kOracleConfigs['weton']!;

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Initialize provider state from local storage
    Future.microtask(() {
      ref.read(oracleChatProvider(widget.oracleType).notifier).initialize(aiContext: widget.aiContext);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    FocusScope.of(context).unfocus();

    await ref.read(oracleChatProvider(widget.oracleType).notifier).sendMessage(
          prompt: text.trim(),
          authHeader: widget.authHeader,
          context: widget.aiContext,
        );
    _scrollToBottom();

    // Show sesepuh hint after 3 messages if oracle type is specialist
    final msgs = ref.read(oracleChatProvider(widget.oracleType)).messages;
    if (msgs.length >= 6 && widget.oracleType != 'synthesis') {
      setState(() => _showSesepuhHint = true);
    }
  }

  Color get _accentColor => Color(_config.accentColor);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oracleChatProvider(widget.oracleType));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Auto-scroll only when a new message is added
    ref.listen<OracleChatState>(
      oracleChatProvider(widget.oracleType),
      (prev, next) {
        if (prev != null && next.messages.length > prev.messages.length) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Background + Ambient Glow ──────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              _config.bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.background),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          // Animated ambient glow dari warna persona oracle
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              final glow = Curves.easeInOut.transform(_glowCtrl.value);
              return Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _accentColor.withValues(alpha: 0.10 + glow * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: state.messages.isEmpty && !state.isLoading
                      ? _buildEmptyState()
                      : _buildMessageList(state),
                ),
                if (_showSesepuhHint && widget.oracleType != 'synthesis')
                  _buildSesepuhHint(),
                _buildSuggestionPills(state),
                _buildInputRow(state, bottomInset, bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: _accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _config.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                      Text(
                        _config.greetingTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF69F0AE),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingMandala(color: _accentColor),
          const SizedBox(height: 20),
          Text(
            'Sentuh sebuah topik\nuntuk memulai dialog',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ────────────────────────────────────────────────────────────

  Widget _buildMessageList(OracleChatState state) {
    final msgs = state.messages;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: msgs.length + (state.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == msgs.length) {
          // Divination loader — mandala pulsing sesuai PRD
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14, right: 48),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                    color: _accentColor.withValues(alpha: 0.20)),
              ),
              child: _PulsingMandala(color: _accentColor),
            ),
          );
        }
        final msg = msgs[i];
        return msg.role == 'user'
            ? _UserBubble(message: msg)
            : _OracleBubble(
                message: msg,
                accentColor: _accentColor,
                oracleName: _config.name,
              );
      },
    );
  }

  // ── Suggestion Pills ────────────────────────────────────────────────────────

  Widget _buildSuggestionPills(OracleChatState state) {
    final pills = state.availablePills;
    if (pills.isEmpty || state.isLoading) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          return _SuggestionPill(
            label: pills[i],
            accentColor: _accentColor,
            onTap: () async {
              await ref
                  .read(oracleChatProvider(widget.oracleType).notifier)
                  .markPillUsed(pills[i]);
              await _send(pills[i]);
            },
          );
        },
      ),
    );
  }

  // ── Sesepuh Hint ────────────────────────────────────────────────────────────

  Widget _buildSesepuhHint() {
    return GestureDetector(
      onTap: () {
        // Build synthesis context from all available data sources
        final weton = ref.read(birthProfileProvider).value?.weton;
        final drawnCards = ref.read(drawnCardProvider);

        final synthesisContext = <String, dynamic>{
          // Merge current oracle's context (may contain weton or bazi data)
          if (widget.aiContext != null) ...widget.aiContext!,
          // Ensure weton is always present if available from profile
          if (weton != null)
            'wetonLahir': {
              'nama': '${weton.saptawara} ${weton.pancawara}',
              'neptu': weton.totalNeptu,
              'elemen': '',
              'karakter': weton.characterSummary,
            },
          if (weton != null && weton.pangarasan.isNotEmpty)
            'pangarasan': weton.pangarasan,
          // Tarot cards from global draw state
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

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OracleChatScreen(
              oracleType: 'synthesis',
              authHeader: widget.authHeader,
              aiContext: synthesisContext.isEmpty ? null : synthesisContext,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5C6BC0).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF5C6BC0).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: Color(0xFF5C6BC0), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ingin melihat gambaran penuhnya? Sesepuh Kosmis menunggu.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.80),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF5C6BC0), size: 18),
          ],
        ),
      ),
    );
  }

  // ── Input Row ───────────────────────────────────────────────────────────────

  Widget _buildInputRow(
      OracleChatState state, double bottomInset, double bottomPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, math.max(bottomInset, bottomPadding) + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: !state.isLoading,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (v) => _send(v),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan keresahanmu...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: state.isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 44,
                          height: 44,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accentColor,
                            ),
                          ),
                        )
                      : GestureDetector(
                          key: const ValueKey('send'),
                          onTap: () => _send(_inputCtrl.text),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withValues(alpha: 0.40),
                                  blurRadius: 12,
                                )
                              ],
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2452).withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.90),
          ),
        ),
      ),
    );
  }
}

class _OracleBubble extends StatelessWidget {
  final ChatMessage message;
  final Color accentColor;
  final String oracleName;

  const _OracleBubble({
    required this.message,
    required this.accentColor,
    required this.oracleName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oracle name label
            Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 2),
              child: Text(
                oracleName,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: accentColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: accentColor.withValues(alpha: 0.22)),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.90),
                ),
              ),
            ),
            // Rich card (opsional)
            if (message.card != null)
              buildOracleCard(message.card!, accentColor),
          ],
        ),
      ),
    );
  }
}

/// Animasi loader mandala berpulsasi — menggantikan CircularProgressIndicator standar.
class _DivinationLoader extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _DivinationLoader({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.33;
                final t = (controller.value + delay) % 1.0;
                final scale = 0.6 + 0.4 * math.sin(t * math.pi);
                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 3, vertical: 4 - (4 * scale - 4).abs()),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6 * scale),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

/// Mandala pulsing untuk empty state.
class _PulsingMandala extends StatefulWidget {
  final Color color;
  const _PulsingMandala({required this.color});

  @override
  State<_PulsingMandala> createState() => _PulsingMandalaState();
}

class _PulsingMandalaState extends State<_PulsingMandala>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.10),
              border:
                  Border.all(color: widget.color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25 * _pulse.value),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome,
                color: widget.color.withValues(alpha: 0.75), size: 32),
          ),
        );
      },
    );
  }
}

/// Tombol kapsul saran pertanyaan floating.
class _SuggestionPill extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _SuggestionPill({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accentColor.withValues(alpha: 0.30)),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
