import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/birth_profile_provider.dart';
import '../providers/oracle_chat_provider.dart';
import '../../tarot/services/tarot_data.dart';
import 'oracle_card_widgets.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/widgets/cosmic_auth_bottom_sheet.dart';

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

  // Topic-based ambient glow — warna berubah per topik percakapan (PRD section 4)
  late Color _topicGlowColor;
  late Color _prevGlowColor;

  @override
  void initState() {
    super.initState();
    _config = kOracleConfigs[widget.oracleType] ?? kOracleConfigs['weton']!;
    _topicGlowColor = Color(_config.accentColor);
    _prevGlowColor = Color(_config.accentColor);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Initialize provider state from local storage
    Future.microtask(() async {
      await ref.read(oracleChatProvider(widget.oracleType).notifier).initialize(aiContext: widget.aiContext);
      
      // Auto-trigger a silent greeting from the oracle if conversation is empty
      final currentState = ref.read(oracleChatProvider(widget.oracleType));
      if (currentState.messages.isEmpty) {
        final dynamicAuthHeader = await ref.read(authProvider.notifier).getAuthHeader();
        ref.read(oracleChatProvider(widget.oracleType).notifier).sendMessage(
              prompt: 'Halo',
              authHeader: dynamicAuthHeader,
              context: widget.aiContext,
              isSilent: true,
            );
      }
    });
  }

  @override
  void dispose() {
    // Capture notifier ref SEBELUM disposal agar aman di Riverpod
    final notifier =
        ref.read(oracleChatProvider(widget.oracleType).notifier);
    final authHeader = widget.authHeader;

    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _glowCtrl.dispose();

    // Fire-and-forget summary setelah controllers di-dispose
    notifier.summarizeSession(authHeader).catchError((_) {});
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

  /// Wraps [child] in [BackdropFilter] only when reduce-effects is off.
  Widget _maybeBlur({required double sigma, required Widget child}) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    FocusScope.of(context).unfocus();

    final dynamicAuthHeader = await ref.read(authProvider.notifier).getAuthHeader();

    await ref.read(oracleChatProvider(widget.oracleType).notifier).sendMessage(
          prompt: text.trim(),
          authHeader: dynamicAuthHeader,
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

  /// Deteksi elemen/topik dari teks oracle untuk ambient glow dinamis (PRD section 4).
  Color _detectTopicColor(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'karier|ambisi|semangat|motivasi|api|berani|tegas|tindakan|keberanian').hasMatch(t)) {
      return const Color(0xFFE64A19); // Api — merah-oranye
    }
    if (RegExp(r'emosi|asmara|intuisi|mimpi|perasaan|batin|hubungan|cinta|air').hasMatch(t)) {
      return const Color(0xFF1565C0); // Air — biru
    }
    if (RegExp(r'pertumbuhan|berkembang|kreatif|kreativitas|inspirasi|kayu|tumbuh').hasMatch(t)) {
      return const Color(0xFF2E7D32); // Kayu — hijau
    }
    if (RegExp(r'keluarga|stabilitas|rumah|kesehatan|tanah|rezeki|materi|pondasi').hasMatch(t)) {
      return const Color(0xFF6D4C41); // Tanah — coklat
    }
    if (RegExp(r'keuangan|uang|finansial|logika|disiplin|logam|struktur|fokus').hasMatch(t)) {
      return const Color(0xFF78909C); // Logam — biru-abu
    }
    return _accentColor; // Default: warna persona oracle
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oracleChatProvider(widget.oracleType));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final authState = ref.watch(authProvider);
    final isGuest = authState == null || authState.isMock;

    // Auto-scroll when new message added + update topic glow from oracle response
    ref.listen<OracleChatState>(
      oracleChatProvider(widget.oracleType),
      (prev, next) {
        if (prev != null && next.messages.length > prev.messages.length) {
          _scrollToBottom();
          // Detect element/topik dari pesan oracle terbaru untuk ambient glow
          final lastMsg = next.messages.last;
          if (lastMsg.role == 'model' && lastMsg.text.isNotEmpty) {
            final detected = _detectTopicColor(lastMsg.text);
            if (detected != _topicGlowColor) {
              setState(() {
                _prevGlowColor = _topicGlowColor;
                _topicGlowColor = detected;
              });
            }
          }
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
          // Overlay tambahan untuk synthesis oracle — mandala_bg cukup terang sehingga
          // teks chat jadi susah terbaca tanpa dim ekstra ini
          if (widget.oracleType == 'synthesis')
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          // Ambient glow — warna berubah perlahan mengikuti topik percakapan (PRD section 4)
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: _prevGlowColor, end: _topicGlowColor),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            builder: (_, animColor, __) {
              return AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) {
                  final glow = Curves.easeInOut.transform(_glowCtrl.value);
                  final c = animColor ?? _topicGlowColor;
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
                            c.withValues(alpha: 0.10 + glow * 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
                if (isGuest && state.guestMessageCount == 0 && state.messages.isNotEmpty)
                  _buildGuestQuotaHint(),
                if (isGuest && state.guestMessageCount >= 1)
                  _buildSoftGatePanel(bottomInset, bottomPadding)
                else ...[
                  _buildSuggestionPills(state),
                  _buildInputRow(state, bottomInset, bottomPadding),
                ],
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
        child: _maybeBlur(
          sigma: 16,
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
          OraclePulsingMandala(color: _accentColor),
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
              child: OraclePulsingMandala(color: _accentColor),
            ),
          );
        }
        final msg = msgs[i];
        return msg.role == 'user'
            ? OracleChatUserBubble(message: msg)
            : OracleChatOracleBubble(
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
          return OracleSuggestionPill(
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

        ref.read(authProvider.notifier).getAuthHeader().then((dynamicAuthHeader) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OracleChatScreen(
                  oracleType: 'synthesis',
                  authHeader: dynamicAuthHeader,
                  aiContext: synthesisContext.isEmpty ? null : synthesisContext,
                ),
              ),
            );
          }
        });
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

  // ── Guest Quota Hint ────────────────────────────────────────────────────────

  Widget _buildGuestQuotaHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withValues(alpha: 0.30)),
            ),
            child: Text(
              '✦ 1 pertanyaan gratis tersisa',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: _accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
        child: _maybeBlur(
          sigma: 20,
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
                      : Semantics(
                          label: 'Kirim pesan',
                          button: true,
                          child: GestureDetector(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _oracleContinuationTeaser() {
    const teasers = {
      'weton':
          '"Masih ada yang ingin aku sampaikan — tentang energi yang sedang berputar di sekelilingmu, dan apa yang sebaiknya kamu jaga hari ini..."',
      'bazi':
          '"Elemen dalam dirimu masih menyimpan pola yang belum sempat kubacakan — sebuah ketidakseimbangan yang mungkin kamu rasakan tapi belum bisa kamu namakan..."',
      'tarot':
          '"Kartu-kartumu masih berbisik sesuatu yang belum sempat kusampaikan — sebuah pesan dari alam bawah sadarmu yang perlu kamu dengar..."',
      'synthesis':
          '"Tiga sistem ini memiliki benang merah yang jarang terlihat — sebuah pola yang menghubungkan masa lalumu, kondisimu saat ini, dan arah yang sedang kamu tuju..."',
    };
    return teasers[widget.oracleType] ?? teasers['weton']!;
  }

  Widget _buildSoftGatePanel(double bottomInset, double bottomPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, math.max(bottomInset, bottomPadding) + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _maybeBlur(
          sigma: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0B26).withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _accentColor.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Curiosity gap — teks oracle selanjutnya diblur untuk memancing rasa penasaran
                SizedBox(
                  height: 58,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                          child: Text(
                            _oracleContinuationTeaser(),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 28,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xFF0F0B26)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Orakel Menanti Jawabanmu',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk dengan Google atau Email untuk membalas dialog dan menyimpan perjalanan kosmismu.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final success = await CosmicAuthBottomSheet.show(context);
                    if (success == true) {
                      setState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accentColor,
                          _accentColor.withValues(alpha: 0.70),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Simpan & Lanjutkan Dialog',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
