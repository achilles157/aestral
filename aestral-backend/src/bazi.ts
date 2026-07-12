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

export const STEM_ELEMENTS: readonly string[] = [
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

export const BRANCH_ELEMENTS: readonly string[] = [
	'air', 'tanah', 'kayu', 'kayu', 'tanah', 'api',
	'api', 'tanah', 'logam', 'logam', 'tanah', 'air',
];

// ─── Wu Xing Interaction Cycles ──────────────────────────────────────────────

/** Sheng (生) — producing cycle */
const GENERATES: Record<string, string> = {
	kayu: 'api', api: 'tanah', tanah: 'logam', logam: 'air', air: 'kayu',
};

/** Ke (克) — controlling cycle */
const CONTROLS: Record<string, string> = {
	kayu: 'tanah', tanah: 'air', air: 'api', api: 'logam', logam: 'kayu',
};

// ─── Day Master Strength (旺衰) ───────────────────────────────────────────────
//
// Scores indexed by Month Branch (0=Zi … 11=Hai) per DM element.
// 0=Sangat Lemah(死) 1=Lemah(囚) 2=Sedang(休) 3=Kuat(相) 4=Sangat Kuat(旺)

const DM_STRENGTH_MATRIX: Record<string, readonly number[]> = {
	//         Zi  Cou  Yin  Mao  Che  Si   Wu   Wei  She  You  Xu   Hai
	kayu:   [  3,   1,   4,   4,   1,   2,   2,   1,   0,   0,   1,   3],
	api:    [  0,   2,   3,   3,   2,   4,   4,   2,   1,   1,   2,   0],
	tanah:  [  1,   4,   0,   0,   4,   3,   3,   4,   2,   2,   4,   1],
	logam:  [  2,   3,   1,   1,   3,   0,   0,   3,   4,   4,   3,   2],
	air:    [  4,   0,   2,   2,   0,   1,   1,   0,   3,   3,   0,   4],
};

const DM_STRENGTH_LABELS = [
	'Sangat Lemah', 'Lemah', 'Sedang', 'Kuat', 'Sangat Kuat',
] as const;

// ─── Cang Gan (藏干 Hidden Stems) ───────────────────────────────────────────
// Each branch contains 1-3 hidden stems that contribute to Wu Xing balance.

const BRANCH_HIDDEN_STEMS: readonly (readonly number[])[] = [
	[9],          // zi  (0, Rat)    : gui
	[5, 9, 7],    // chou(1, Ox)     : ji, gui, xin
	[0, 2, 4],    // yin (2, Tiger)  : jia, bing, wu
	[1],          // mao (3, Rabbit) : yi
	[4, 1, 9],    // chen(4, Dragon) : wu, yi, gui
	[2, 4, 6],    // si  (5, Snake)  : bing, wu, geng
	[3, 5],       // wu  (6, Horse)  : ding, ji
	[5, 3, 1],    // wei (7, Goat)   : ji, ding, yi
	[6, 8, 4],    // shen(8, Monkey) : geng, ren, wu
	[7],          // you (9, Rooster): xin
	[4, 7, 3],    // xu  (10, Dog)   : wu, xin, ding
	[8, 0],       // hai (11, Pig)   : ren, jia
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

// ─── Solar Term Lookup Table (节 Jié) ─────────────────────────────────────
//
// Day-of-month for each of the 12 jié (month-start solar terms), 1924–2100.
// Generated by scripts/gen_solar_terms.js using Meeus low-precision algorithm
// with WIB (UTC+7) offset — matches Indonesian local date of each solar term.
//
// Flat array: index = (year − 1924) × 12 + termIndex
// termIndex : 0=XiaoHan 1=LiChun 2=JingZhe 3=QingMing 4=LiXia  5=MangZhong
//             6=XiaoShu 7=LiQiu  8=BaiLu   9=HanLu  10=LiDong 11=DaXue

const JIE_DAYS: readonly number[] = [
  6,5,6,5,6,6,7,8,8,8,7,7, // 1924
  6,4,6,5,6,6,7,8,8,9,8,7, // 1925
  6,4,6,5,6,6,8,8,8,9,8,8, // 1926
  6,5,6,6,6,7,8,8,8,9,8,8, // 1927
  6,5,6,5,6,6,7,8,8,8,7,7, // 1928
  6,4,6,5,6,6,7,8,8,9,8,7, // 1929
  6,4,6,5,6,6,8,8,8,9,8,8, // 1930
  6,5,6,6,6,6,8,8,8,9,8,8, // 1931
  6,5,6,5,6,6,7,8,8,8,7,7, // 1932
  6,4,6,5,6,6,7,8,8,9,8,7, // 1933
  6,4,6,5,6,6,8,8,8,9,8,8, // 1934
  6,5,6,6,6,6,8,8,8,9,8,8, // 1935
  6,5,6,5,5,6,7,8,8,8,7,7, // 1936
  6,4,6,5,6,6,7,8,8,9,8,7, // 1937
  6,4,6,5,6,6,8,8,8,9,8,8, // 1938
  6,5,6,5,6,6,8,8,8,9,8,8, // 1939
  6,5,6,5,5,6,7,7,8,8,7,7, // 1940
  6,4,6,5,6,6,7,8,8,8,8,7, // 1941
  6,4,6,5,6,6,8,8,8,9,8,8, // 1942
  6,4,6,5,6,6,8,8,8,9,8,8, // 1943
  6,5,5,5,5,6,7,7,8,8,7,7, // 1944
  5,4,6,5,6,6,7,8,8,8,8,7, // 1945
  6,4,6,5,6,6,8,8,8,9,8,8, // 1946
  6,4,6,5,6,6,8,8,8,9,8,8, // 1947
  6,5,5,5,5,6,7,7,8,8,7,7, // 1948
  5,4,6,5,6,6,7,8,8,8,8,7, // 1949
  6,4,6,5,6,6,8,8,8,9,8,7, // 1950
  6,4,6,5,6,6,8,8,8,9,8,8, // 1951
  6,5,5,5,5,6,7,7,8,8,7,7, // 1952
  5,4,6,5,6,6,7,8,8,8,8,7, // 1953
  6,4,6,5,6,6,7,8,8,9,8,7, // 1954
  6,4,6,5,6,6,8,8,8,9,8,8, // 1955
  6,5,5,5,5,6,7,7,7,8,7,7, // 1956
  5,4,6,5,6,6,7,8,8,8,7,7, // 1957
  6,4,6,5,6,6,7,8,8,9,8,7, // 1958
  6,4,6,5,6,6,8,8,8,9,8,8, // 1959
  6,5,5,5,5,5,7,7,7,8,7,7, // 1960
  5,4,6,5,6,6,7,8,8,8,7,7, // 1961
  6,4,6,5,6,6,7,8,8,9,8,7, // 1962
  6,4,6,5,6,6,8,8,8,9,8,8, // 1963
  6,5,5,5,5,5,7,7,7,8,7,7, // 1964
  5,4,6,5,6,6,7,8,8,8,7,7, // 1965
  6,4,6,5,6,6,7,8,8,9,8,7, // 1966
  6,4,6,5,6,6,8,8,8,9,8,8, // 1967
  6,5,5,5,5,5,7,7,7,8,7,7, // 1968
  5,4,6,5,5,6,7,8,8,8,7,7, // 1969
  6,4,6,5,6,6,7,8,8,9,8,7, // 1970
  6,4,6,5,6,6,8,8,8,9,8,8, // 1971
  6,5,5,4,5,5,7,7,7,8,7,7, // 1972
  5,4,6,5,5,6,7,7,8,8,7,7, // 1973
  6,4,6,5,6,6,7,8,8,8,8,7, // 1974
  6,4,6,5,6,6,8,8,8,9,8,8, // 1975
  6,4,5,4,5,5,7,7,7,8,7,7, // 1976
  5,4,5,5,5,6,7,7,8,8,7,7, // 1977
  5,4,6,5,6,6,7,8,8,8,8,7, // 1978
  6,4,6,5,6,6,8,8,8,9,8,8, // 1979
  6,4,5,4,5,5,7,7,7,8,7,7, // 1980
  5,4,5,5,5,6,7,7,8,8,7,7, // 1981
  5,4,6,5,6,6,7,8,8,8,8,7, // 1982
  6,4,6,5,6,6,7,8,8,9,8,7, // 1983
  6,4,5,4,5,5,7,7,7,8,7,7, // 1984
  5,4,5,5,5,6,7,7,7,8,7,7, // 1985
  5,4,6,5,6,6,7,8,8,8,8,7, // 1986
  6,4,6,5,6,6,7,8,8,9,8,7, // 1987
  6,4,5,4,5,5,7,7,7,8,7,7, // 1988
  5,4,5,5,5,5,7,7,7,8,7,7, // 1989
  5,4,6,5,6,6,7,8,8,8,7,7, // 1990
  6,4,6,5,6,6,7,8,8,9,8,7, // 1991
  6,4,5,4,5,5,7,7,7,8,7,7, // 1992
  5,4,5,5,5,5,7,7,7,8,7,7, // 1993
  5,4,6,5,6,6,7,8,8,8,7,7, // 1994
  6,4,6,5,6,6,7,8,8,9,8,7, // 1995
  6,4,5,4,5,5,7,7,7,8,7,7, // 1996
  5,4,5,5,5,5,7,7,7,8,7,7, // 1997
  5,4,6,5,6,6,7,8,8,8,7,7, // 1998
  6,4,6,5,6,6,7,8,8,9,8,7, // 1999
  6,4,5,4,5,5,7,7,7,8,7,7, // 2000
  5,4,5,5,5,5,7,7,7,8,7,7, // 2001
  5,4,6,5,5,6,7,7,8,8,7,7, // 2002
  6,4,6,5,6,6,7,8,8,8,8,7, // 2003
  6,4,5,4,5,5,7,7,7,8,7,7, // 2004
  5,4,5,4,5,5,7,7,7,8,7,7, // 2005
  5,4,6,5,5,6,7,7,8,8,7,7, // 2006
  6,4,6,5,6,6,7,8,8,8,8,7, // 2007
  6,4,5,4,5,5,7,7,7,8,7,7, // 2008
  5,3,5,4,5,5,7,7,7,8,7,7, // 2009
  5,4,5,5,5,6,7,7,8,8,7,7, // 2010
  5,4,6,5,6,6,7,8,8,8,8,7, // 2011
  6,4,5,4,5,5,6,7,7,8,7,7, // 2012
  5,3,5,4,5,5,7,7,7,8,7,7, // 2013
  5,4,5,5,5,6,7,7,8,8,7,7, // 2014
  5,4,6,5,6,6,7,8,8,8,8,7, // 2015
  6,4,5,4,5,5,6,7,7,8,7,6, // 2016
  5,3,5,4,5,5,7,7,7,8,7,7, // 2017
  5,4,5,5,5,6,7,7,7,8,7,7, // 2018
  5,4,6,5,6,6,7,8,8,8,8,7, // 2019
  6,4,5,4,5,5,6,7,7,8,7,6, // 2020
  5,3,5,4,5,5,7,7,7,8,7,7, // 2021
  5,4,5,5,5,5,7,7,7,8,7,7, // 2022
  5,4,6,5,6,6,7,8,8,8,7,7, // 2023
  6,4,5,4,5,5,6,7,7,8,7,6, // 2024
  5,3,5,4,5,5,7,7,7,8,7,7, // 2025
  5,4,5,5,5,5,7,7,7,8,7,7, // 2026
  5,4,6,5,6,6,7,8,8,8,7,7, // 2027
  6,4,5,4,5,5,6,7,7,8,7,6, // 2028
  5,3,5,4,5,5,7,7,7,8,7,7, // 2029
  5,4,5,5,5,5,7,7,7,8,7,7, // 2030
  5,4,6,5,5,6,7,7,8,8,7,7, // 2031
  6,4,5,4,5,5,6,7,7,8,7,6, // 2032
  5,3,5,4,5,5,7,7,7,8,7,7, // 2033
  5,4,5,5,5,5,7,7,7,8,7,7, // 2034
  5,4,6,5,5,6,7,7,8,8,7,7, // 2035
  6,4,5,4,5,5,6,7,7,7,7,6, // 2036
  5,3,5,4,5,5,7,7,7,8,7,7, // 2037
  5,4,5,4,5,5,7,7,7,8,7,7, // 2038
  5,4,6,5,5,6,7,7,8,8,7,7, // 2039
  6,4,5,4,5,5,6,7,7,7,7,6, // 2040
  5,3,5,4,5,5,6,7,7,8,7,7, // 2041
  5,4,5,4,5,5,7,7,7,8,7,7, // 2042
  5,4,5,5,5,6,7,7,8,8,7,7, // 2043
  6,4,5,4,5,5,6,7,7,7,7,6, // 2044
  5,3,5,4,5,5,6,7,7,8,7,7, // 2045
  5,3,5,4,5,5,7,7,7,8,7,7, // 2046
  5,4,5,5,5,6,7,7,7,8,7,7, // 2047
  5,4,5,4,5,5,6,7,7,7,7,6, // 2048
  5,3,5,4,5,5,6,7,7,8,7,6, // 2049
  5,3,5,4,5,5,7,7,7,8,7,7, // 2050
  5,4,5,5,5,5,7,7,7,8,7,7, // 2051
  5,4,5,4,5,5,6,7,7,7,7,6, // 2052
  5,3,5,4,5,5,6,7,7,8,7,6, // 2053
  5,3,5,4,5,5,7,7,7,8,7,7, // 2054
  5,4,5,5,5,5,7,7,7,8,7,7, // 2055
  5,4,5,4,5,5,6,7,7,7,6,6, // 2056
  5,3,5,4,5,5,6,7,7,8,7,6, // 2057
  5,3,5,4,5,5,7,7,7,8,7,7, // 2058
  5,4,5,5,5,5,7,7,7,8,7,7, // 2059
  5,4,5,4,5,5,6,6,7,7,6,6, // 2060
  5,3,5,4,5,5,6,7,7,8,7,6, // 2061
  5,3,5,4,5,5,7,7,7,8,7,7, // 2062
  5,4,5,5,5,5,7,7,7,8,7,7, // 2063
  5,4,5,4,4,5,6,6,7,7,6,6, // 2064
  5,3,5,4,5,5,6,7,7,8,7,6, // 2065
  5,3,5,4,5,5,7,7,7,8,7,7, // 2066
  5,4,5,4,5,5,7,7,7,8,7,7, // 2067
  5,4,5,4,4,5,6,6,7,7,6,6, // 2068
  5,3,5,4,5,5,6,7,7,7,7,6, // 2069
  5,3,5,4,5,5,6,7,7,8,7,7, // 2070
  5,4,5,4,5,5,7,7,7,8,7,7, // 2071
  5,4,5,4,4,5,6,6,7,7,6,6, // 2072
  5,3,5,4,5,5,6,7,7,7,7,6, // 2073
  5,3,5,4,5,5,6,7,7,8,7,7, // 2074
  5,4,5,4,5,5,7,7,7,8,7,7, // 2075
  5,4,5,4,4,5,6,6,7,7,6,6, // 2076
  5,3,5,4,5,5,6,7,7,7,7,6, // 2077
  5,3,5,4,5,5,6,7,7,8,7,7, // 2078
  5,3,5,4,5,5,7,7,7,8,7,7, // 2079
  5,4,4,4,4,4,6,6,6,7,6,6, // 2080
  4,3,5,4,5,5,6,7,7,7,7,6, // 2081
  5,3,5,4,5,5,6,7,7,8,7,6, // 2082
  5,3,5,4,5,5,7,7,7,8,7,7, // 2083
  5,4,4,4,4,4,6,6,6,7,6,6, // 2084
  4,3,5,4,5,5,6,7,7,7,7,6, // 2085
  5,3,5,4,5,5,6,7,7,8,7,6, // 2086
  5,3,5,4,5,5,7,7,7,8,7,7, // 2087
  5,4,4,4,4,4,6,6,6,7,6,6, // 2088
  4,3,5,4,5,5,6,7,7,7,6,6, // 2089
  5,3,5,4,5,5,6,7,7,8,7,6, // 2090
  5,3,5,4,5,5,7,7,7,8,7,7, // 2091
  5,4,4,4,4,4,6,6,6,7,6,6, // 2092
  4,3,5,4,4,5,6,6,7,7,6,6, // 2093
  5,3,5,4,5,5,6,7,7,8,7,6, // 2094
  5,3,5,4,5,5,7,7,7,8,7,7, // 2095
  5,4,4,4,4,4,6,6,6,7,6,6, // 2096
  4,3,5,4,4,5,6,6,7,7,6,6, // 2097
  5,3,5,4,5,5,6,7,7,8,7,6, // 2098
  5,3,5,4,5,5,7,7,7,8,7,7, // 2099
  5,4,5,4,5,5,7,7,7,8,7,7, // 2100
];

/**
 * Returns the actual day-of-month for a jié solar term in a given year (WIB).
 * termIndex: 0=XiaoHan 1=LiChun 2=JingZhe 3=QingMing 4=LiXia  5=MangZhong
 *            6=XiaoShu 7=LiQiu  8=BaiLu   9=HanLu  10=LiDong 11=DaXue
 */
function getJieDay(termIndex: number, year: number): number {
	if (year < 1924 || year > 2100) {
		const NOM = [6, 4, 6, 5, 6, 6, 7, 7, 8, 8, 7, 7];
		return NOM[termIndex];
	}
	return JIE_DAYS[(year - 1924) * 12 + termIndex];
}

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

/**
 * Ten Gods (十神) relationship of each pillar's Heavenly Stem relative to the Day Master.
 * Day Pillar is always the Day Master itself — not included here.
 */
export interface TenGods {
	year:  string;
	month: string;
	/** Null when birth hour is unknown */
	hour:  string | null;
}

/** Day Master strength and elemental prescription */
export interface DayMasterStrength {
	/** e.g. "Kuat", "Lemah", "Sedang" */
	label: string;
	/** Favorable elements — 用神 yòngshén */
	yongShen: string[];
	/** Unfavorable elements — 忌神 jìshén */
	jiShen: string[];
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
	/** Ten Gods relationship per pillar stem relative to Day Master */
	tenGods: TenGods;
	/** Day Master strength and favorable/unfavorable elements */
	dmStrength: DayMasterStrength;
	/** Human-readable TST correction note, null if no longitude provided */
	trueSolarTimeNote: string | null;
	/** TST-adjusted hour used for Hour Pillar, null if birthHour not provided */
	adjustedHour: number | null;
}

// ─── Ten Gods (十神) ──────────────────────────────────────────────────────────

/**
 * Returns the Ten God relationship ID of a target stem relative to the Day Master stem.
 *
 * The ten gods are determined by two axes:
 *   1. The Wu Xing relationship (same element, generates, controls, etc.)
 *   2. Polarity parity — same parity (both Yang or both Yin) → "indirect/sibling" variant
 *
 * @param dmStemIndex     Day Master stem index (0–9)
 * @param targetStemIndex Target stem index to classify (0–9)
 */
function getTenGodId(dmStemIndex: number, targetStemIndex: number): string {
	const dmEl  = STEM_ELEMENTS[dmStemIndex];
	const tgEl  = STEM_ELEMENTS[targetStemIndex];
	const same  = (dmStemIndex % 2) === (targetStemIndex % 2);

	if (tgEl === dmEl)              return same ? 'friend'            : 'rob_wealth';
	if (GENERATES[dmEl] === tgEl)   return same ? 'eating_god'        : 'hurting_officer';
	if (CONTROLS[dmEl]  === tgEl)   return same ? 'indirect_wealth'   : 'direct_wealth';
	if (CONTROLS[tgEl]  === dmEl)   return same ? 'seven_killings'    : 'direct_officer';
	if (GENERATES[tgEl] === dmEl)   return same ? 'indirect_resource' : 'direct_resource';
	return 'friend'; // unreachable with valid 0–9 stem indices
}

/**
 * Returns the strength label of the Day Master based on the Month Branch.
 * Uses the seasonal rooting (月令) principle.
 */
function getDayMasterStrength(monthBranchIndex: number, dmElement: string): string {
	const scores = DM_STRENGTH_MATRIX[dmElement];
	if (!scores) return 'Sedang';
	return DM_STRENGTH_LABELS[scores[monthBranchIndex]];
}

/**
 * Returns favorable (用神 yòngshén) and unfavorable (忌神 jìshén) elements
 * based on Day Master element and strength.
 *
 * Strong DM  → needs drain (output) + control to balance excess.
 * Weak DM    → needs support (resource) + same element to reinforce.
 */
function getFavorableElements(
	dmElement: string,
	strength: string,
): { yongShen: string[]; jiShen: string[] } {
	const generates    = GENERATES[dmElement];
	const generatedBy  = Object.entries(GENERATES).find(([, v]) => v === dmElement)![0];
	const controlledBy = Object.entries(CONTROLS).find(([, v]) => v === dmElement)![0];

	if (strength === 'Kuat' || strength === 'Sangat Kuat') {
		return { yongShen: [generates, controlledBy], jiShen: [generatedBy, dmElement] };
	}
	if (strength === 'Lemah' || strength === 'Sangat Lemah') {
		return { yongShen: [generatedBy, dmElement], jiShen: [controlledBy, generates] };
	}
	// Sedang
	return { yongShen: [generatedBy, dmElement], jiShen: [controlledBy] };
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
	const liChunDay    = getJieDay(1, year); // index 1 = Li Chun (立春)
	const adjustedYear = month < 2 || (month === 2 && day < liChunDay) ? year - 1 : year;
	const stemIndex   = ((adjustedYear - 4) % 10 + 10) % 10;
	const branchIndex = ((adjustedYear - 4) % 12 + 12) % 12;
	return buildPillar(stemIndex, branchIndex);
}

/**
 * Determines the Earthly Branch index for the Ba Zi month containing the given date.
 * Uses the actual solar term day for the given year (not a fixed approximation).
 *
 * termIndex mapping: 0=XiaoHan(Jan) 1=LiChun(Feb) 2=JingZhe(Mar) 3=QingMing(Apr)
 *   4=LiXia(May) 5=MangZhong(Jun) 6=XiaoShu(Jul) 7=LiQiu(Aug)
 *   8=BaiLu(Sep) 9=HanLu(Oct) 10=LiDong(Nov) 11=DaXue(Dec)
 */
function getMonthBranchIndex(month: number, day: number, year: number): number {
	const md = month * 100 + day;
	if (md < 100 + getJieDay(0, year))  return 0;  // Jan 1 – XiaoHan  : Rat   (Da Xue tail)
	if (md < 200 + getJieDay(1, year))  return 1;  // XiaoHan – LiChun : Ox
	if (md < 300 + getJieDay(2, year))  return 2;  // LiChun – JingZhe : Tiger
	if (md < 400 + getJieDay(3, year))  return 3;  // JingZhe – QingMing: Rabbit
	if (md < 500 + getJieDay(4, year))  return 4;  // QingMing – LiXia  : Dragon
	if (md < 600 + getJieDay(5, year))  return 5;  // LiXia – MangZhong : Snake
	if (md < 700 + getJieDay(6, year))  return 6;  // MangZhong – XiaoShu: Horse
	if (md < 800 + getJieDay(7, year))  return 7;  // XiaoShu – LiQiu   : Goat
	if (md < 900 + getJieDay(8, year))  return 8;  // LiQiu – BaiLu     : Monkey
	if (md < 1000 + getJieDay(9, year)) return 9;  // BaiLu – HanLu     : Rooster
	if (md < 1100 + getJieDay(10, year)) return 10; // HanLu – LiDong   : Dog
	if (md < 1200 + getJieDay(11, year)) return 11; // LiDong – DaXue   : Pig
	return 0;                                        // DaXue – Dec 31   : Rat
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
function getMonthPillar(month: number, day: number, yearStemIndex: number, year: number): BaziPillar {
	const monthBranchIndex = getMonthBranchIndex(month, day, year);
	const tigerStemStart   = (yearStemIndex % 5) * 2 + 2;
	const monthSequence    = (monthBranchIndex - 2 + 12) % 12;
	const monthStemIndex   = (tigerStemStart + monthSequence) % 10;
	return buildPillar(monthStemIndex, monthBranchIndex);
}

/**
 * Day Pillar.
 * Reference: JDN 2451545 (1 Jan 2000) = Geng (stem 6) Chen (branch 4).
 */
export function getDayPillar(year: number, month: number, day: number): BaziPillar {
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
 * Counts the elemental distribution across all pillar stems, branches,
 * and Cang Gan (藏干 hidden stems).
 *
 * Each pillar contributes:
 *   • 1 element from its Heavenly Stem
 *   • 1 element from its Earthly Branch surface element
 *   • 1–3 elements from hidden stems (Cang Gan) inside the branch
 *
 * A full chart (with Hour Pillar) yields 16–17 characters after Cang Gan.
 */
function calculateWuXingBalance(pillars: Array<BaziPillar | null>): WuXingBalance {
	const balance: WuXingBalance = { kayu: 0, api: 0, tanah: 0, logam: 0, air: 0 };

	for (const pillar of pillars) {
		if (!pillar) continue;
		// Heavenly Stem element
		balance[STEM_ELEMENTS[pillar.stemIndex] as keyof WuXingBalance]++;
		// Earthly Branch surface element
		balance[BRANCH_ELEMENTS[pillar.branchIndex] as keyof WuXingBalance]++;
		// Cang Gan — hidden stems inside the branch
		for (const hiddenStemIdx of BRANCH_HIDDEN_STEMS[pillar.branchIndex]) {
			balance[STEM_ELEMENTS[hiddenStemIdx] as keyof WuXingBalance]++;
		}
	}

	return balance;
}

// ─── Main Export ──────────────────────────────────────────────────────────

// ─── Luck Pillars (大運 Da Yun) ───────────────────────────────────────────────

export interface LuckPillar {
	pillar: BaziPillar;
	startAge: number;
	/** startAge + 9 */
	endAge: number;
}

export interface LuckPillarsResult {
	pillars: LuckPillar[];
	/** true = forward (顺运), false = backward (逆运) */
	isForward: boolean;
	/** Age at which the first luck pillar begins */
	startAge: number;
}

/**
 * Returns the number of days between the birth date and the nearest
 * solar term (forward or backward), used to derive Da Yun start age.
 */
function daysToNearestSolarTerm(
	year: number, month: number, day: number,
	isForward: boolean,
): number {
	const birthJdn = dateToJdn(year, month, day);
	const candidates: number[] = [];
	for (let yr = year - 1; yr <= year + 1; yr++) {
		for (let termIdx = 0; termIdx < 12; termIdx++) {
			const d = getJieDay(termIdx, yr);
			candidates.push(dateToJdn(yr, termIdx + 1, d));
		}
	}
	if (isForward) {
		const nexts = candidates.filter(j => j > birthJdn).sort((a, b) => a - b);
		return nexts.length ? nexts[0] - birthJdn : 30;
	} else {
		const prevs = candidates.filter(j => j < birthJdn).sort((a, b) => b - a);
		return prevs.length ? birthJdn - prevs[0] : 30;
	}
}

/**
 * Calculates 8 ten-year Luck Pillar cycles (大運) from the Month Pillar sequence.
 *
 * Direction rule:
 *   Male + Yang Year  OR  Female + Yin Year  → forward (顺运)
 *   Male + Yin Year   OR  Female + Yang Year → backward (逆运)
 *
 * Start age = round(days to nearest solar term / 3), clamped 1–99.
 * Each subsequent pillar adds 10 years.
 */
export function calculateLuckPillars(
	birthDate: string,
	monthPillar: BaziPillar,
	yearStemIndex: number,
	isMale: boolean,
	count = 8,
): LuckPillarsResult {
	const [y, m, d] = birthDate.split('-').map(Number);
	const isYangYear = yearStemIndex % 2 === 0;
	const isForward  = isMale === isYangYear;

	const days     = daysToNearestSolarTerm(y, m, d, isForward);
	const startAge = Math.min(Math.max(Math.round(days / 3), 1), 99);

	const monthCycleIdx = getSexagenaryIndex(monthPillar.stemIndex, monthPillar.branchIndex);
	const step = isForward ? 1 : -1;

	const pillars: LuckPillar[] = Array.from({ length: count }, (_, i) => {
		const cycleIdx = ((monthCycleIdx + step * (i + 1)) % 60 + 60) % 60;
		const pillar   = buildPillar(cycleIdx % 10, cycleIdx % 12);
		const sa       = startAge + i * 10;
		return { pillar, startAge: sa, endAge: sa + 9 };
	});

	return { pillars, isForward, startAge };
}

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
	const monthPillar = getMonthPillar(month, day, yearPillar.stemIndex, year);
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

	// --- Ten Gods ---
	const dmIdx = dayPillar.stemIndex;
	const tenGods: TenGods = {
		year:  getTenGodId(dmIdx, yearPillar.stemIndex),
		month: getTenGodId(dmIdx, monthPillar.stemIndex),
		hour:  hourPillar ? getTenGodId(dmIdx, hourPillar.stemIndex) : null,
	};

	// --- Day Master Strength ---
	const strengthLabel = getDayMasterStrength(monthPillar.branchIndex, dayPillar.element);
	const { yongShen, jiShen } = getFavorableElements(dayPillar.element, strengthLabel);
	const dmStrength: DayMasterStrength = { label: strengthLabel, yongShen, jiShen };

	return {
		yearPillar,
		monthPillar,
		dayPillar,
		hourPillar,
		dayMasterId:      dayPillar.stemId,
		dayMasterElement: dayPillar.element,
		wuXingBalance,
		tenGods,
		dmStrength,
		trueSolarTimeNote,
		adjustedHour,
	};
}

// ─── Ba Zi Compatibility Analysis ──────────────────────────────────────────

export interface BaziCompatibilityResult {
	dayMasterMatch: {
		type: 'combination' | 'clash' | 'neutral' | 'same_element';
		label: string;
		description: string;
	};
	spousePalaceMatch: {
		type: 'harmony' | 'clash' | 'neutral';
		label: string;
		description: string;
	};
	monthPillarMatch: {
		type: 'harmony' | 'clash' | 'neutral';
		label: string;
		description: string;
	};
	zodiacMatch: {
		type: 'harmony' | 'clash' | 'neutral';
		label: string;
		description: string;
	};
	elementCompatibility: {
		type: 'complementary' | 'non-complementary';
		label: string;
		description: string;
	};
	compatibilityScore: number;
}

export function calculateBaziCompatibility(
	chart1: BaziChartResult,
	chart2: BaziChartResult,
): BaziCompatibilityResult {
	const stem1 = chart1.dayPillar.stemIndex;
	const stem2 = chart2.dayPillar.stemIndex;
	const branch1 = chart1.dayPillar.branchIndex;
	const branch2 = chart2.dayPillar.branchIndex;
	const yBranch1 = chart1.yearPillar.branchIndex;
	const yBranch2 = chart2.yearPillar.branchIndex;
	const mBranch1 = chart1.monthPillar.branchIndex;
	const mBranch2 = chart2.monthPillar.branchIndex;

	const yongShen1 = chart1.dmStrength.yongShen;
	const yongShen2 = chart2.dmStrength.yongShen;

	// 1. Day Master Match
	let dmType: 'combination' | 'clash' | 'neutral' | 'same_element' = 'neutral';
	let dmLabel = 'Interaksi Netral (Saling Mendukung)';
	let dmDesc = 'Karakter utama kalian tidak berbenturan langsung, melahirkan hubungan yang stabil dan minim drama.';

	const dmCombos = [[0, 5], [1, 6], [2, 7], [3, 8], [4, 9]];
	const isDmCombo = dmCombos.some(([a, b]) => (stem1 === a && stem2 === b) || (stem1 === b && stem2 === a));
	const dmClashes = [[0, 6], [1, 7], [2, 8], [3, 9]];
	const isDmClash = dmClashes.some(([a, b]) => (stem1 === a && stem2 === b) || (stem1 === b && stem2 === a));
	const isSameElement = !isDmCombo && !isDmClash && Math.floor(stem1 / 2) === Math.floor(stem2 / 2);

	if (isDmCombo) {
		dmType = 'combination';
		dmLabel = 'Ketertarikan Alami (Saling Menggenapi)';
		dmDesc = 'Day Master kalian berdua membentuk kombinasi harmonis. Chemistry alami ini melahirkan daya tarik kuat sejak pandangan pertama.';
	} else if (isDmClash) {
		dmType = 'clash';
		dmLabel = 'Dinamika Cermin (Tantangan Pertumbuhan)';
		dmDesc = 'Terjadi benturan kutub energi Day Master. Hubungan kalian penuh dengan cerminan diri yang memicu pertumbuhan spiritual, meski kadang menimbulkan percikan argumen.';
	} else if (isSameElement) {
		dmType = 'same_element';
		dmLabel = 'Cermin Energi (Sesama Elemen)';
		dmDesc = 'Day Master kalian berdua berasal dari elemen yang sama. Hubungan ini penuh empati dan saling pengertian mendalam, namun rentan terhadap persaingan ego bawah sadar — karena kalian memandang dunia dengan cara yang terlalu mirip.';
	}

	// 2. Spouse Palace Match
	let spType: 'harmony' | 'clash' | 'neutral' = 'neutral';
	let spLabel = 'Dinamika Harian Stabil';
	let spDesc = 'Komunikasi dan ekspektasi harian dalam rumah tangga berjalan dalam ritme wajar tanpa gesekan konstan.';

	const branchCombos = [[0, 1], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]];
	const isSpCombo = branchCombos.some(([a, b]) => (branch1 === a && branch2 === b) || (branch1 === b && branch2 === a));
	const isSpClash = Math.abs(branch1 - branch2) === 6;

	if (isSpCombo) {
		spType = 'harmony';
		spLabel = 'Chemistry Domestik Sangat Kuat';
		spDesc = 'Istana Pasangan kalian bersinkronisasi secara intim. Kalian mudah memahami bahasa kasih masing-masing dan nyaman berbagi ruang hidup bersama.';
	} else if (isSpClash) {
		spType = 'clash';
		spLabel = 'Fase Penyelarasan (Tantangan Komunikasi)';
		spDesc = 'Istana Pasangan saling bertolak belakang. Fluktuasi emosi harian dalam rumah tangga memerlukan ruang privasi ekstra dan latihan mendengarkan tanpa menghakimi.';
	}

	// 3. Zodiac Match
	let zType: 'harmony' | 'clash' | 'neutral' = 'neutral';
	let zLabel = 'Koneksi Sosial Selaras';
	let zDesc = 'Cara kalian berdua berinteraksi dengan keluarga besar dan lingkaran sosial luar terjalin wajar dan bersahabat.';

	const isZCombo = branchCombos.some(([a, b]) => (yBranch1 === a && yBranch2 === b) || (yBranch1 === b && yBranch2 === a));
	const triads = [[8, 0, 4], [11, 3, 7], [2, 6, 10], [5, 9, 1]];
	const isZTriad = triads.some(
		(triad) => triad.includes(yBranch1) && triad.includes(yBranch2) && yBranch1 !== yBranch2
	);
	const isZClash = Math.abs(yBranch1 - yBranch2) === 6;

	if (isZCombo || isZTriad) {
		zType = 'harmony';
		zLabel = 'Harmoni Zodiak Lahir';
		zDesc = 'Zodiak tahun lahir kalian bersahabat erat. Hubungan ini mendapat dukungan sosial yang baik dari keluarga besar dan lingkungan pertemanan.';
	} else if (isZClash) {
		zType = 'clash';
		zLabel = 'Oposisi Sudut Pandang';
		zDesc = 'Zodiak kalian berhadapan langsung. Perbedaan latar belakang atau cara pandang sosial sering memicu debat, yang memerlukan toleransi atas perbedaan.';
	}

	// 4. Month Pillar Match (Ambisi & Karir)
	let mpType: 'harmony' | 'clash' | 'neutral' = 'neutral';
	let mpLabel = 'Arah Hidup Mandiri';
	let mpDesc = 'Ambisi dan ritme karir kalian berjalan di jalur masing-masing — bukan berarti tidak cocok, tapi lebih kepada dua individu yang mengejar pertumbuhan secara independen.';

	const isMpCombo = branchCombos.some(([a, b]) => (mBranch1 === a && mBranch2 === b) || (mBranch1 === b && mBranch2 === a));
	const isMpTriad = triads.some(
		(triad) => triad.includes(mBranch1) && triad.includes(mBranch2) && mBranch1 !== mBranch2,
	);
	const isMpClash = Math.abs(mBranch1 - mBranch2) === 6;

	if (isMpCombo || isMpTriad) {
		mpType = 'harmony';
		mpLabel = 'Visi Hidup Selaras';
		mpDesc = 'Pilar Bulan kalian — cerminan ambisi dan arah karir — bersinergi harmonis. Kalian cenderung memiliki tujuan hidup yang saling mendukung dan mudah sepakat dalam keputusan besar bersama.';
	} else if (isMpClash) {
		mpType = 'clash';
		mpLabel = 'Perbedaan Ambisi (Tantangan Arah)';
		mpDesc = 'Arah karir dan ambisi hidup kalian bergerak di jalur yang berlawanan. Hubungan ini memerlukan negosiasi aktif agar masing-masing bisa tumbuh tanpa mengorbankan impian pasangannya.';
	}

	// 5. Wu Xing Complementarity
	const getDominant = (chart: BaziChartResult) => {
		let maxVal = -1;
		let maxElem = 'kayu';
		for (const [elem, pct] of Object.entries(chart.wuXingBalance)) {
			if (pct > maxVal) {
				maxVal = pct;
				maxElem = elem;
			}
		}
		return maxElem;
	};

	const dominant1 = getDominant(chart1);
	const dominant2 = getDominant(chart2);

	const p1HelpsP2 = yongShen2.includes(dominant1);
	const p2HelpsP1 = yongShen1.includes(dominant2);
	const isComplementary = p1HelpsP2 || p2HelpsP1;

	let compLabel = 'Keseimbangan Energi Menengah';
	let compDesc = 'Distribusi elemen kalian cukup seimbang. Hubungan ini berjalan mandiri tanpa saling ketergantungan energi yang berlebih.';

	if (p1HelpsP2 && p2HelpsP1) {
		compLabel = 'Sinergi Yin-Yang Sempurna';
		compDesc = 'Luar biasa! Energi dominan masing-masing dari kalian adalah elemen penyeimbang (Yong Shen) bagi pasangannya. Kehadiran kalian saling menyembuhkan dan menyetabilkan emosi.';
	} else if (isComplementary) {
		compLabel = 'Saling Melengkapi (Komplementer)';
		compDesc = 'Salah satu pilar energi dari kalian mampu menyuplai elemen penting yang dibutuhkan pasangannya, memberikan rasa aman dan kenyamanan mental.';
	}

	// 6. Score Calculation
	let score = 60; // Base lebih konservatif — mencerminkan analisis terbatas (3 dari 8 pilar)
	if (dmType === 'combination') score += 12;
	if (dmType === 'clash') score -= 8;
	if (dmType === 'same_element') score += 2;
	if (spType === 'harmony') score += 15;
	if (spType === 'clash') score -= 12;
	if (mpType === 'harmony') score += 6;
	if (mpType === 'clash') score -= 5;
	if (zType === 'harmony') score += 8;
	if (zType === 'clash') score -= 6;
	if (p1HelpsP2 && p2HelpsP1) score += 12;
	else if (isComplementary) score += 6;

	score = Math.max(40, Math.min(98, score));

	return {
		dayMasterMatch: { type: dmType, label: dmLabel, description: dmDesc },
		spousePalaceMatch: { type: spType, label: spLabel, description: spDesc },
		monthPillarMatch: { type: mpType, label: mpLabel, description: mpDesc },
		zodiacMatch: { type: zType, label: zLabel, description: zDesc },
		elementCompatibility: { type: isComplementary ? 'complementary' : 'non-complementary', label: compLabel, description: compDesc },
		compatibilityScore: Math.round(score),
	};
}
