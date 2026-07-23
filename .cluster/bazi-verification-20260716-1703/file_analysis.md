# File Analysis — Ba Zi Verification

## 1. File Inventory

| File | Type | Size | Summary |
|---|---|---|---|
| `lib/core/utils/bazi_utils.dart` | Dart source | ~28KB | Full Ba Zi calculation engine: pillars, Wu Xing, Ten Gods, Luck Pillars, relations, TST |
| `aestral-backend/src/bazi.ts` | TypeScript source | ~32KB | Mirror of Dart engine + compatibility engine |
| `lib/features/bazi/domain/bazi_chart.dart` | Dart domain | ~8KB | Domain models for Ba Zi chart data |
| `assets/bazi/risetdatabazi.md` | Research doc | ~25KB | Comprehensive design doc: Day Masters, 10 Gods psychology, JSON templates |
| `assets/bazi/bazi-stems.json` | JSON data | ~2KB | 10 Heavenly Stems metadata |
| `assets/bazi/bazi-branches.json` | JSON data | ~2KB | 12 Earthly Branches metadata |
| `assets/bazi/10day-masters.json` | JSON data | TBD | 10 Day Master interpretations |
| `assets/bazi/10gods.json` | JSON data | TBD | 10 Gods interpretations |
| `assets/bazi/bazi-pillars.json` | JSON data | TBD | 60 sexagenary pillars data |
| `assets/bazi/dm-strength-levels.json` | JSON data | TBD | Day Master strength levels |
| `scripts/gen_solar_terms.js` | JS script | TBD | Solar term generation (Meeus algorithm) |

## 2. Per-File Extraction

### bazi_utils.dart (Dart Engine)
- **10 Heavenly Stems**: Correct sequence Jia→Gui with proper element/polarity mapping
- **12 Earthly Branches**: Correct sequence Zi→Hai with zodiac, element, hidden stems
- **60 Sexagenary Cycle**: Complete jia_zi through gui_hai
- **Solar Term Table**: 1924-2100 WIB, 12 jie per year (XiaoHan through DaXue), using Meeus algorithm
- **JDN Day Pillar**: Reference 1 Jan 2000 = Geng Chen (consistent with standard)
- **Year Pillar**: Li Chun boundary lookup table (not fixed Feb 4)
- **Month Pillar**: Tiger stem formula + solar term boundaries
- **Hour Pillar**: 12 two-hour blocks, Zi starts 23:00
- **True Solar Time**: longitude-based correction for Indonesian timezones
- **Wu Xing Balance**: 4 stems + 4 branch surfaces + Cang Gan hidden stems (16-17 chars)
- **Ten Gods**: 5-relationship × 2-polarity = 10 types, relative to Day Master
- **Day Master Strength**: 5-element × 12-month-branch matrix (旺相休囚死)
- **Favorable Elements**: Based on DM strength (strong→drain+control, weak→support+same)
- **Luck Pillars**: 8×10yr, forward/backward rule by gender + yang/yin year
- **Empty Branches**: 10-day-group formula
- **Branch Relations**: 六冲/六合/三合 detection
- **Nobleman Star**: 天乙貴人 lookup by Day Stem
- **Annual Pillar**: Current year pillar calculation

### bazi.ts (TypeScript Backend)
- Mirrors Dart engine exactly + adds:
- **Compatibility Engine**: 5-dimensional couples analysis (DM, Spouse Palace, Month, Zodiac, Elements)
- Same algorithms, same data tables, same naming conventions

### risetdatabazi.md (Research Document)
- **Core philosophy**: Transform Ba Zi from fatalistic to psychological/navigational tool
- **10 Day Masters**: Jungian archetype mapping with modern career/love interpretations
- **10 Gods**: Rebranded from scary traditional names to modern corporate competencies
- **JSON templates**: Structured data for Day Masters and Gods with ID terminology
- **Target audience**: Jakarta urban millennials/Gen Z

### bazi-stems.json
- Correct 10 stems: jia→gui with index/symbol/pinyin/element/polarity
- Note: Pinyin encoding issues (some Unicode characters broken)

### bazi-branches.json
- Correct 12 branches: zi→hai with hidden_stems arrays matching codebase
- Hidden stems verified consistent with codebase constants

## 3. Cross-File Mapping

### Overlaps
- Stems data: dart vs ts vs json → consistent
- Branches data: dart vs ts vs json → consistent  
- 60-cycle: dart vs ts → identical slugs
- Solar terms: dart vs ts → identical (same gen script)
- Ten Gods logic: dart vs ts → identical algorithm
- Strength matrix: dart vs ts → identical scores

### Gaps identified
1. No external authoritative Ba Zi source verification (codebase only self-referenced)
2. Solar term accuracy vs astronomical ephemeris not validated
3. Cang Gan (hidden stems) completeness for each branch not verified against classical texts
4. Ten Gods naming convention (friend/rob_wealth etc.) not compared to standard English translations
5. Day Master Strength matrix not compared to multiple systems (Zi Ping vs other schools)
6. The risetdatabazi.md interpretations may reflect a specific modernized approach - need traditional source verification
7. Nobleman Star lookup table completeness
8. Empty Branches formula correctness
9. Luck Pillar forward/backward rule edge cases
10. Bazi Compatibility scoring weights are arbitrary - not from classical texts

## 4. Theme List (for dimension slicing)
1. **Heavenly Stems & Earthly Branches** — core data correctness
2. **Solar Terms & Calendar Math** — astronomical accuracy
3. **Pillar Calculation Algorithms** — year/month/day/hour formulas
4. **Wu Xing & Cang Gan** — element mapping and hidden stems
5. **Ten Gods System** — naming, relationships, calculation
6. **Day Master Strength & Favorable Elements** — 旺衰 and 用神
7. **Luck Pillars (大運)** — direction rules, start age, sequence
8. **Branch Interactions** — 六冲/六合/三合/空亡/貴人
9. **Compatibility Engine** — scoring methodology and interpretations
10. **Interpretation Content** — Day Master & God descriptions vs classical
