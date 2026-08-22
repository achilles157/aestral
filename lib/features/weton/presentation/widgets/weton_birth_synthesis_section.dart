import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/oracle_rest_dialog.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../services/weton_dictionary_service.dart';

/// Sintesis seumur hidup berbasis data weton lahir saja.
/// Cache permanen - tidak berubah sepanjang hidup, tidak terikat siklus wuku/mangsa.
class WetonBirthSynthesisSection extends ConsumerStatefulWidget {
  const WetonBirthSynthesisSection({
    super.key,
    required this.result,
    required this.entry,
  });

  final WetonInfo result;
  final WetonDictionaryEntry entry;

  @override
  ConsumerState<WetonBirthSynthesisSection> createState() =>
      _WetonBirthSynthesisSectionState();
}

class _WetonBirthSynthesisSectionState
    extends ConsumerState<WetonBirthSynthesisSection> {
  String? _insight;
  bool _loading = false;
  String? _error;

  /// Cache key permanen - tidak pernah expired karena data lahir tidak berubah.
  static String _cacheKey(String saptawara, String pancawara) =>
      'weton_birth_synthesis_${saptawara.toLowerCase()}_${pancawara.toLowerCase()}';

  String _buildPrompt() {
    final r = widget.result;
    final e = widget.entry;
    return 'Weton ${r.saptawara} ${r.pancawara}, neptu ${r.totalNeptu}. '
        'Pancasuda: ${r.pancasuda}. Pangarasan: ${r.pangarasan}. '
        'Karakter: ${e.headline}. '
        'Tulis 3-4 kalimat yang menggambarkan pola hidup orang ini secara konkret: '
        'bagaimana cara mereka bekerja dan mengambil keputusan, '
        'pola yang sering muncul dalam hubungan mereka, '
        'dan satu hal yang kalau disadari bisa mengubah banyak hal. '
        'Bahasa sehari-hari, mudah dipahami, boleh sedikit filosofis.';
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final key = _cacheKey(widget.result.saptawara, widget.result.pancawara);
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null) {
        if (mounted)
          setState(() {
            _insight = cached;
            _loading = false;
          });
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
      debugPrint('WetonBirthSynthesisSection error: $e');
      if (context.mounted) {
        OracleRestDialog.showIfOracleRest(context, e);
      }
      if (mounted) setState(() => _error = 'Gagal memuat - coba lagi.');
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
          color: AppTheme.accentPurple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentPurple.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '✦ Blueprint Jiwa Wetonmu',
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  'Seumur Hidup',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: AppTheme.accentPurple.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(
                      _cacheKey(
                        widget.result.saptawara,
                        widget.result.pancawara,
                      ),
                    );
                    if (mounted) setState(() => _insight = null);
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
                color: AppTheme.accentPurple,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Membaca blueprint jiwa wetonmu...',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.accentPurple,
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
              const Icon(
                Icons.refresh_rounded,
                size: 14,
                color: Color(0xFFF87171),
              ),
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
            color: AppTheme.accentPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✦', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'Baca blueprint jiwa wetonmu',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.accentPurple,
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
