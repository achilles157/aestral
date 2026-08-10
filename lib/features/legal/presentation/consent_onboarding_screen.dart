import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../models/consent_log.dart';
import '../services/consent_service.dart';

/// Halaman onboarding consent PDP + age gate.
/// Ditampilkan SEKALI — setelah user setuju, tidak akan muncul lagi
/// kecuali versi kebijakan naik (dicek via [ConsentService.hasRequiredConsents]).
class ConsentOnboardingScreen extends ConsumerStatefulWidget {
  /// Callback setelah semua consent disetujui.
  final VoidCallback? onComplete;

  const ConsentOnboardingScreen({super.key, this.onComplete});

  @override
  ConsumerState<ConsentOnboardingScreen> createState() =>
      _ConsentOnboardingScreenState();
}

class _ConsentOnboardingScreenState
    extends ConsumerState<ConsentOnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _dataProcessing = true; // wajib — pre-checked
  bool _historyStorage = true; // wajib — pre-checked
  bool _analytics = false; // opsional
  bool _ageConfirmed = false;
  bool _submitting = false;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_ageConfirmed) {
      setState(() => _error = 'Harap konfirmasi usia Anda (minimal 18 tahun).');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final svc = ref.read(consentServiceProvider);
      await svc.grantAll(
        dataProcessing: _dataProcessing,
        historyStorage: _historyStorage,
        analytics: _analytics,
      );
    } catch (_) {
      // fail-open: tetap lanjut meski penyimpanan gagal
    }

    if (!mounted) return;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Text(
                  'Selamat Datang\ndi Aestral ✨',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sebelum kita mulai, ada beberapa hal penting yang'
                  ' perlu kamu ketahui.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Disclaimer AI ────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: AppTheme.accentPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aestral menggunakan AI untuk refleksi & hiburan.'
                          ' Semua hasil pembacaan BUKAN nasihat'
                          ' profesional, medis, keuangan, atau hukum.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Consent 1: Data Processing ───────────────────────
                _ConsentTile(
                  type: ConsentType.dataProcessing,
                  value: _dataProcessing,
                  onChanged: (_) {}, // wajib — tidak bisa di-uncheck
                  locked: true,
                ),
                const SizedBox(height: 10),

                // ── Consent 2: History Storage ───────────────────────
                _ConsentTile(
                  type: ConsentType.historyStorage,
                  value: _historyStorage,
                  onChanged: (_) {}, // wajib — tidak bisa di-uncheck
                  locked: true,
                ),
                const SizedBox(height: 10),

                // ── Consent 3: Analytics (opsional) ──────────────────
                _ConsentTile(
                  type: ConsentType.analytics,
                  value: _analytics,
                  onChanged: (v) => setState(() => _analytics = v),
                ),
                const SizedBox(height: 24),

                // ── Age Gate ─────────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppTheme.accentGold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Konfirmasi Usia',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aestral hanya untuk pengguna berusia 18 tahun'
                        ' ke atas.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _ageConfirmed,
                              onChanged: (v) =>
                                  setState(() => _ageConfirmed = v ?? false),
                              activeColor: AppTheme.accentGold,
                              side: const BorderSide(
                                color: Colors.white30,
                                width: 1.5,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saya berusia 18 tahun atau lebih',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Privacy Link ─────────────────────────────────────
                Center(
                  child: Text(
                    'Dengan melanjutkan, kamu menyetujui\n'
                    'Kebijakan Privasi & Ketentuan Layanan kami.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: navigasi ke Privacy Policy screen
                    },
                    child: Text(
                      '📜 Baca Kebijakan Privasi',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.accentGold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.accentGold.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Error ────────────────────────────────────────────
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Submit Button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      disabledBackgroundColor: AppTheme.accentGold.withValues(
                        alpha: 0.4,
                      ),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: _submitting ? 0 : 4,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : Text(
                            'Setuju & Lanjutkan',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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

/// Tile untuk satu item consent.
class _ConsentTile extends StatelessWidget {
  final ConsentType type;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool locked;

  const _ConsentTile({
    required this.type,
    required this.value,
    required this.onChanged,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: locked ? null : (v) => onChanged(v ?? false),
                activeColor: AppTheme.accentGold,
                checkColor: Colors.black,
                side: BorderSide(
                  color: locked ? Colors.white12 : Colors.white30,
                  width: 1.5,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (locked)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text('🔒', style: TextStyle(fontSize: 10)),
                      ),
                    Text(
                      type.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                    if (type.isRequired)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Wajib',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  type.description,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.35,
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

