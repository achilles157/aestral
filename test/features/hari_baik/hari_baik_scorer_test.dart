import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/features/hari_baik/services/hari_baik_scorer.dart';

Map<String, dynamic> _day({
  String label = 'stabil',
  bool dinoWas = false,
  bool baziClash = false,
  bool wukuRawan = false,
  bool mangsaRawan = false,
  bool baziHarmony = false,
  bool baziYongShen = false,
  String date = '2099-01-01',
}) {
  return {
    'date': date,
    'is_dino_was': dinoWas,
    'is_bazi_clash': baziClash,
    'is_wuku_rawan': wukuRawan,
    'is_mangsa_rawan': mangsaRawan,
    'is_bazi_harmony': baziHarmony,
    'is_bazi_yong_shen': baziYongShen,
    'pancasuda': {'planner_label': label},
  };
}

void main() {
  group('HariBaikScorer', () {
    test('stabil polos lolos threshold (skor >= 30)', () {
      final s = HariBaikScorer.score(_day(label: 'stabil'), 'umum');
      expect(s, greaterThanOrEqualTo(30));
    });

    test('stabil + wuku rawan tetap di bawah threshold', () {
      final s = HariBaikScorer.score(
        _day(label: 'stabil', wukuRawan: true),
        'umum',
      );
      expect(s, lessThan(30));
    });

    test('ekspansi polos tetap lebih tinggi dari stabil polos', () {
      final ekspansi = HariBaikScorer.score(_day(label: 'ekspansi'), 'umum');
      final stabil = HariBaikScorer.score(_day(label: 'stabil'), 'umum');
      expect(ekspansi, greaterThan(stabil));
    });

    test('filter menampilkan hari stabil polos', () {
      final days = [_day(label: 'stabil')];
      final results = HariBaikScorer.filter(days, 'umum');
      expect(results, isNotEmpty);
    });

    test('filter menyembunyikan hari stabil + wuku rawan', () {
      final days = [_day(label: 'stabil', wukuRawan: true)];
      final results = HariBaikScorer.filter(days, 'umum');
      expect(results, isEmpty);
    });

    test('filter selalu menyembunyikan dino was', () {
      final days = [_day(label: 'ekspansi', dinoWas: true)];
      final results = HariBaikScorer.filter(days, 'umum');
      expect(results, isEmpty);
    });
  });
}
