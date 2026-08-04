import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../services/weton_dictionary_service.dart';

/// Computes dominant Javanese element(s) from saptawara + pancawara.
/// Returns single name (e.g. 'Geni') or dual sorted (e.g. 'Banyu & Geni').
String _dominantElement(String saptawara, String pancawara) {
  double geni = 1, banyu = 1, lemah = 1, angin = 1;

  final s = saptawara.toLowerCase();
  if (s.contains('ahad') || s.contains('minggu')) {
    geni += 2; angin += 1;
  } else if (s.contains('senin')) {
    banyu += 3;
  } else if (s.contains('selasa')) {
    geni += 3;
  } else if (s.contains('rabu')) {
    banyu += 2; lemah += 1;
  } else if (s.contains('kamis')) {
    angin += 3;
  } else if (s.contains('jumat')) {
    lemah += 2; banyu += 1;
  } else if (s.contains('sabtu')) {
    lemah += 3; geni += 1;
  }

  final p = pancawara.toLowerCase();
  if (p.contains('legi')) {
    angin += 3; lemah += 1;
  } else if (p.contains('pahing')) {
    geni += 3; angin += 1;
  } else if (p.contains('pon')) {
    banyu += 3; geni += 1;
  } else if (p.contains('wage')) {
    lemah += 3; banyu += 1;
  } else if (p.contains('kliwon')) {
    geni += 1; banyu += 1; lemah += 1; angin += 1;
  }

  final values = {'Geni': geni, 'Banyu': banyu, 'Lemah': lemah, 'Angin': angin};
  final maxVal = values.values.reduce((a, b) => a > b ? a : b);
  final tied = values.entries
      .where((e) => (e.value - maxVal).abs() < 0.001)
      .map((e) => e.key)
      .toList()
    ..sort();

  if (tied.length >= 3) return 'Seimbang';
  if (tied.length == 2) return '${tied[0]} & ${tied[1]}';
  return tied.first;
}

/// On-demand AI synthesis yang menghubungkan weton lahir, energi wuku berjalan,
/// elemen dominan, dan Pancasuda menjadi satu narasi personal.
class WetonAiSynthesisSection extends ConsumerStatefulWidget {
  const WetonAiSynthesisSection({
    super.key,
    required this.result,
    required this.entry,
    this.dailyInsightData,
  });

  final WetonInfo result;
  final WetonDictionaryEntry entry;
  final Map<String, dynamic>? dailyInsightData;

  @override
  ConsumerState<WetonAiSynthesisSection> createState() =>
      _WetonAiSynthesisSectionState();
}

class _WetonAiSynthesisSectionState
    extends ConsumerState<WetonAiSynthesisSection> {
  String? _insight;
  bool _loading = false;
  String? _error;

  static String _cacheKey(String saptawara, String pancawara, String wuku) =>
      'weton_ai_synthesis_${saptawara.toLowerCase()}_${pancawara.toLowerCase()}_${wuku.toLowerCase()}';

  String _buildPrompt() {
    final r = widget.result;
    final dominant = _dominantElement(r.saptawara, r.pancawara);

    final wukuMap = widget.dailyInsightData?['wuku'] as Map<String, dynamic>?;
    final wukuNama = wukuMap?['nama_wuku'] as String? ?? r.wuku;
    final wukuArketipe = wukuMap?['arketipe_modern'] as String? ?? '';

    final wukuCtx = wukuArketipe.isNotEmpty
        ? '$wukuNama ($wukuArketipe)'
        : wukuNama;

    return 'Weton ${r.saptawara} ${r.pancawara}, neptu ${r.totalNeptu}. '
        'Elemen dominan: $dominant. '
        'Pancasuda: ${r.pancasuda}. Pangarasan: ${r.pangarasan}. '
        'Wuku berjalan: $wukuCtx. '
        'Tulis 3–4 kalimat sintesis yang menghubungkan weton lahir '
        'dengan energi wuku sekarang — apa yang sedang aktif dalam diri '
        'orang ini dan apa yang perlu disadari minggu ini. '
        'Nada empatik, psikologi modern, bukan ramalan buta.';
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      final r = widget.result;
      // Anchor cache key ke r.wuku (nilai lahir stabil), bukan API-returned nama_wuku
      // Mencegah dual cache entries jika nama_wuku dari API berbeda casing
      final key = _cacheKey(r.saptawara, r.pancawara, r.wuku);

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null) {
        if (mounted) setState(() { _insight = cached; _loading = false; });
        return;
      }

      final authHeader = await ref.read(authProvider.notifier).getAuthHeader();
      final result = await ApiService.generateAiChat(
        prompt: _buildPrompt(),
        authHeader: authHeader,
      );
      final text = result['response'] as String? ?? '';
      if (text.isNotEmpty) {
        await prefs.setString(key, text);
        if (mounted) setState(() => _insight = text);
      } else {
        if (mounted) setState(() => _error = 'Tidak ada respons. Coba lagi.');
      }
    } catch (e) {
      debugPrint('WetonAiSynthesisSection error: $e');
      if (mounted) setState(() => _error = 'Gagal memuat — coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_insight != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '☯ Sintesis Kosmis Wetonmu',
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final r = widget.result;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(
                      _cacheKey(r.saptawara, r.pancawara, r.wuku),
                    );
                    if (mounted) {
                      setState(() => _insight = null);
                      _generate();
                    }
                  },
                  child: Text(
                    '↻',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _insight!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.55,
              ),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Menyusun sintesis kosmismu...',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.accentGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: _generate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded,
                  size: 14, color: Color(0xFFF87171)),
              const SizedBox(width: 6),
              Text(
                _error!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFFF87171),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _generate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'Baca sintesis kosmis wetonmu minggu ini',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
