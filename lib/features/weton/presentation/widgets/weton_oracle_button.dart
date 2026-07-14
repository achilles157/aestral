import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/weton_utils.dart';
import '../../../ai/presentation/oracle_chat_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../data/pranata_mangsa_repository.dart';
import '../../services/weton_dictionary_service.dart';
import 'weton_ui_utils.dart';

/// Tombol "Tanyakan Orakel Weton Lahir Anda" — membangun konteks AI
/// dari weton lahir, wuku berjalan, dan pranata mangsa aktif.
class WetonOracleButton extends ConsumerWidget {
  final WetonInfo result;
  final String? warnaHarmoni;
  final Map<String, dynamic>? dailyInsightData;

  const WetonOracleButton({
    super.key,
    required this.result,
    this.warnaHarmoni,
    this.dailyInsightData,
  });

  static const _saptawaraElemenMap = {
    'Ahad': 'Api',
    'Minggu': 'Api',
    'Senin': 'Air',
    'Selasa': 'Api',
    'Rabu': 'Tanah',
    'Kamis': 'Kayu',
    'Jumat': 'Air',
    'Sabtu': 'Tanah',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor =
        parseWetonHexColor(warnaHarmoni) ?? AppTheme.accentPurple;
    final iconColor = parseWetonHexColor(warnaHarmoni) ?? AppTheme.accentGold;
    final wukuAsync = ref.watch(wukuProvider);
    final pranataAsync = ref.watch(pranataMangsaListProvider);

    return ElevatedButton.icon(
      onPressed: () async {
        final authHeader = await ref
            .read(authProvider.notifier)
            .getAuthHeader();
        if (!context.mounted) return;

        // ── Wuku berjalan ─────────────────────────────────────────────────
        Map<String, dynamic>? wukuContext;
        if (dailyInsightData != null && wukuAsync.hasValue) {
          try {
            final weeklyInfo =
                dailyInsightData!['weekly'] as Map<String, dynamic>?;
            final wukuIndex = weeklyInfo?['wukuIndex'] as int? ?? -1;
            final wukuName = weeklyInfo?['wukuName'] as String? ?? '';
            final wukuList = wukuAsync.value!;
            final wukuEntry = wukuList.firstWhere(
              (w) =>
                  w['id'] == wukuIndex ||
                  w['id'] == wukuIndex + 1 ||
                  w['nama_wuku'].toString().toLowerCase() ==
                      wukuName.toLowerCase(),
              orElse: () => wukuList.first,
            );
            wukuContext = {
              'nama': wukuEntry['nama_wuku'] ?? wukuName,
              'elemen': wukuEntry['elemen'] ?? '',
            };
          } catch (e) {
            debugPrint('WetonOracleButton: gagal build wuku context — $e');
          }
        }

        // ── Pranata Mangsa berjalan ────────────────────────────────────────
        Map<String, dynamic>? pranataContext;
        if (dailyInsightData != null && pranataAsync.hasValue) {
          try {
            final targetWetonInfo =
                dailyInsightData!['targetWeton'] as Map<String, dynamic>?;
            final targetPranataId =
                targetWetonInfo?['pranataMangsaId'] as int? ?? 1;
            final pranataList = pranataAsync.value!;
            final pranata = pranataList.firstWhere(
              (m) => m.id == targetPranataId,
              orElse: () => pranataList.first,
            );
            pranataContext = {
              'nama': pranata.namaMangsa,
              'arketipe': pranata.arketipeModern,
              if (pranata.karakterEnergi.isNotEmpty)
                'karakterEnergi': pranata.karakterEnergi,
              if (pranata.pesanKesadaran.isNotEmpty)
                'pesanKesadaran': pranata.pesanKesadaran,
            };
          } catch (e) {
            debugPrint('WetonOracleButton: gagal build wuku context — $e');
          }
        }

        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OracleChatScreen(
              oracleType: 'weton',
              authHeader: authHeader,
              aiContext: {
                'wetonLahir': {
                  'nama': '${result.saptawara} ${result.pancawara}',
                  'neptu': result.totalNeptu,
                  'elemen': _saptawaraElemenMap[result.saptawara] ?? '',
                  'karakter': result.characterSummary,
                  'pancasuda': result.pancasuda,
                },
                'pangarasan': result.pangarasan,
                if (wukuContext != null) 'wukuBerjalan': wukuContext,
                if (pranataContext != null) 'pranataMangsa': pranataContext,
              },
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        side: BorderSide(color: borderColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      icon: Icon(Icons.auto_awesome, color: iconColor, size: 18),
      label: Text(
        'Tanyakan Orakel Weton Lahir Anda',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
