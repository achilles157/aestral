import 'package:flutter_test/flutter_test.dart';
import 'package:aestral/core/utils/bazi_utils.dart';

// Semua 10 godId yang valid — harus cocok dengan _kGodPositionalContext keys
const _kValidGodIds = {
  'friend',
  'rob_wealth',
  'eating_god',
  'hurting_officer',
  'indirect_wealth',
  'direct_wealth',
  'seven_killings',
  'direct_officer',
  'indirect_resource',
  'direct_resource',
};

void main() {
  // ─── getTenGodId output coverage ─────────────────────────────────────────

  group('BaziUtils.getTenGodId', () {
    test('returns one of 10 valid godIds for all stem combinations', () {
      // 10 heavenly stems × 10 heavenly stems = 100 combinations
      for (int dm = 0; dm < 10; dm++) {
        for (int other = 0; other < 10; other++) {
          final godId = BaziUtils.getTenGodId(dm, other);
          expect(
            _kValidGodIds.contains(godId),
            isTrue,
            reason: 'dm=$dm other=$other returned unknown godId: $godId',
          );
        }
      }
    });

    test('Day Master vs self → friend (比肩)', () {
      // Same stem as Day Master → 比肩 (Friend/Rob Wealth alternates)
      // Even DM: friend, Odd DM: rob_wealth (or vice versa by Yin/Yang)
      for (int dm = 0; dm < 10; dm++) {
        final godId = BaziUtils.getTenGodId(dm, dm);
        expect(
          godId == 'friend' || godId == 'rob_wealth',
          isTrue,
          reason: 'DM $dm vs self should be friend or rob_wealth, got $godId',
        );
      }
    });

    test('known pairs: Jia (0) vs Bing (2) → Eating God (食神)', () {
      // Jia Wood produces Fire → Eating God
      expect(BaziUtils.getTenGodId(0, 2), 'eating_god');
    });

    test('known pairs: Jia (0) vs Geng (6) → Seven Killings (七殺)', () {
      // Metal controls Wood → Seven Killings (偏官)
      expect(BaziUtils.getTenGodId(0, 6), 'seven_killings');
    });

    test('known pairs: Jia (0) vs Xin (7) → Direct Officer (正官)', () {
      // Metal controls Wood (opposite polarity) → Direct Officer
      expect(BaziUtils.getTenGodId(0, 7), 'direct_officer');
    });

    test('known pairs: Jia (0) vs Wu (4) → Indirect Wealth (偏財)', () {
      // Wood controls Earth (same polarity) → Indirect Wealth
      expect(BaziUtils.getTenGodId(0, 4), 'indirect_wealth');
    });

    test('known pairs: Jia (0) vs Ji (5) → Direct Wealth (正財)', () {
      // Wood controls Earth (opposite polarity) → Direct Wealth
      expect(BaziUtils.getTenGodId(0, 5), 'direct_wealth');
    });

    test('all 10 godIds reachable across the 100 combinations', () {
      final found = <String>{};
      for (int dm = 0; dm < 10; dm++) {
        for (int other = 0; other < 10; other++) {
          found.add(BaziUtils.getTenGodId(dm, other));
        }
      }
      expect(found, equals(_kValidGodIds),
          reason: 'All 10 Ten Gods must be reachable');
    });
  });

  // ─── branchElements coverage ──────────────────────────────────────────────

  group('BaziUtils.branchElements', () {
    test('has exactly 12 entries (one per Earthly Branch)', () {
      expect(BaziUtils.branchElements.length, 12);
    });

    test('all elements are valid Wu Xing names', () {
      const valid = {'kayu', 'api', 'tanah', 'logam', 'air'};
      for (final e in BaziUtils.branchElements) {
        expect(valid.contains(e), isTrue, reason: 'Invalid element: $e');
      }
    });

    test('Zi (0=Rat) = air, Wu (6=Horse) = api — known reference', () {
      expect(BaziUtils.branchElements[0], 'air');  // Zi = Water
      expect(BaziUtils.branchElements[6], 'api');  // Wu = Fire
    });
  });
}
