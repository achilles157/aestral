#!/usr/bin/env node
/**
 * Generates compact solar term lookup table for Ba Zi calendar.
 * Algorithm: Jean Meeus "Astronomical Algorithms" Ch.25 (low-precision solar coords)
 * Accuracy: ±0.01° → ±15 min → reliable day-of-month determination.
 *
 * Output: flat JIE_DAYS array [177 years × 12 terms] storing actual day-of-month.
 * Handles any magnitude of drift (not just ±1) — correct for 1924–2100.
 */

// ─── Sun apparent longitude (Meeus Ch.25 low-precision) ──────────────────────

function sunApparentLon(jde) {
  const T  = (jde - 2451545.0) / 36525.0;
  const L0 = (280.46646 + 36000.76983 * T + 0.0003032 * T * T) % 360;
  const M  = (357.52911 + 35999.05029 * T - 0.0001537 * T * T) % 360;
  const Mr = M * Math.PI / 180;
  const C  = (1.914602 - 0.004817 * T - 0.000014 * T * T) * Math.sin(Mr)
           + (0.019993 - 0.000101 * T) * Math.sin(2 * Mr)
           + 0.000289 * Math.sin(3 * Mr);
  const lon = L0 + C;
  const omega = (125.04452 - 1934.136261 * T) * Math.PI / 180;
  const apparent = lon - 0.00569 - 0.00478 * Math.sin(omega);
  return ((apparent % 360) + 360) % 360;
}

// ─── JDE ↔ Gregorian ────────────────────────────────────────────────────────

function jdeToGregorian(jde) {
  const z = Math.floor(jde + 0.5);
  let a;
  if (z < 2299161) { a = z; }
  else {
    const alpha = Math.floor((z - 1867216.25) / 36524.25);
    a = z + 1 + alpha - Math.floor(alpha / 4);
  }
  const b = a + 1524;
  const c = Math.floor((b - 122.1) / 365.25);
  const d = Math.floor(365.25 * c);
  const e = Math.floor((b - d) / 30.6001);
  const day   = b - d - Math.floor(30.6001 * e);
  const month = e < 14 ? e - 1 : e - 13;
  const year  = month > 2 ? c - 4716 : c - 4715;
  return { year, month, day };
}

function gregorianToJde(year, month, day) {
  if (month <= 2) { year -= 1; month += 12; }
  const a = Math.floor(year / 100);
  const b = 2 - a + Math.floor(a / 4);
  return Math.floor(365.25 * (year + 4716))
       + Math.floor(30.6001 * (month + 1))
       + day + b - 1524.5;
}

// ─── Newton iteration: find JDE where sunApparentLon = targetLon ─────────────

function findSolarTermJDE(targetLon, startJde) {
  let jde = startJde;
  for (let i = 0; i < 50; i++) {
    let diff = sunApparentLon(jde) - targetLon;
    if (diff >  180) diff -= 360;
    if (diff < -180) diff += 360;
    const delta = diff * (365.25 / 360);
    jde -= delta;
    if (Math.abs(delta) < 0.00001) break; // ~1 second accuracy
  }
  return jde;
}

// ─── The 12 jié (节) month-start terms ───────────────────────────────────────
// Order matches getMonthBranchIndex return values:
//   0=XiaoHan(285°,Jan,branchOx=1 tail→Rat=0)
//   Wait — in getMonthBranchIndex the branch mapping is:
//   Jan1-5 = Rat(0), Jan6+ = Ox(1), Feb4+ = Tiger(2), ...
// So the 12 jié (節) that START each Ba Zi month are, in calendar order:
//   Xiao Han (Jan ~6)  → starts Ox month (branch 1)
//   Li Chun  (Feb ~4)  → starts Tiger month (branch 2) — also Ba Zi New Year
//   Jing Zhe (Mar ~6)  → starts Rabbit month (branch 3)
//   Qing Ming(Apr ~5)  → starts Dragon month (branch 4)
//   Li Xia   (May ~6)  → starts Snake month (branch 5)
//   Mang Zhong(Jun ~6) → starts Horse month (branch 6)
//   Xiao Shu (Jul ~7)  → starts Goat month (branch 7)
//   Li Qiu   (Aug ~7)  → starts Monkey month (branch 8)
//   Bai Lu   (Sep ~8)  → starts Rooster month (branch 9)
//   Han Lu   (Oct ~8)  → starts Dog month (branch 10)
//   Li Dong  (Nov ~7)  → starts Pig month (branch 11)
//   Da Xue   (Dec ~7)  → starts Rat month (branch 0, next cycle)

const JIE = [
  { name: 'XiaoHan',   lon: 285, nomMonth:  1, nomDay: 6 },  // idx 0
  { name: 'LiChun',    lon: 315, nomMonth:  2, nomDay: 4 },  // idx 1
  { name: 'JingZhe',   lon: 345, nomMonth:  3, nomDay: 6 },  // idx 2
  { name: 'QingMing',  lon:  15, nomMonth:  4, nomDay: 5 },  // idx 3
  { name: 'LiXia',     lon:  45, nomMonth:  5, nomDay: 6 },  // idx 4
  { name: 'MangZhong', lon:  75, nomMonth:  6, nomDay: 6 },  // idx 5
  { name: 'XiaoShu',   lon: 105, nomMonth:  7, nomDay: 7 },  // idx 6
  { name: 'LiQiu',     lon: 135, nomMonth:  8, nomDay: 7 },  // idx 7
  { name: 'BaiLu',     lon: 165, nomMonth:  9, nomDay: 8 },  // idx 8
  { name: 'HanLu',     lon: 195, nomMonth: 10, nomDay: 8 },  // idx 9
  { name: 'LiDong',    lon: 225, nomMonth: 11, nomDay: 7 },  // idx 10
  { name: 'DaXue',     lon: 255, nomMonth: 12, nomDay: 7 },  // idx 11
];

// ─── Compute all days 1924–2100 ───────────────────────────────────────────────

const START_YEAR = 1924;
const END_YEAR   = 2100;
const N_YEARS    = END_YEAR - START_YEAR + 1; // 177

// days[yearIdx][termIdx] = actual day-of-month
const days = Array.from({ length: N_YEARS }, () => new Array(12).fill(0));

for (let y = START_YEAR; y <= END_YEAR; y++) {
  const yi = y - START_YEAR;
  for (let ti = 0; ti < JIE.length; ti++) {
    const { lon, nomMonth, nomDay } = JIE[ti];
    // Start search from nominal date ±15 days window
    const startJde = gregorianToJde(y, nomMonth, nomDay);
    const jde      = findSolarTermJDE(lon, startJde);
    // Convert UT solar term moment to WIB local date (UTC+7 for Indonesia)
    const WIB_OFFSET = 7 / 24; // 7 hours in days
    const localJde   = jde + WIB_OFFSET;
    const date       = jdeToGregorian(localJde);
    days[yi][ti]     = date.day;
  }
}

// ─── Spot-check known reference dates ────────────────────────────────────────
// Source: Hong Kong Observatory + NAOJ solar term tables

const CHECKS = [
  // [year, termName, expectedDay]
  [2021,  'LiChun',   3], // Feb 3, 2021
  [2024,  'QingMing', 4], // Apr 4, 2024
  [2020,  'LiXia',    5], // May 5, 2020
  [2020,  'BaiLu',    7], // Sep 7, 2020
  [2000,  'LiChun',   4], // Feb 4, 2000
  [1990,  'LiChun',   4], // Feb 4, 1990
  [2025,  'LiChun',   3], // Feb 3, 2025
  [2023,  'QingMing', 5], // Apr 5, 2023
  [2022,  'QingMing', 5], // Apr 5, 2022
];

let checkOk = true;
for (const [year, name, expected] of CHECKS) {
  const ti   = JIE.findIndex(j => j.name === name);
  const got  = days[year - START_YEAR][ti];
  const status = got === expected ? '✓' : `✗ got ${got}`;
  if (got !== expected) checkOk = false;
  process.stderr.write(`  CHECK ${year} ${name}: expected ${expected} → ${status}\n`);
}
process.stderr.write(checkOk ? '✓ All spot-checks passed.\n' : '✗ Some checks FAILED.\n');

// ─── Output TypeScript ────────────────────────────────────────────────────────

// Flat array: index = (year - 1924) * 12 + termIndex, value = day-of-month
const flat = days.flat();

console.log(`// ─── Generated by scripts/gen_solar_terms.js — DO NOT EDIT ───────────────────`);
console.log(`// Solar term day-of-month for 1924–2100, 12 jié terms per year.`);
console.log(`// Access: JIE_DAYS[(year - 1924) * 12 + termIndex]`);
console.log(`// termIndex: 0=XiaoHan 1=LiChun 2=JingZhe 3=QingMing 4=LiXia 5=MangZhong`);
console.log(`//            6=XiaoShu 7=LiQiu  8=BaiLu   9=HanLu   10=LiDong 11=DaXue`);
console.log(``);

// TypeScript block
console.log(`// ── TypeScript (bazi.ts) ─────────────────────────────────────────────────────`);
console.log(`const JIE_DAYS: readonly number[] = [`);
for (let yi = 0; yi < N_YEARS; yi++) {
  const row   = days[yi];
  const year  = START_YEAR + yi;
  console.log(`  ${row.join(',')}, // ${year}`);
}
console.log(`];`);
console.log(``);
console.log(`/** Returns actual day-of-month for jié term [termIndex] in [year]. */`);
console.log(`function getJieDay(termIndex: number, year: number): number {`);
console.log(`  if (year < ${START_YEAR} || year > ${END_YEAR}) {`);
console.log(`    // Fallback for out-of-range years — use nominal`);
console.log(`    const NOM = [6,4,6,5,6,6,7,7,8,8,7,7];`);
console.log(`    return NOM[termIndex];`);
console.log(`  }`);
console.log(`  return JIE_DAYS[(year - ${START_YEAR}) * 12 + termIndex];`);
console.log(`}`);
console.log(``);

// Dart block
console.log(`// ── Dart (bazi_utils.dart) ───────────────────────────────────────────────────`);
console.log(`  static const List<int> _jieDays = [`);
for (let yi = 0; yi < N_YEARS; yi++) {
  const row  = days[yi];
  const year = START_YEAR + yi;
  console.log(`    ${row.join(',')}, // ${year}`);
}
console.log(`  ];`);
console.log(``);
console.log(`  static const List<int> _jieNominal = [6,4,6,5,6,6,7,7,8,8,7,7];`);
console.log(``);
console.log(`  /// Returns actual day-of-month for jié term [termIndex] in [year].`);
console.log(`  static int _getJieDay(int termIndex, int year) {`);
console.log(`    if (year < ${START_YEAR} || year > ${END_YEAR}) return _jieNominal[termIndex];`);
console.log(`    return _jieDays[(year - ${START_YEAR}) * 12 + termIndex];`);
console.log(`  }`);
