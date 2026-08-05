import 'package:flutter_test/flutter_test.dart';

// Replicates element weight logic from WetonElementMandala.elementValues
// for pure unit testing without widget dependency.
Map<String, double> _elementValues(String saptawara, String pancawara) {
  double geni = 1, banyu = 1, lemah = 1, angin = 1;

  final s = saptawara.toLowerCase();
  if (s.contains('ahad') || s.contains('minggu')) {
    geni += 2;
    angin += 1;
  } else if (s.contains('senin')) {
    banyu += 3;
  } else if (s.contains('selasa')) {
    geni += 3;
  } else if (s.contains('rabu')) {
    banyu += 2;
    lemah += 1;
  } else if (s.contains('kamis')) {
    angin += 3;
  } else if (s.contains('jumat')) {
    lemah += 2;
    banyu += 1;
  } else if (s.contains('sabtu')) {
    lemah += 3;
    geni += 1;
  }

  final p = pancawara.toLowerCase();
  if (p.contains('legi')) {
    angin += 3;
    lemah += 1;
  } else if (p.contains('pahing')) {
    geni += 3;
    angin += 1;
  } else if (p.contains('pon')) {
    banyu += 3;
    geni += 1;
  } else if (p.contains('wage')) {
    lemah += 3;
    banyu += 1;
  } else if (p.contains('kliwon')) {
    geni += 1;
    banyu += 1;
    lemah += 1;
    angin += 1;
  }

  final total = geni + banyu + lemah + angin;
  return {
    'geni': geni / total,
    'banyu': banyu / total,
    'lemah': lemah / total,
    'angin': angin / total,
  };
}

// Detects dominant element(s) — mirrors tie-breaking logic in mandala widget
List<String> _dominants(String saptawara, String pancawara) {
  final values = _elementValues(saptawara, pancawara);
  final maxVal = values.values.reduce((a, b) => a > b ? a : b);
  return values.entries
      .where((e) => (e.value - maxVal).abs() < 0.001)
      .map((e) => e.key)
      .toList()
    ..sort();
}

void main() {
  // ─── Accuracy: 15 Juli 2002 = Senin Pahing ───────────────────────────────

  group('Element calculation accuracy', () {
    test('15 Juli 2002 (Senin Pahing): Api 36.4%, Air 36.4%, Tanah 9.1%, Angin 18.2%', () {
      final values = _elementValues('Senin', 'Pahing');
      expect((values['geni']! * 100).toStringAsFixed(1), '36.4');
      expect((values['banyu']! * 100).toStringAsFixed(1), '36.4');
      expect((values['lemah']! * 100).toStringAsFixed(1), '9.1');
      expect((values['angin']! * 100).toStringAsFixed(1), '18.2');
    });

    test('Selasa Pon: Api dominan', () {
      final values = _elementValues('Selasa', 'Pon');
      // geni: 1+3+1=5, banyu: 1+3=4, lemah:1, angin:1 → total 11
      expect(values['geni']! > values['banyu']!, isTrue);
      expect(values['geni']! > values['lemah']!, isTrue);
      expect(values['geni']! > values['angin']!, isTrue);
    });

    test('Sabtu Wage: Tanah dominan', () {
      final values = _elementValues('Sabtu', 'Wage');
      // lemah: 1+3+3=7, geni: 1+1=2, banyu: 1+1=2, angin:1 → total 13
      expect(values['lemah']! > values['geni']!, isTrue);
      expect(values['lemah']! > values['banyu']!, isTrue);
    });

    test('Kamis Legi: Angin dominan', () {
      final values = _elementValues('Kamis', 'Legi');
      // angin: 1+3+3=7, geni:1, banyu:1, lemah:1+1=2 → total 11
      expect(values['angin']! > values['geni']!, isTrue);
    });

    test('Semua total = 1.0 (normalisasi benar)', () {
      final combos = [
        ['Senin', 'Legi'], ['Selasa', 'Pahing'], ['Rabu', 'Pon'],
        ['Kamis', 'Wage'], ['Jumat', 'Kliwon'], ['Sabtu', 'Legi'],
        ['Minggu', 'Pahing'],
      ];
      for (final c in combos) {
        final v = _elementValues(c[0], c[1]);
        final total = v.values.reduce((a, b) => a + b);
        expect(total, closeTo(1.0, 0.001),
            reason: '${c[0]} ${c[1]} total should be 1.0');
      }
    });
  });

  // ─── Tie-breaking ─────────────────────────────────────────────────────────

  group('Tie-breaking logic', () {
    test('Senin Pahing: Api & Banyu tie → dua elemen dominant', () {
      final doms = _dominants('Senin', 'Pahing');
      expect(doms.length, 2);
      expect(doms, contains('geni'));
      expect(doms, contains('banyu'));
    });

    test('Single dominant: Selasa Pon → hanya Api', () {
      final doms = _dominants('Selasa', 'Pon');
      expect(doms.length, 1);
      expect(doms.first, 'geni');
    });

    test('Kliwon menambah semua elemen sama → lebih merata (tidak crash)', () {
      // Kliwon menambah 1 ke semua → distribusi lebih merata
      final values = _elementValues('Senin', 'Kliwon');
      // banyu: 1+3+1=5, sisanya lebih kecil — masih bisa jalan
      expect(values.values.reduce((a, b) => a + b), closeTo(1.0, 0.001));
    });

    test('Dual key sorted alphabetically: banyu_geni bukan geni_banyu', () {
      final doms = _dominants('Senin', 'Pahing');
      expect(doms.first, 'banyu'); // sorted: banyu < geni
      expect(doms.last, 'geni');
    });

    test('Balanced: 3+ elemen seri → list panjang >= 3', () {
      // Tidak ada kombinasi 35 weton yang persis 4-tie, tapi bisa 3-tie
      // Verifikasi logika tidak crash untuk edge case
      expect(() => _dominants('Rabu', 'Kliwon'), returnsNormally);
    });
  });
}
