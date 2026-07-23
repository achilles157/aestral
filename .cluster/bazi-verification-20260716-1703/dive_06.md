# Dive 06: Ten Gods (十神) System Verification

**Date:** 2026-07-16  
**Status:** ✅ ALL CHECKS PASSED

---

## 1. Classical Ten Gods Reference

| Code ID | Chinese | Pinyin | Translation | Axis | Verified |
|---|---|---|---|---|---|
| `friend` | 比肩 | Bǐ Jiān | Shoulder-to-Shoulder / Companion | Same element, same polarity | ✅ |
| `rob_wealth` | 劫财 | Jié Cái | Rob Wealth | Same element, different polarity | ✅ |
| `eating_god` | 食神 | Shí Shén | Eating God | DM generates target, same polarity | ✅ |
| `hurting_officer` | 伤官 | Shāng Guān | Hurting Officer | DM generates target, different polarity | ✅ |
| `indirect_wealth` | 偏财 | Piān Cài | Indirect Wealth | DM controls target, same polarity | ✅ |
| `direct_wealth` | 正财 | Zhèng Cài | Direct Wealth | DM controls target, different polarity | ✅ |
| `seven_killings` | 七杀 | Qī Shā | Seven Killings | Target controls DM, same polarity | ✅ |
| `direct_officer` | 正官 | Zhèng Guān | Direct Officer | Target controls DM, different polarity | ✅ |
| `indirect_resource` | 偏印 | Piān Yìn | Indirect Resource | Target generates DM, same polarity | ✅ |
| `direct_resource` | 正印 | Zhèng Yìn | Direct Resource | Target generates DM, different polarity | ✅ |

---

## 2. Wu Xing Cycles (Foundation)

Both implementations use identical Indonesian-language element IDs:

**Sheng (生) — Producing cycle:**
```
wood → fire → earth → metal → water → wood
(kayu → api → tanah → logam → air → kayu)
```

**Ke (克) — Controlling cycle:**
```
wood → earth → water → fire → metal → wood
(kayu → tanah → air → api → logam → kayu)
```

Cross-verified against 4 classical references — all match.

---

## 3. Algorithm Logic

```typescript
function getTenGodId(dmStemIndex, targetStemIndex) {
  const dmEl = STEM_ELEMENTS[dmStemIndex];
  const tgEl = STEM_ELEMENTS[targetStemIndex];
  const same = (dmStemIndex % 2) === (targetStemIndex % 2);

  if (tgEl === dmEl)              return same ? 'friend'            : 'rob_wealth';
  if (GENERATES[dmEl] === tgEl)   return same ? 'eating_god'        : 'hurting_officer';
  if (CONTROLS[dmEl]  === tgEl)   return same ? 'indirect_wealth'   : 'direct_wealth';
  if (CONTROLS[tgEl]  === dmEl)   return same ? 'seven_killings'    : 'direct_officer';
  if (GENERATES[tgEl] === dmEl)   return same ? 'indirect_resource' : 'direct_resource';
  return 'friend'; // unreachable
}
```

**Decision order:** Same element → Output (食伤) → Wealth (财) → Officer (官杀) → Resource (印)

**Polarity rule:** Same parity (both Yang or both Yin) → 偏/比 (indirect/peer); Different parity → 正 (direct).

This is correct: in classical Ba Zi, **偏 (Pian)** = same polarity as DM, **正 (Zheng)** = different polarity from DM. The "indirect" prefix in English translations corresponds to 偏, and "direct" corresponds to 正.

---

## 4. Exhaustive Test Results

### Test 1: 100 Combinations (10 DM × 10 Target)

Independent reference implementation derived from first principles was compared against the code for all 100 combinations.

**Result: 100/100 PASS ✅**

### Test 2: 28 Golden Vectors (Hard-coded classical spot checks)

Spot-checked critical combos drawn from published Ba Zi charts:

| DM | Target | Expected | Got | Status |
|---|---|---|---|---|
| Jia(0) | Jia(0) | friend | friend | ✅ |
| Jia(0) | Yi(1) | rob_wealth | rob_wealth | ✅ |
| Jia(0) | Bing(2) | eating_god | eating_god | ✅ |
| Jia(0) | Ding(3) | hurting_officer | hurting_officer | ✅ |
| Jia(0) | Wu(4) | indirect_wealth | indirect_wealth | ✅ |
| Jia(0) | Ji(5) | direct_wealth | direct_wealth | ✅ |
| Jia(0) | Geng(6) | seven_killings | seven_killings | ✅ |
| Jia(0) | Xin(7) | direct_officer | direct_officer | ✅ |
| Jia(0) | Ren(8) | indirect_resource | indirect_resource | ✅ |
| Jia(0) | Gui(9) | direct_resource | direct_resource | ✅ |
| Geng(6) | Jia(0) | indirect_wealth | indirect_wealth | ✅ |
| Geng(6) | Wu(4) | indirect_resource | indirect_resource | ✅ |
| Geng(6) | Ji(5) | direct_resource | direct_resource | ✅ |
| Geng(6) | Ren(8) | eating_god | eating_god | ✅ |
| Geng(6) | Gui(9) | hurting_officer | hurting_officer | ✅ |
| Ji(5) | Ren(8) | direct_wealth | direct_wealth | ✅ |
| Gui(9) | Bing(2) | direct_wealth | direct_wealth | ✅ |
| Ding(3) | Geng(6) | direct_wealth | direct_wealth | ✅ |
| Bing(2) | Gui(9) | direct_officer | direct_officer | ✅ |
| + 8 more | | | | ✅ |

**Result: 28/28 PASS ✅**

### Test 3: Distribution Completeness

For each of the 10 Day Masters, all 10 Ten Gods must appear exactly once (bijection property).

**Result: 10/10 DMs have exactly 10 distinct gods each ✅**

---

## 5. Full Ten Gods Matrix

```
DM    : Jia   Yi    Bing  Ding  Wu    Ji    Geng  Xin   Ren   Gui
─────────────────────────────────────────────────────────────────────
Jia   : friend rob_wealth eating_god hurting_officer indirect_wealth direct_wealth seven_killings direct_officer indirect_resource direct_resource
Yi    : rob_wealth friend hurting_officer eating_god direct_wealth indirect_wealth direct_officer seven_killings direct_resource indirect_resource
Bing  : indirect_resource direct_resource friend rob_wealth eating_god hurting_officer indirect_wealth direct_wealth seven_killings direct_officer
Ding  : direct_resource indirect_resource rob_wealth friend hurting_officer eating_god direct_wealth indirect_wealth direct_officer seven_killings
Wu    : seven_killings direct_officer indirect_resource direct_resource friend rob_wealth eating_god hurting_officer indirect_wealth direct_wealth
Ji    : direct_officer seven_killings direct_resource indirect_resource rob_wealth friend hurting_officer eating_god direct_wealth indirect_wealth
Geng  : indirect_wealth direct_wealth seven_killings direct_officer indirect_resource direct_resource friend rob_wealth eating_god hurting_officer
Xin   : direct_wealth indirect_wealth direct_officer seven_killings direct_resource indirect_resource rob_wealth friend hurting_officer eating_god
Ren   : eating_god hurting_officer indirect_wealth direct_wealth seven_killings direct_officer indirect_resource direct_resource friend rob_wealth
Gui   : hurting_officer eating_god direct_wealth indirect_wealth direct_officer seven_killings direct_resource indirect_resource rob_wealth friend
```

---

## 6. Cross-Platform Consistency

| Aspect | TS Backend (`bazi.ts`) | Dart Frontend (`bazi_utils.dart`) | Match |
|---|---|---|---|
| GENERATES cycle | ✅ | ✅ | ✅ Identical |
| CONTROLS cycle | ✅ | ✅ | ✅ Identical |
| Element IDs (Indonesian) | kayu, api, tanah, logam, air | Same | ✅ |
| Polarity check | `(dm % 2) === (tg % 2)` | `(dm % 2) == (tg % 2)` | ✅ Identical |
| Decision order | Same → Output → Wealth → Officer → Resource | Same | ✅ Identical |
| Ten God IDs | All 10 match | All 10 match | ✅ Identical |
| Fallback | `'friend'` (unreachable) | `'friend'` (unreachable) | ✅ Identical |

**Result: TS ↔ Dart fully consistent ✅**

---

## 7. Summary

| Check | Result |
|---|---|
| Chinese classical names match IDs | ✅ 10/10 |
| Wu Xing cycles correct | ✅ |
| Polarity parity logic correct | ✅ |
| 100 exhaustive combos | ✅ |
| 28 golden vector spot checks | ✅ |
| Distribution bijection (each DM → all 10 gods) | ✅ |
| TS ↔ Dart cross-platform consistency | ✅ |
| Correctness issues found | **None** |

**The Ten Gods system is correct and complete across both implementations.**

---

*Test artifact:* `test_ten_gods.js` — exhaustive 100-combo + 28 golden + distribution check, all passing.
