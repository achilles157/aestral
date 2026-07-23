## Dimension 01: Heavenly Stems & Earthly Branches

### Current State
- All 10 Heavenly Stems (天干) verified correct — sequence, Chinese characters, elements, and polarity ✅
- All 12 Earthly Branches (地支) verified correct — sequence, Chinese characters, zodiac animals, surface elements, and polarity ✅
- Full 60 Sexagenary Cycle (六十甲子) verified correct — completeness, uniqueness, parity, and sequence ✅
- Parity constraint (Yang-Yang / Yin-Yin only) holds for all 60 combinations ✅
- No discrepancies found between codebase and classical Ba Zi standards

### Key Evidence

| Data point | Verification | Status | Notes |
|---|---|---|---|
| Stem sequence | 甲乙丙丁戊己庚辛壬癸 — matches classical standard exactly | ✅ | All 10 stems in correct order |
| Stem Chinese characters | `stemSymbols`: 甲乙丙丁戊己庚辛壬癸 | ✅ | Unicode CJK characters correct |
| Stem elements | kayu,kayu,api,api,tanah,tanah,logam,logam,air,air — Wood,Wood,Fire,Fire,Earth,Earth,Metal,Metal,Water,Water | ✅ | Pairs correctly: 甲乙=Wood, 丙丁=Fire, 戊己=Earth, 庚辛=Metal, 壬癸=Water |
| Stem polarity (Yang/Yin) | stemNamesId shows alternating Yang/Yin starting with Yang | ✅ | Odd indices (0,2,4,6,8)=Yang, even (1,3,5,7,9)=Yin — correct |
| Branch sequence | 子丑寅卯辰巳午未申酉戌亥 — matches classical standard exactly | ✅ | All 12 branches in correct order |
| Branch Chinese characters | `branchSymbols`: 子丑寅卯辰巳午未申酉戌亥 | ✅ | Correct Unicode CJK characters |
| Branch zodiac animals | Rat,Ox,Tiger,Rabbit,Dragon,Snake,Horse,Goat,Monkey,Rooster,Dog,Pig | ✅ | Maps correctly to 子 through 亥 |
| Branch surface elements | air,tanah,kayu,kayu,tanah,api,api,tanah,logam,logam,tanah,air | ✅ | 子=Water, 丑=Earth, 寅=Wood, 卯=Wood, 辰=Earth, 巳=Fire, 午=Fire, 未=Earth, 申=Metal, 酉=Metal, 戌=Earth, 亥=Water |
| Branch polarity | Alternates starting with Yang (子) | ✅ | Odd indices (0,2,4,6,8,10)=Yang, even (1,3,5,7,9,11)=Yin |
| Sexagenary cycle completeness | 60 unique entries | ✅ | Exact LCM(10,12)=60 entries |
| Sexagenary sequence | jia_zi through gui_hai, stem+1 mod 10 / branch+1 mod 12 stepping | ✅ | Programmatically verified: no sequence gaps |
| Cycle start/end | Starts 甲子(0,0), ends 癸亥(9,11) | ✅ | Standard cycle boundaries |
| Parity constraint | stemIdx % 2 == branchIdx % 2 for all 60 pairs | ✅ | No Yang-Yin or Yin-Yang mismatches — verified programmatically |
| Cang Gan (hidden stems) | 12 branches each have 1–3 hidden stems | ✅ | Cross-checked: zi→gui, chou→ji/gui/xin, yin→jia/bing/wu, etc. match standard 藏干 tables |
| Six Harmony (六合) | 6 pairs: 子丑, 寅亥, 卯戌, 辰酉, 巳申, 午未 | ✅ | Standard 六合 pairs with correct result elements |
| Three Harmony (三合) | 4 triads: 申子辰→Water, 亥卯未→Wood, 寅午戌→Fire, 巳酉丑→Metal | ✅ | Standard 三合局 |
| Six Clash (六冲) | Branch distance == 6 | ✅ | Standard 六冲 rule |
| Nobleman (天乙貴人) | Per-stem lookup table for 2 branches each | ✅ | Standard Zi Ping assignment |

### Tensions & Issues

**None found.** All foundational Ba Zi data structures in `bazi_utils.dart` are accurate against classical Chinese astrology standards:

1. **Stems**: Perfect match — all 10 Heavenly Stems with correct sequence, Chinese characters (甲乙丙丁戊己庚辛壬癸), paired elements (Wood/Fire/Earth/Metal/Water × 2), and alternating Yang→Yin polarity.

2. **Branches**: Perfect match — all 12 Earthly Branches with correct sequence, Chinese characters (子丑寅卯辰巳午未申酉戌亥), zodiac animals (Rat through Pig), surface elements (Water/Earth/Wood/Wood/Earth/Fire/Fire/Earth/Metal/Metal/Earth/Water), and alternating polarity.

3. **Sexagenary Cycle**: Programmatically verified — all 60 entries are unique, correctly sequenced (stem advances +1 mod 10, branch advances +1 mod 12), starts at 甲子 and ends at 癸亥. Parity constraint satisfied: every pair is Yang-Yang or Yin-Yin (no mixed-polarity combinations exist, as required by the CRT construction).

4. **Derived structures**: Cang Gan, Six Harmony, Three Harmony, Six Clash, and Nobleman tables all conform to standard references.

### Source
- `lib/core/utils/bazi_utils.dart` — full read, all arrays extracted and cross-checked
- Verification script: programmatic parity + sequence + uniqueness check (all passed)
