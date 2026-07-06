/// Model untuk menyimpan hasil pembacaan Oracle AI dari tebaran 3 kartu Tarot.
class TarotCardNarrative {
  final String label; // 'past' | 'present' | 'future'
  final String narrative;

  const TarotCardNarrative({
    required this.label,
    required this.narrative,
  });
}

class TarotOracleReading {
  final List<TarotCardNarrative> cardNarratives;
  final String synthesis;

  const TarotOracleReading({
    required this.cardNarratives,
    required this.synthesis,
  });

  /// Ambil narasi untuk posisi tertentu. Return string kosong jika tidak ada.
  String getNarrativeForLabel(String label) {
    try {
      return cardNarratives.firstWhere((n) => n.label == label).narrative;
    } catch (_) {
      return '';
    }
  }

  factory TarotOracleReading.fromJson(Map<String, dynamic> json) {
    final readings = (json['cardReadings'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((r) => TarotCardNarrative(
              label: r['label'] as String,
              narrative: r['narrative'] as String? ?? '',
            ))
        .toList();
    return TarotOracleReading(
      cardNarratives: readings,
      synthesis: json['synthesis'] as String? ?? '',
    );
  }
}
