# Dive 08: Luck Pillars (大運 Da Yun) — Verification Report

**Date:** 2026-07-16  
**Scope:** `lib/core/utils/bazi_utils.dart` lines 2657–2728, `lib/features/bazi/domain/bazi_chart.dart` lines 246–265, `lib/features/bazi/presentation/bazi_calculator_screen.dart` lines 241–249  

---

## 1. Direction Rule (陰陽順逆)

### Classical Rule
| Gender | Year Stem Polarity | Direction |
|--------|-------------------|-----------|
| Male   | Yang (甲丙戊庚壬)  | Forward 順運 |
| Male   | Yin  (乙丁己辛癸)  | Backward 逆運 |
| Female | Yang              | Backward 逆運 |
| Female | Yin               | Forward 順運 |

### Code (line 2705–2706)
```dart
final bool isYangYear = yearStemIndex % 2 == 0;
final bool isForward = isMale == isYangYear;
```

### Parity Mapping Verification
| Index | Stem | Parity | `index % 2` | Yang? | Classical | Code | Match? |
|-------|------|--------|-------------|-------|-----------|------|--------|
| 0 | 甲 Jia  | Yang | 0 (even) | ✅ | Yang | ✅ | ✅ |
| 1 | 乙 Yi   | Yin  | 1 (odd)  | ❌ | Yin  | ✅ | ✅ |
| 2 | 丙 Bing | Yang | 0 (even) | ✅ | Yang | ✅ | ✅ |
| 3 | 丁 Ding | Yin  | 1 (odd)  | ❌ | Yin  | ✅ | ✅ |
| 4 | 戊 Wu   | Yang | 0 (even) | ✅ | Yang | ✅ | ✅ |
| 5 | 己 Ji   | Yin  | 1 (odd)  | ❌ | Yin  | ✅ | ✅ |
| 6 | 庚 Geng | Yang | 0 (even) | ✅ | Yang | ✅ | ✅ |
| 7 | 辛 Xin  | Yin  | 1 (odd)  | ❌ | Yin  | ✅ | ✅ |
| 8 | 壬 Ren  | Yang | 0 (even) | ✅ | Yang | ✅ | ✅ |
| 9 | 癸 Gui  | Yin  | 1 (odd)  | ❌ | Yin  | ✅ | ✅ |

**Truth table for `isMale == isYangYear`:**

| isMale | isYangYear | isForward | Classical Direction |
|--------|-----------|-----------|-------------------|
| true   | true      | true      | Forward  ✓        |
| true   | false     | false     | Backward ✓        |
| false  | true      | false     | Backward ✓        |
| false  | false     | true      | Forward  ✓        |

### Verdict: ✅ CORRECT — All four classical cases produce the right direction.

---

## 2. Start Age Calculation (起運歲數)

### Classical Formula
```
Start Age = round(days from birth to nearest 節 ÷ 3)
```
- "三日一年" — 3 days = 1 year of Luck Pillar cycle
- Forward: count days to **NEXT** 節 (solar term)
- Backward: count days to **PREVIOUS** 節 (solar term)

### Code (lines 2667–2709)

#### `_daysToNearestSolarTerm(birth, isForward)`
```dart
static int _daysToNearestSolarTerm(DateTime birth, bool isForward) {
  final int birthJdn = dateToJdn(birth.year, birth.month, birth.day);
  final List<int> candidates = [];
  for (int yr = birth.year - 1; yr <= birth.year + 1; yr++) {
    for (int termIdx = 0; termIdx < 12; termIdx++) {
      final int month = termIdx + 1;
      final int day = _getJieDay(termIdx, yr);
      candidates.add(dateToJdn(yr, month, day));
    }
  }
  if (isForward) {
    final nexts = candidates.where((j) => j > birthJdn).toList()..sort();
    return nexts.isEmpty ? 30 : nexts.first - birthJdn;
  } else {
    final prevs = candidates.where((j) => j < birthJdn).toList()
      ..sort((a, b) => b.compareTo(a));
    return prevs.isEmpty ? 30 : birthJdn - prevs.first;
  }
}
```

**Analysis:**
- Builds a candidate list of all 12 節 × 3 years (birth year ± 1) = up to 36 candidates ✅
- Forward: picks smallest JDN strictly > birthJdn → nearest NEXT term ✅
- Backward: picks largest JDN strictly < birthJdn → nearest PREVIOUS term ✅
- Uses Julian Day Number arithmetic for correct day-counting across month/year boundaries ✅
- Fallback `30` if no candidate found (shouldn't happen in practice — safety net) ✅

#### Solar Term Source: `_getJieDay(termIdx, year)` (line 2339)
```dart
static int _getJieDay(int termIndex, int year) {
  if (year < 1924 || year > 2100) return _jieNominal[termIndex];
  return _jieDays[(year - 1924) * 12 + termIndex];
}
```
- Uses the **12 節 (Jié)** only, NOT the 24 full solar terms ✅
  - termIdx 0 = XiaoHan (小寒), 1 = LiChun (立春), 2 = JingZhe (驚蟄), ..., 11 = DaXue (大雪)
- `_jieDays` is a pre-computed lookup table (1924–2100, WIB UTC+7) generated via Meeus algorithm ✅
- Falls back to `_jieNominal` (fixed approximate dates) for years outside 1924–2100 ✅
- **Critically**: This correctly uses 節 boundaries, not 氣 boundaries. Classical Ba Zi uses only the 12 節 for Luck Pillar calculation. ✅

#### Start Age Formula (line 2709)
```dart
final int startAge = (days / 3).round().clamp(1, 99);
```
- Division by 3 → "三日一年" ✅
- `Math.round()` → standard rounding (≥0.5 rounds up) ✅
- `clamp(1, 99)` → handles edge case of born exactly ON a solar term (0 days → 0/3 = 0 → clamp to 1). Classical convention: born on a 節 → Luck Pillar starts at age 1. ✅
- **Note:** The code uses `days / 3` then `round()`. With integer division in Dart, `days` is `int`, so `days / 3` is `double`. This is correct.

### Verdict: ✅ CORRECT — Classical "三日一年" formula with proper 節-based day counting.

---

## 3. Luck Pillar Sequence (大運排法)

### Classical Rule
- Start from the **month pillar** position in the sexagenary cycle
- Forward: advance +1, +2, +3, ... through the 60-cycle
- Backward: retreat −1, −2, −3, ... through the 60-cycle
- Each pillar covers 10 years (standard)
- 8 pillars = 80 years of life

### Code (lines 2711–2724)
```dart
final int monthCycleIdx = _sexagenaryIndex(
  monthPillar.stemIndex,
  monthPillar.branchIndex,
);
final int step = isForward ? 1 : -1;

return List.generate(count, (i) {
  final int cycleIdx = ((monthCycleIdx + step * (i + 1)) % 60 + 60) % 60;
  return LuckPillar(
    pillar: _buildPillarFromCycleIndex(cycleIdx),
    startAge: startAge + i * 10,
  );
});
```

**Analysis:**
- `monthCycleIdx` is correctly derived from month pillar's stem+branch via `_sexagenaryIndex()` (Chinese Remainder Theorem) ✅
- `step = +1` (forward) or `−1` (backward) ✅
- For each pillar `i` (0-based): `cycleIdx = monthCycleIdx + step * (i + 1)`
  - Pillar 0 = month ±1, Pillar 1 = month ±2, etc. ✅
- Double-modulo `((... % 60) + 60) % 60` correctly handles negative values for backward direction ✅
- `_buildPillarFromCycleIndex` extracts stem = `cycleIdx % 10`, branch = `cycleIdx % 12` ✅
- `startAge = startAge + i * 10` → each pillar spans 10 years ✅
- Default `count = 8` → 8 pillars covering 80 years ✅

### Sexagenary Cycle Positioning Verification
The `_sexagenaryIndex` function (line 2366):
```dart
static int _sexagenaryIndex(int stemIndex, int branchIndex) {
  final int diff = ((branchIndex - stemIndex) % 12 + 12) % 12;
  final int k = (((diff ~/ 2) * 5) % 6 + 6) % 6;
  return (stemIndex + 10 * k) % 60;
}
```
This solves the CRT: find `p` where `p ≡ stemIndex (mod 10)` and `p ≡ branchIndex (mod 12)`. Since `gcd(10,12) = 2`, a solution exists only when `stemIndex ≡ branchIndex (mod 2)` — which is guaranteed by the construction of the sexagenary cycle. The algorithm is mathematically correct. ✅

### Verdict: ✅ CORRECT — Month-pillar-based advancement through the 60-cycle with proper modular arithmetic.

---

## 4. Data Model (`LuckPillar` class)

**Location:** `lib/features/bazi/domain/bazi_chart.dart` lines 246–265

```dart
class LuckPillar {
  final BaziPillar pillar;
  final int startAge;
  int get endAge => startAge + 9;
  const LuckPillar({required this.pillar, required this.startAge});
  // fromJson/toJson for serialization
}
```

- `startAge` is inclusive, `endAge` (computed) is `startAge + 9` → 10-year span ✅
- Properly serializable for API round-tripping ✅
- Used in UI: `bazi_calculator_screen.dart` line 321 checks `currentAge >= lp.startAge && currentAge <= lp.endAge` to highlight the active pillar ✅

### Verdict: ✅ CORRECT

---

## 5. Integration & UI Wiring

**Location:** `bazi_calculator_screen.dart` lines 241–249

```dart
if (_isMale != null) {
  final bool isYang = chart.yearPillar.stemIndex % 2 == 0;
  luckForward = _isMale! == isYang;
  luckPillars = BaziUtils.calculateLuckPillars(
    birthDate: _birthDate!,
    monthPillar: chart.monthPillar,
    yearStemIndex: chart.yearPillar.stemIndex,
    isMale: _isMale!,
  );
}
```

- Gender is required for Luck Pillar calculation; skips if unknown ✅
- The `isYang` / `isForward` check is duplicated in the UI (for display) but consistent with `calculateLuckPillars` internals ✅
- Parameters correctly passed: birth date, month pillar, year stem index, gender ✅

### Verdict: ✅ CORRECT

---

## 6. Edge Cases & Robustness

| Edge Case | Behavior | Assessment |
|-----------|----------|------------|
| Born exactly ON a 節 (0 days) | `startAge = 0 → clamp(1, 99) = 1` | ✅ Matches classical: age 1 start |
| Birth year < 1924 or > 2100 | `_getJieDay` falls back to `_jieNominal` (fixed dates) | ✅ Graceful degradation |
| No candidate in forward/backward direction | Returns 30 (fallback) | ⚠️ Extremely unlikely; could log warning |
| `days / 3` = exactly X.5 | `round()` rounds up (away from 0) | ✅ Standard rounding |
| Very large days (e.g., born Dec 31 near DaXue Jan 6) | Correctly finds nearest in ±1 year window | ✅ 3-year window sufficient |
| Gender not selected | `luckPillars = null`, UI hides section | ✅ Graceful |

---

## 7. Accuracy Considerations

1. **"三日一年" approximation**: The classical formula `days / 3` is a simplification. Some modern practitioners argue for lunar-year or more precise conversions. For a consumer app, this is standard and widely accepted.

2. **JDN-based day counting**: Using Julian Day Numbers ensures correct day-counting across month/year boundaries and leap years. This is more robust than naive `DateTime.difference()` which could have timezone issues.

3. **WIB timezone**: The `_jieDays` table is generated for WIB (UTC+7). This is appropriate for the Indonesia-focused app. Users in other timezones would need timezone adjustment, but this is by design.

4. **No fractional-year precision**: The classical formula doesn't account for time-of-day. Born at 23:59 on the day before a 節 would technically count as much closer to the 節 than the formula suggests. This is standard practice.

---

## 8. Test Coverage Gap

**No unit tests found for Luck Pillar calculation.** This is a significant gap given the complexity of the logic. Recommended test cases:
- Male + Yang year → forward direction
- Female + Yin year → forward direction
- Male + Yin year → backward direction
- Female + Yang year → backward direction
- Start age calculation with known birth dates near solar terms
- Pillar sequence from known month pillar
- Edge case: birth exactly on a 節

---

## Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Direction rule (陰陽順逆) | ✅ Correct | Parity mapping verified for all 10 stems |
| Solar term source (12 節) | ✅ Correct | Uses 節 only, not full 24 terms |
| Start age formula (三日一年) | ✅ Correct | JDN arithmetic, proper rounding, clamp to [1,99] |
| Pillar sequence (month-based) | ✅ Correct | CRT-based cycle index, proper modular arithmetic |
| Data model (LuckPillar) | ✅ Correct | 10-year spans, serializable |
| UI integration | ✅ Correct | Gender guard, consistent direction flag |
| Edge cases | ✅ Handled | Solar term boundary, year range fallback |
| Test coverage | ❌ Missing | No unit tests for this subsystem |

**Overall verdict: The Luck Pillar implementation is algorithmically correct and faithful to classical Ba Zi theory. The main concern is the absence of automated tests.**
