import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Weton wrapper — data yang selalu tersedia dari birth profile.
class WetonContext {
  final String label; // "Jumat Kliwon"
  final int neptu;
  final String characterSummary;
  final String pangarasan; // kosong jika tidak ada
  final String pancasuda; // kosong jika tidak ada
  final String wuku; // wuku lahir

  const WetonContext({
    required this.label,
    required this.neptu,
    required this.characterSummary,
    this.pangarasan = '',
    this.pancasuda = '',
    this.wuku = '',
  });

  bool get isComplete => neptu > 0 && label.isNotEmpty;
}

/// BaZi wrapper — data dari bazi_chart_provider.
class BaziContext {
  final String dayMasterElement;
  final String dmStrengthLabel;
  final String? dominantElement; // dari WuXingBalance
  final String? daYunLabel; // "Kayu Yin — usia 28–37"
  final String? annualPillarLabel; // "Naga (Tanah)"

  const BaziContext({
    required this.dayMasterElement,
    required this.dmStrengthLabel,
    this.dominantElement,
    this.daYunLabel,
    this.annualPillarLabel,
  });

  bool get isComplete => dayMasterElement.isNotEmpty;
}

/// Satu kartu tarot dalam konteks.
class TarotCardContext {
  final String name;
  final String archetype;
  final String element;
  final String label; // "past" | "present" | "future" | "potensi" | ...
  final bool isReversed;

  const TarotCardContext({
    required this.name,
    required this.archetype,
    required this.element,
    required this.label,
    this.isReversed = false,
  });
}

/// Tarot wrapper.
class TarotContext {
  final List<TarotCardContext> cards;
  final String? drawType; // "kosmis" | "mangsa" | "moment" | "thematic" | null

  const TarotContext({this.cards = const [], this.drawType});

  bool get isComplete => cards.isNotEmpty;
}

/// Seasonal / active cycle context — data siklik saat ini.
class SeasonalContext {
  final int mangsaId;
  final String mangsaName;
  final String seasonElement;
  final String? mangsaArketipe;

  const SeasonalContext({
    required this.mangsaId,
    required this.mangsaName,
    required this.seasonElement,
    this.mangsaArketipe,
  });
}

/// Konteks lintas tradisi — agregat dari 3 sistem + siklus musiman.
/// Dipakai sebagai sumber tunggal untuk membangun `aiContext` di semua
/// entry point AI (Sesepuh Kosmis, oracle spesialis, cross-oracle prompt).
class CrossContextBundle {
  final WetonContext weton;
  final BaziContext bazi;
  final TarotContext tarot;
  final SeasonalContext? seasonal;

  const CrossContextBundle({
    required this.weton,
    required this.bazi,
    required this.tarot,
    this.seasonal,
  });

  /// Jumlah sistem dengan data valid (min. 2 untuk Grand Reading).
  int get systemsReady {
    int count = 0;
    if (weton.isComplete) count++;
    if (bazi.isComplete) count++;
    if (tarot.isComplete) count++;
    return count;
  }

  bool get isGrandReady => systemsReady >= 2;

  /// Konversi ke Map<String, dynamic> — format yang diterima oleh
  /// `OracleChatSecreen.aiContext` dan `oracleChatProvider.sendMessage(context:)`.
  Map<String, dynamic> toAiContext() {
    final ctx = <String, dynamic>{};

    if (weton.isComplete) {
      ctx['wetonLahir'] = {
        'nama': weton.label,
        'neptu': weton.neptu,
        'elemen': '',
        'karakter': weton.characterSummary,
      };
      if (weton.pangarasan.isNotEmpty) {
        ctx['pangarasan'] = weton.pangarasan;
      }
    }

    if (tarot.isComplete) {
      ctx['tarotCards'] = tarot.cards
          .map(
            (c) => {
              'name': c.name,
              'label': c.label,
              'isReversed': c.isReversed,
              'archetype': c.archetype,
              'element': c.element,
            },
          )
          .toList();
    }

    if (bazi.isComplete) {
      ctx['baziChart'] = <String, dynamic>{
        'dayMasterElement': bazi.dayMasterElement,
        'dmStrength': bazi.dmStrengthLabel,
      };
      if (bazi.dominantElement != null) {
        (ctx['baziChart'] as Map<String, dynamic>)['wuXingDominant'] =
            bazi.dominantElement;
      }
    }

    if (seasonal != null) {
      ctx['seasonalContext'] = {
        'mangsaName': seasonal!.mangsaName,
        'seasonElement': seasonal!.seasonElement,
        if (seasonal!.mangsaArketipe != null)
          'mangsaArketipe': seasonal!.mangsaArketipe,
      };
    }

    return ctx;
  }
}

/// Riverpod provider untuk CrossContextBundle.
///
/// Refresh dilakukan tiap kali ada perubahan pada birth profile, BaZi chart,
/// atau tarot draw. Dipanggil oleh entry point AI untuk mendapatkan konteks
/// terbaru tanpa duplikasi logika.
class CrossContextNotifier extends Notifier<CrossContextBundle> {
  @override
  CrossContextBundle build() {
    // Placeholder — akan di-refresh oleh entry point via buildFromProviders().
    return CrossContextBundle(
      weton: const WetonContext(label: '', neptu: 0, characterSummary: ''),
      bazi: const BaziContext(dayMasterElement: '', dmStrengthLabel: ''),
      tarot: const TarotContext(),
    );
  }

  void set(CrossContextBundle bundle) => state = bundle;
}

final crossContextProvider =
    NotifierProvider<CrossContextNotifier, CrossContextBundle>(
      CrossContextNotifier.new,
    );
