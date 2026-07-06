/**
 * Ba Zi (八字) Four Pillars of Destiny calculation engine.
 *
 * Pure TypeScript — zero external dependencies.
 * Follows the same architectural pattern as weton.ts.
 *
 * Algorithms:
 * - Year Pillar  : Li Chun (立春 ~Feb 4) solar boundary + 60-cycle
 * - Month Pillar : 12 Major Solar Terms (节 jié), approximate ±1 day
 * - Day Pillar   : JDN-based (reference: 1 Jan 2000 = Geng Chen)
 * - Hour Pillar  : 2-hour shi (時) blocks, Zi (子) starts at 23:00
 * - True Solar Time: longitude correction for Indonesia (WIB/WITA/WIT)
 */

import { dateToJdn } from './weton';

// ─── Heavenly Stems 天干 ──────────────────────────────────────────────────

const STEM_IDS: readonly string[] = [
	'jia', 'yi', 'bing', 'ding', 'wu', 'ji', 'geng', 'xin', 'ren', 'gui',
];

const STEM_SYMBOLS: readonly string[] = [
	'甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
];

const STEM_NAMES_ID: readonly string[] = [
	'Kayu Yang', 'Kayu Yin', 'Api Yang', 'Api Yin', 'Tanah Yang',
	'Tanah Yin', 'Logam Yang', 'Logam Yin', 'Air Yang', 'Air Yin',
];

const STEM_ELEMENTS: readonly string[] = [
	'kayu', 'kayu', 'api', 'api', 'tanah', 'tanah', 'logam', 'logam', 'air', 'air',
];

// ─── Earthly Branches 地支 ────────────────────────────────────────────────

const BRANCH_IDS: readonly string[] = [
	'zi', 'chou', 'yin', 'mao', 'chen', 'si', 'wu', 'wei', 'shen', 'you', 'xu', 'hai',
];

const BRANCH_SYMBOLS: readonly string[] = [
	'子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

const BRANCH_ZODIACS_ID: readonly string[] = [
	'Tikus', 'Kerbau', 'Harimau', 'Kelinci', 'Naga', 'Ular',
	'Kuda', 'Kambing', 'Monyet', 'Ayam', 'Anjing', 'Babi',
];

const BRANCH_ELEMENTS: readonly string[] = [
	'air', 'tanah', 'kayu', 'kayu', 'tanah', 'api',
	'api', 'tanah', 'logam', 'logam', 'tanah', 'air',
];

// ─── 60-Pillar Sexagenary Cycle 六十甲子 ──────────────────────────────────
// Each step increments both stem (+1 mod 10) and branch (+1 mod 12).
// Starts at Jia Zi (index 0), ends at Gui Hai (index 59).
// Matches the slug IDs used in assets/bazi/bazi-pillars.json.

const SEXAGENARY_SLUGS: readonly string[] = [
	'jia_zi',   'yi_chou',   'bing_yin',  'ding_mao',  'wu_chen',
	'ji_si',    'geng_wu',   'xin_wei',   'ren_shen',  'gui_you',
	'jia_xu',   'yi_hai',    'bing_zi',   'ding_chou', 'wu_yin',
	'ji_mao',   'geng_chen', 'xin_si',    'ren_wu',    'gui_wei',
	'jia_shen', 'yi_you',    'bing_xu',   'ding_hai',  'wu_zi',
	'ji_chou',  'geng_yin',  'xin_mao',   'ren_chen',  'gui_si',
	'jia_wu',   'yi_wei',    'bing_shen', 'ding_you',  'wu_xu',
	'ji_hai',   'geng_zi',   'xin_chou',  'ren_yin',   'gui_mao',
	'jia_chen', 'yi_si',     'bing_wu',   'ding_wei',  'wu_shen',
	'ji_you',   'geng_xu',   'xin_hai',   'ren_zi',    'gui_chou',
	'jia_yin',  'yi_mao',    'bing_chen', 'ding_si',   'wu_wu',
	'ji_wei',   'geng_shen', 'xin_you',   'ren_xu',    'gui_hai',
];

// ─── Types ────────────────────────────────────────────────────────────────

export interface BaziPillar {
	/** Sexagenary slug matching bazi-pillars.json id, e.g. "geng_chen" */
	id: string;
	stemId: string;
	branchId: string;
	stemIndex: number;
	branchIndex: number;
	stemSymbol: string;
	branchSymbol: string;
	stemNameId: string;
	branchZodiacId: string;
	/** Dominant element of the Heavenly Stem (for Flutter color-mapping) */
	element: string;
}

export interface WuXingBalance {
	kayu: number;
	api: number;
	tanah: number;
	logam: number;
	air: number;
}

export interface BaziChartResult {
	yearPillar: BaziPillar;
	monthPillar: BaziPillar;
	dayPillar: BaziPillar;
	/** Null when birth hour is unknown */
	hourPillar: BaziPillar | null;
	/** The Day Stem id — the "self" of the chart */
	dayMasterId: string;
	dayMasterElement: string;
	wuXingBalance: WuXingBalance;
	/** Human-readable TST correction note, null if no longitude provided */
	trueSolarTimeNote: string | null;
	/** TST-adjusted hour used for Hour Pillar, null if birthHour not provided */
	adjustedHour: number | null;
}

// ─── Core Utility ─────────────────────────────────────────────────────────

/**
 * Returns 0-indexed position (0–59) in the 60-pillar sexagenary cycle
 * for a given stem index (0–9) and branch index (0–11).
 *
 * Valid Ba Zi pairs always share the same parity (both even or both odd).
 * Uses the Chinese Remainder Theorem: solve p ≡ s (mod 10), p ≡ b (mod 12).
 */
function getSexagenaryIndex(stemIndex: number, branchIndex: number): number {
	const diff = ((branchIndex - stemIndex) % 12 + 12) % 12; // always 0,2,4,6,8,10
	const k = (((diff / 2) * 5) % 6 + 6) % 6; // k in 0..5
	return (stemIndex + 10 * k) % 60;
}

/**
 * Assembles a BaziPillar object from stem and branch indices.
 */
function buildPillar(stemIndex: number, branchIndex: number): BaziPillar {
	const cycleIdx = getSexagenaryIndex(stemIndex, branchIndex);
	return {
		id: SEXAGENARY_SLUGS[cycleIdx],
		stemId: STEM_IDS[stemIndex],
		branchId: BRANCH_IDS[branchIndex],
		stemIndex,
		branchIndex,
		stemSymbol: STEM_SYMBOLS[stemIndex],
		branchSymbol: BRANCH_SYMBOLS[branchIndex],
		stemNameId: STEM_NAMES_ID[stemIndex],
		branchZodiacId: BRANCH_ZODIACS_ID[branchIndex],
		element: STEM_ELEMENTS[stemIndex],
	};
}

// ─── True Solar Time ──────────────────────────────────────────────────────

/**
 * Corrects local standard time to True Solar Time using longitude.
 *
 * Indonesia spans three administrative timezones:
 *   WIB  UTC+7  meridian 105° (Jawa, Sumatra, Kalimantan Barat/Tengah)
 *   WITA UTC+8  meridian 120° (Bali, Kalimantan Timur/Selatan, Sulawesi, NTB/NTT)
 *   WIT  UTC+9  meridian 135° (Maluku, Papua)
 *
 * Equation of Time is omitted (max ±16 min — negligible for 2-hour blocks).
 */
function applyTrueSolarTime(
	localHour: number,
	localMinute: number,
	longitude: number,
): { hour: number; minute: number; offsetMinutes: number } {
	const standardMeridian = Math.round(longitude / 15) * 15;
	const offsetMinutes = (longitude - standardMeridian) * 4; // degrees × 4 min/degree
	const totalMinutes = localHour * 60 + localMinute + offsetMinutes;
	const normalised = ((totalMinutes % 1440) + 1440) % 1440;
	return {
		hour: Math.floor(normalised / 60),
		minute: Math.round(normalised % 60),
		offsetMinutes,
	};
}

// ─── Pillar Calculations ──────────────────────────────────────────────────

/**
 * Year Pillar.
 * The Ba Zi year begins at Li Chun (立春, ~Feb 4), not Jan 1.
 * Dates before Feb 4 are assigned to the previous year.
 */
function getYearPillar(year: number, month: number, day: number): BaziPillar {
	const adjustedYear = month < 2 || (month === 2 && day < 4) ? year - 1 : year;
	const stemIndex   = ((adjustedYear - 4) % 10 + 10) % 10;
	const branchIndex = ((adjustedYear - 4) % 12 + 12) % 12;
	return buildPillar(stemIndex, branchIndex);
}

/**
 * Determines the Earthly Branch index for the Ba Zi month containing the given date.
 * Based on the 12 major solar terms (节 jié), with approximate fixed-date boundaries.
 *
 * Brackets (md = month×100 + day):
 *   Jan 1–5   → Rat  (Zi,   0) — Da Xue period still active from Dec 7
 *   Jan 6+    → Ox   (Chou, 1) — Xiao Han
 *   Feb 4+    → Tiger (Yin,  2) — Li Chun
 *   ...
 *   Dec 7+    → Rat  (Zi,   0) — Da Xue
 */
function getMonthBranchIndex(month: number, day: number): number {
	const md = month * 100 + day;

	if (md < 106)  return 0;  // Jan 1–5   : Rat   (Da Xue from Dec 7)
	if (md < 204)  return 1;  // Jan 6–Feb 3: Ox   (Xiao Han)
	if (md < 306)  return 2;  // Feb 4–Mar 5: Tiger (Li Chun)
	if (md < 405)  return 3;  // Mar 6–Apr 4: Rabbit (Jing Zhe)
	if (md < 506)  return 4;  // Apr 5–May 5: Dragon (Qing Ming)
	if (md < 606)  return 5;  // May 6–Jun 5: Snake  (Li Xia)
	if (md < 707)  return 6;  // Jun 6–Jul 6: Horse  (Mang Zhong)
	if (md < 807)  return 7;  // Jul 7–Aug 6: Goat   (Xiao Shu)
	if (md < 908)  return 8;  // Aug 7–Sep 7: Monkey (Li Qiu)
	if (md < 1008) return 9;  // Sep 8–Oct 7: Rooster (Bai Lu)
	if (md < 1107) return 10; // Oct 8–Nov 6: Dog    (Han Lu)
	if (md < 1207) return 11; // Nov 7–Dec 6: Pig    (Li Dong)
	return 0;                 // Dec 7–Dec 31: Rat   (Da Xue)
}

/**
 * Month Pillar.
 * Branch: from solar term (getMonthBranchIndex).
 * Stem  : derived from Year Stem via standard formula.
 *
 * Tiger (Yin) month start stem by Year Stem group:
 *   Jia(0)/Ji(5)  → Bing(2)
 *   Yi(1)/Geng(6) → Wu(4)
 *   Bing(2)/Xin(7)→ Geng(6)
 *   Ding(3)/Ren(8)→ Ren(8)
 *   Wu(4)/Gui(9)  → Jia(0)
 *
 * Formula: tigerStemStart = (yearStemIndex % 5) * 2 + 2
 *          monthSequence  = (monthBranchIndex - 2 + 12) % 12
 *          monthStemIndex = (tigerStemStart + monthSequence) % 10
 */
function getMonthPillar(month: number, day: number, yearStemIndex: number): BaziPillar {
	const monthBranchIndex = getMonthBranchIndex(month, day);
	const tigerStemStart   = (yearStemIndex % 5) * 2 + 2;
	const monthSequence    = (monthBranchIndex - 2 + 12) % 12;
	const monthStemIndex   = (tigerStemStart + monthSequence) % 10;
	return buildPillar(monthStemIndex, monthBranchIndex);
}

/**
 * Day Pillar.
 * Reference: JDN 2451545 (1 Jan 2000) = Geng (stem 6) Chen (branch 4).
 */
function getDayPillar(year: number, month: number, day: number): BaziPillar {
	const jdn         = dateToJdn(year, month, day);
	const stemIndex   = ((jdn - 2451545 + 6)  % 10 + 10) % 10;
	const branchIndex = ((jdn - 2451545 + 4)  % 12 + 12) % 12;
	return buildPillar(stemIndex, branchIndex);
}

/**
 * Hour Pillar.
 * 12 two-hour shi (時) blocks. Zi (Rat) hour = 23:00–01:00 (branchIndex 0).
 *
 * hourBranchIndex = floor((hour + 1) % 24 / 2)
 * hourStemStart   = (dayStemIndex % 5) * 2
 * hourStemIndex   = (hourStemStart + hourBranchIndex) % 10
 */
function getHourPillar(hour: number, dayStemIndex: number): BaziPillar {
	const hourBranchIndex = Math.floor(((hour + 1) % 24) / 2);
	const stemStart       = (dayStemIndex % 5) * 2;
	const hourStemIndex   = (stemStart + hourBranchIndex) % 10;
	return buildPillar(hourStemIndex, hourBranchIndex);
}

// ─── Wu Xing Balance ──────────────────────────────────────────────────────

/**
 * Counts the elemental distribution across all pillar stems and branches.
 * Each pillar contributes 2 elements: one from its Heavenly Stem, one from
 * its Earthly Branch. A full chart (with Hour Pillar) yields 8 characters.
 *
 * Note: Hidden stems (藏干 Cang Gan) are intentionally excluded here.
 * They are reserved for the full Ten Gods (十神) analysis in a future phase.
 */
function calculateWuXingBalance(pillars: Array<BaziPillar | null>): WuXingBalance {
	const balance: WuXingBalance = { kayu: 0, api: 0, tanah: 0, logam: 0, air: 0 };

	for (const pillar of pillars) {
		if (!pillar) continue;
		const stemEl   = STEM_ELEMENTS[pillar.stemIndex]   as keyof WuXingBalance;
		const branchEl = BRANCH_ELEMENTS[pillar.branchIndex] as keyof WuXingBalance;
		balance[stemEl]++;
		balance[branchEl]++;
	}

	return balance;
}

// ─── Main Export ──────────────────────────────────────────────────────────

/**
 * Calculates a complete Ba Zi (Four Pillars of Destiny) chart.
 *
 * @param birthDate  ISO date string "YYYY-MM-DD"
 * @param birthHour  Local standard time hour (0–23); omit/pass undefined if unknown
 * @param latitude   Decimal degrees latitude (reserved for Equation of Time in future)
 * @param longitude  Decimal degrees longitude; used for True Solar Time correction
 *
 * @example
 *   calculateBaziChart('1990-10-10', 14, -6.2088, 106.8456)
 *   // yearPillar: geng_wu, monthPillar: bing_xu, dayPillar: geng_chen,
 *   // hourPillar: ji_wei (TST-adjusted)
 */
export function calculateBaziChart(
	birthDate: string,
	birthHour?: number,
	_latitude?: number,
	longitude?: number,
): BaziChartResult {
	const [yearStr, monthStr, dayStr] = birthDate.split('-');
	const year  = parseInt(yearStr,  10);
	const month = parseInt(monthStr, 10);
	const day   = parseInt(dayStr,   10);

	// --- Pillars ---
	const yearPillar  = getYearPillar(year, month, day);
	const monthPillar = getMonthPillar(month, day, yearPillar.stemIndex);
	const dayPillar   = getDayPillar(year, month, day);

	// --- Hour Pillar + TST ---
	let hourPillar: BaziPillar | null = null;
	let trueSolarTimeNote: string | null = null;
	let adjustedHour: number | null = null;

	if (birthHour !== undefined && birthHour !== null) {
		let tstHour   = birthHour;
		let tstMinute = 0;

		if (longitude !== undefined && longitude !== null) {
			const tst     = applyTrueSolarTime(birthHour, 0, longitude);
			tstHour       = tst.hour;
			tstMinute     = tst.minute;
			const offsetMin    = Math.round(tst.offsetMinutes);
			const sign         = offsetMin >= 0 ? '+' : '-';
			const absMin       = Math.abs(offsetMin);
			const stdMeridian  = Math.round(longitude / 15) * 15;
			trueSolarTimeNote  =
				`${String(birthHour).padStart(2, '0')}:00 → ` +
				`${String(tstHour).padStart(2, '0')}:${String(tstMinute).padStart(2, '0')} TST ` +
				`(bujur ${longitude.toFixed(2)}°, meridian standar ${stdMeridian}°, koreksi ${sign}${absMin} mnt)`;
		}

		hourPillar   = getHourPillar(tstHour, dayPillar.stemIndex);
		adjustedHour = tstHour;
	}

	// --- Wu Xing Balance ---
	const wuXingBalance = calculateWuXingBalance([
		yearPillar, monthPillar, dayPillar, hourPillar,
	]);

	return {
		yearPillar,
		monthPillar,
		dayPillar,
		hourPillar,
		dayMasterId:      dayPillar.stemId,
		dayMasterElement: dayPillar.element,
		wuXingBalance,
		trueSolarTimeNote,
		adjustedHour,
	};
}
