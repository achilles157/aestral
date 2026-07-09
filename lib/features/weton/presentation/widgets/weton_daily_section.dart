import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/pranata_mangsa_repository.dart';
import '../../services/weton_dictionary_service.dart';
import 'daily_insight_card.dart';
import 'seasonal_banner.dart';

/// Daily insight section — spinner saat loading, DailyInsightCard +
/// SeasonalBanner saat data tersedia.  Provider di-watch langsung di sini
/// sehingga WetonCalculatorScreen tidak perlu meneruskannya.
class WetonDailySection extends ConsumerWidget {
  final bool isLoading;
  final Map<String, dynamic>? dailyInsightData;

  const WetonDailySection({
    super.key,
    required this.isLoading,
    required this.dailyInsightData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Loading dari API ────────────────────────────────────────────────
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    if (dailyInsightData == null) return const SizedBox.shrink();

    // ── Tunggu providers JSON ───────────────────────────────────────────
    final sisaBagiAsync    = ref.watch(sisaBagiProvider);
    final wukuAsync        = ref.watch(wukuProvider);
    final pranataMangsaAsync = ref.watch(pranataMangsaListProvider);

    final allLoading = sisaBagiAsync.isLoading ||
        wukuAsync.isLoading ||
        pranataMangsaAsync.isLoading;
    final anyError = sisaBagiAsync.hasError ||
        wukuAsync.hasError ||
        pranataMangsaAsync.hasError;

    if (allLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(color: AppTheme.accentPurple),
        ),
      );
    }

    if (anyError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Gagal memuat data harian.',
            style: GoogleFonts.outfit(color: AppTheme.accentPink, fontSize: 13),
          ),
        ),
      );
    }

    // ── Resolve data ────────────────────────────────────────────────────
    final sisaBagiList = sisaBagiAsync.value!;
    final wukuList     = wukuAsync.value!;
    final pranataList  = pranataMangsaAsync.value!;

    final dailyInfo      = dailyInsightData!['daily']       as Map<String, dynamic>;
    final weeklyInfo     = dailyInsightData!['weekly']      as Map<String, dynamic>;
    final targetWetonInfo = dailyInsightData!['targetWeton'] as Map<String, dynamic>?;

    final sisaBagiVal = dailyInfo['sisaBagi'] as int;
    final wukuIndex   = weeklyInfo['wukuIndex'] as int;
    final wukuName    = weeklyInfo['wukuName']  as String;

    final sisaBagiEntry = sisaBagiList.firstWhere(
      (s) => s['sisa_bagi'] == sisaBagiVal,
      orElse: () => sisaBagiList.first,
    );
    final wukuEntry = wukuList.firstWhere(
      (w) =>
          w['id'] == wukuIndex ||
          w['id'] == wukuIndex + 1 ||
          w['nama_wuku'].toString().toLowerCase() == wukuName.toLowerCase(),
      orElse: () => wukuList.first,
    );
    final targetPranataId = targetWetonInfo?['pranataMangsaId'] as int? ?? 1;
    final targetPranata   = pranataList.firstWhere(
      (m) => m.id == targetPranataId,
      orElse: () => pranataList.first,
    );

    return Column(
      children: [
        DailyInsightCard(sisaBagi: sisaBagiEntry, wuku: wukuEntry),
        const SizedBox(height: 20),
        SeasonalBanner(mangsa: targetPranata),
      ],
    );
  }
}
