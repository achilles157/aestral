# Dive 07 — Day Master Strength (旺衰) & Favorable Elements (用神/忌神) Verification

**Date:** 2026-07-16 17:25 GMT+7
**Verified sources:**
- `lib/core/utils/bazi_utils.dart` (lines ~2726–2798: `_dmStrengthMatrix`, `_dmStrengthLabels`, `getDayMasterStrength`, `getFavorableElements`)
- `aestral-backend/src/bazi.ts` (lines ~70–84: `DM_STRENGTH_MATRIX`, `DM_STRENGTH_LABELS`; lines ~437–451: `getFavorableElements`)
- Call sites: `bazi_utils.dart` ~2590, `bazi.ts` ~787

**Verdict: ✅ PASS — matrix, labels, and yong/ji shen logic are classically correct in both implementations, with documented (acceptable) simplifications.**

---

## 1. Classical Rule Basis (旺相休囚死)

Strength of Day Master element **E** relative to month-branch (月令) season element **M**:

| Relation | State | Score | Label |
|---|---|---|---|
| E == M (当令) | 旺 | 4 | Sangat Kuat |
| M generates E (令生者) | 相 | 3 | Kuat |
| E generates M (生令者) | 休 | 2 | Sedang |
| E controls M (克令者) | 囚 | 1 | Lemah |
| M controls E (令克者) | 死 | 0 | Sangat Lemah |

The code's documented rule (bazi_utils.dart:2731–2734) matches this exactly. Label ordering 旺>相>休>囚>死 → Sangat Kuat > Kuat > Sedang > Lemah > Sangat Lemah is the conventional strength ranking. ✅

Sanity check against the canonical spring example (春: 木旺、火相、水休、金囚、土死):
- kayu[Yin]=4 旺 ✓, api[Yin]=3 相 ✓, air[Yin]=2 休 ✓, logam[Yin]=1 囚 ✓, tanah[Yin]=0 死 ✓

## 2. Full Matrix Verification (60 cells)

Branch surface elements Zi→Hai: `air, tanah, kayu, kayu, tanah, api, api, tanah, logam, logam, tanah, air` ✓ (correct ZiHai mapping)

### kayu (Wood DM): `[3, 1, 4, 4, 1, 2, 2, 1, 0, 0, 1, 3]`
All 12 cells verified ✓ (Water branches → 相=3; Wood → 旺=4; Earth → 囚=1 because **Wood controls Earth**, 克令者囚; Fire → 休=2; Metal → 死=0 because Metal controls Wood, 令克者死)

### api (Fire DM): `[0, 2, 3, 3, 2, 4, 4, 2, 1, 1, 2, 0]`
All 12 cells verified ✓ (Water → 死=0; Earth → 休=2; Wood → 相=3; Fire → 旺=4; Metal → 囚=1)

### tanah (Earth DM): `[1, 4, 0, 0, 4, 3, 3, 4, 2, 2, 4, 1]`
All 12 cells verified ✓ (Water → 囚=1, Earth controls Water; Earth → 旺=4; Wood → 死=0, Wood controls Earth; Fire → 相=3; Metal → 休=2)

### logam (Metal DM): `[2, 3, 1, 1, 3, 0, 0, 3, 4, 4, 3, 2]`
All 12 cells verified ✓ (Water → 休=2; Earth → 相=3; Wood → 囚=1; Fire → 死=0; Metal → 旺=4)

### air (Water DM): `[4, 0, 2, 2, 0, 1, 1, 0, 3, 3, 0, 4]`
All 12 cells verified ✓ (Water → 旺=4; Earth → 死=0, Earth controls Water; Wood → 休=2; Fire → 囚=1; Metal → 相=3)

**60/60 cells correct. ✅**

### Cross-implementation parity
Dart `_dmStrengthMatrix` and TS `DM_STRENGTH_MATRIX` are **byte-identical** row by row, and both use the same label arrays. No frontend/backend drift. ✅

### Call-site correctness
Both implementations call `getDayMasterStrength(monthPillar.branchIndex, dayPillar.element)`:
- `monthPillar.branchIndex` → correct use of 月令 ✓
- `dayPillar.element` → confirmed via `BaziPillar` docs to be the **Heavenly Stem's** element, i.e., the true Day Master element (not the branch element) ✓
- In-code verified example holds: Api DM + Wei(7) → `api[7]=2` → 'Sedang' (休) ✓

## 3. Favorable Elements (用神/忌神) Verification

Prerequisite cycles verified: `_generates` (kayu→api→tanah→logam→air→kayu ✓ 相生) and `_controls` (kayu→tanah→air→api→logam→kayu ✓ 相克) are both correct.

| Strength | yongShen 用神 | jiShen 忌神 | Classical check |
|---|---|---|---|
| Sangat Kuat / Kuat | 我生 (output) + 克我 (officer) | 生我 (resource) + 比劫 (companion) | ✅ Strong DM drained & controlled |
| Sangat Lemah / Lemah | 生我 (resource) + 比劫 (companion) | 克我 (officer) + 我生 (output) | ✅ Weak DM supported |
| Sedang | 生我 + 比劫 | 克我 only | ✅ Reasonable support-leaning simplification |

Dart and TS implementations are logically identical. ✅

## 4. Corrections to the Verification Brief (task text, not code)

Two justifications in the assignment brief were phrased backward, though the **scores stated were correct**:
- Kayu DM at Chou/Chen/Wei/Xu = 1 (囚): the reason is **Wood controls Earth** (我克/克令者囚), *not* "Earth controls Wood." Earth cannot control Wood — Wood controls Earth in the 相克 cycle.
- The "Metal controls Wood → 死" cells (Shen/You = 0) are correctly phrased (令克者死).

The code itself documents the rule correctly and needs no change.

## 5. Known Simplifications (documented, acceptable for an app)

1. **Month-branch-only strength assessment.** Real 旺衰 analysis weighs the whole chart: hidden stems (藏干) in all branches, stem transparency (透干), rooting (通根), and counts of supporters vs. drainers. Month branch is the single most important factor (~40–50% weight in most weighting schemes), so this is the right primary simplification.
2. **No combination effects.** 六合/三合/三会 transformations can change the effective element of branches and shift strength. The codebase computes harmonies/triads elsewhere (`BaziHarmony`, `BaziTriad`) but does not feed them back into DM strength. Known gap.
3. **Earth-month nuance (土旺四季).** Classical doctrine holds Earth is fully 旺 only in the final ~18 days of each of the four Earth months (辰戌丑未); early portions carry the previous season's qi (余气). The code treats the entire Earth month as 土旺 (tanah=4). Standard app-level simplification.
4. **Wealth element (我克) treated as neutral.** Classically, strong DM also favors wealth (财) as yongShen, and weak DM also fears wealth as jiShen. The code omits 我克 from both lists, leaving it neutral in all cases. Consistent and conservative, but a slight deviation from full classical prescription.
5. **Sedang case simplified** to support-leaning with a single jiShen. True balanced charts require 调候 (climate adjustment) or 通关 (mediation) analysis. Acceptable.

## 6. Summary

| Item | Status |
|---|---|
| 旺相休囚死 rule implementation | ✅ Correct |
| 5×12 strength matrix (60 cells) | ✅ All correct |
| Score→label mapping (死→Sangat Lemah … 旺→Sangat Kuat) | ✅ Correct |
| Dart ↔ TS matrix parity | ✅ Identical |
| Call site (month branch + day-stem element) | ✅ Correct |
| 相生/相克 cycles | ✅ Correct |
| Strong DM yong/ji shen | ✅ Classical |
| Weak DM yong/ji shen | ✅ Classical |
| Sedang yong/ji shen | ✅ Acceptable simplification |
| Combination effects on strength | ⚠️ Not modeled (documented gap) |
| Whole-chart weighting | ⚠️ Not modeled (documented gap) |

**No code changes required.** Optional future enhancements: feed 六合/三合 results into strength scoring; add 余气 handling for Earth months; include wealth element in strong/weak prescriptions.
