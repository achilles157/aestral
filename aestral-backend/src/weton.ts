/**
 * Weton (Javanese calendar) calculation engine.
 *
 * Provides Saptawara (7-day), Pancawara (5-day), and Wuku (30-week)
 * cycle lookups, plus neptu-based daily insight calculations.
 */

import JAM_INSIGHT from './data/jam-insight.json';

// --- Saptawara (7-day cycle) ---

const SAPTAWARA_NAMES = [
	'Senin',
	'Selasa',
	'Rabu',
	'Kamis',
	'Jumat',
	'Sabtu',
	'Minggu',
] as const;

const SAPTAWARA_NEPTU: Record<string, number> = {
	Minggu: 5,
	Senin: 4,
	Selasa: 3,
	Rabu: 7,
	Kamis: 8,
	Jumat: 6,
	Sabtu: 9,
};

// --- Pancawara (5-day cycle) ---

const PANCAWARA_NAMES = ['Legi', 'Pahing', 'Pon', 'Wage', 'Kliwon'] as const;

const PANCAWARA_NEPTU: Record<string, number> = {
	Kliwon: 8,
	Legi: 5,
	Pahing: 9,
	Pon: 7,
	Wage: 4,
};

// --- Wuku (30-week cycle, 210 days) ---

const WUKU_NAMES = [
	'Sinta',
	'Landep',
	'Wukir',
	'Kurantil',
	'Tolu',
	'Gumbreg',
	'Warigalit',
	'Warigagung',
	'Julungwangi',
	'Sungsang',
	'Galungan',
	'Kuningan',
	'Langkir',
	'Mandasiya',
	'Julungpujut',
	'Pahang',
	'Kuruwelut',
	'Marakeh',
	'Tambir',
	'Medangkungan',
	'Maktal',
	'Wuye',
	'Manahil',
	'Prangbakat',
	'Bala',
	'Wugu',
	'Wayang',
	'Kulawu',
	'Dukut',
	'Watugunung',
] as const;

// --- Fase mapping ---

const FASE_MAP: Record<number, string> = {
	1: 'Sandang',
	2: 'Pangan',
	3: 'Gedhong',
	4: 'Loro',
	0: 'Pati',
};

// --- Core functions ---

/**
 * Converts a Gregorian date to Julian Day Number.
 */
export function dateToJdn(year: number, month: number, day: number): number {
	let y = year;
	let m = month;
	if (m <= 2) {
		y -= 1;
		m += 12;
	}
	const a = Math.floor(y / 100);
	const b = 2 - a + Math.floor(a / 4);
	return (
		Math.floor(365.25 * (y + 4716)) +
		Math.floor(30.6001 * (m + 1)) +
		day +
		b -
		1524
	);
}

/**
 * Returns the Saptawara (7-day Javanese weekday) for a given JDN.
 */
export function getSaptawara(jdn: number): { name: string; neptu: number } {
	const idx = ((jdn % 7) + 7) % 7; // safe modulo
	const name = SAPTAWARA_NAMES[idx];
	return { name, neptu: SAPTAWARA_NEPTU[name] };
}

/**
 * Returns the Pancawara (5-day Javanese market day) for a given JDN.
 */
export function getPancawara(jdn: number): { name: string; neptu: number } {
	const idx = ((jdn % 5) + 5) % 5; // safe modulo
	const name = PANCAWARA_NAMES[idx];
	return { name, neptu: PANCAWARA_NEPTU[name] };
}

/**
 * Returns the Wuku (30-week cycle) for a given JDN.
 */
export function getWuku(jdn: number): { index: number; name: string } {
	const dayInCycle = ((jdn + 64) % 210 + 210) % 210; // safe modulo
	const index = Math.floor(dayInCycle / 7);
	return { index, name: WUKU_NAMES[index] };
}

/**
 * Total neptu = saptawara neptu + pancawara neptu.
 */
export function calculateTotalNeptu(jdn: number): number {
	return getSaptawara(jdn).neptu + getPancawara(jdn).neptu;
}

/**
 * Sisa bagi: (totalNeptu(birth) + totalNeptu(target)) mod 5.
 * Maps to phases: 1=Sandang, 2=Pangan, 3=Gedhong, 4=Loro, 0=Pati.
 */
export function calculateSisaBagi(
	birthJdn: number,
	targetJdn: number,
): number {
	return (calculateTotalNeptu(birthJdn) + calculateTotalNeptu(targetJdn)) % 5;
}

/**
 * Returns Javanese hours (Saat Pitu/Saat Lima) that are considered favorable (jamBaik)
 * or unfavorable (jamNaas) based on the target day's Saptawara name.
 * Data source: src/data/jam-insight.json
 */
export function getJamInsight(saptawaraName: string): { jamBaik: string[]; jamNaas: string[] } {
	const entry = (JAM_INSIGHT as Record<string, { jamBaik: string[]; jamNaas: string[] }>)[saptawaraName];
	return entry ?? { jamBaik: [], jamNaas: [] };
}

/**
 * Returns the Pranata Mangsa ID (1-12) for a given Gregorian date (year, month, day).
 * Handles leap years (wastu) correctly for February (Kawolu ending).
 */
export function getPranataMangsaId(year: number, month: number, day: number): number {
	const isKabisat = year % 4 === 0;
	const md = month * 100 + day;

	if (md >= 622 && md <= 801) return 1;   // Kasa: 22 Juni - 1 Agustus
	if (md >= 802 && md <= 824) return 2;   // Karo: 2 Agustus - 24 Agustus
	if (md >= 825 && md <= 917) return 3;   // Katiga: 25 Agustus - 17 September
	if (md >= 918 && md <= 1012) return 4;  // Kapat: 18 September - 12 Oktober
	if (md >= 1013 && md <= 1108) return 5; // Kalima: 13 Oktober - 8 November
	if (md >= 1109 && md <= 1221) return 6; // Kanem: 9 November - 21 Desember
	
	// Crossing the year boundary: Kapitu starts 22 Dec and ends 2 Feb
	if (md >= 1222 || md <= 202) return 7;  // Kapitu: 22 Desember - 2 Februari
	
	const kawoluEnd = isKabisat ? 229 : 228;
	if (md >= 203 && md <= kawoluEnd) return 8; // Kawolu: 3 Februari - 28/29 Februari
	
	if (md >= 301 && md <= 325) return 9;   // Kasanga: 1 Maret - 25 Maret
	if (md >= 326 && md <= 418) return 10;  // Kadasa: 26 Maret - 18 April
	if (md >= 419 && md <= 511) return 11;  // Dhesta: 19 April - 11 Mei
	if (md >= 512 && md <= 621) return 12;  // Sada: 12 Mei - 21 Juni
	
	return 12; // Fallback
}

/**
 * Full weton insight for a birth date and target date.
 *
 * @param birthDate  - format YYYY-MM-DD
 * @param targetDate - format YYYY-MM-DD
 */
export function getWetonInsight(
	birthDate: string,
	targetDate: string,
): {
	birthWeton: {
		saptawara: string;
		pancawara: string;
		totalNeptu: number;
		wuku: string;
		pranataMangsaId: number;
	};
	targetWeton: {
		saptawara: string;
		pancawara: string;
		totalNeptu: number;
		wuku: string;
		pranataMangsaId: number;
	};
	daily: {
		sisaBagi: number;
		fase: string;
		statusHari: string;
		hariBaik: boolean;
		hariNaasLahir: string;
		jamBaik: string[];
		jamNaas: string[];
	};
	weekly: {
		wukuIndex: number;
		wukuName: string;
	};
} {
	const [by, bm, bd] = birthDate.split('-').map(Number);
	const [ty, tm, td] = targetDate.split('-').map(Number);

	const birthJdn = dateToJdn(by, bm, bd);
	const targetJdn = dateToJdn(ty, tm, td);

	const birthSapta = getSaptawara(birthJdn);
	const birthPanca = getPancawara(birthJdn);
	const birthWuku = getWuku(birthJdn);

	const targetSapta = getSaptawara(targetJdn);
	const targetPanca = getPancawara(targetJdn);
	const targetWuku = getWuku(targetJdn);

	const sisaBagi = calculateSisaBagi(birthJdn, targetJdn);
	
	// Favorable if Sandang, Pangan, or Gedhong
	const isFavorable = [1, 2, 3].includes(sisaBagi);
	const statusHari = isFavorable ? 'Hari Favorable / Kondusif' : 'Hari Refleksi / Waspada';
	const birthWetonName = `${birthSapta.name} ${birthPanca.name}`;

	const hours = getJamInsight(targetSapta.name);

	const birthPranataId = getPranataMangsaId(by, bm, bd);
	const targetPranataId = getPranataMangsaId(ty, tm, td);

	return {
		birthWeton: {
			saptawara: birthSapta.name,
			pancawara: birthPanca.name,
			totalNeptu: calculateTotalNeptu(birthJdn),
			wuku: birthWuku.name,
			pranataMangsaId: birthPranataId,
		},
		targetWeton: {
			saptawara: targetSapta.name,
			pancawara: targetPanca.name,
			totalNeptu: calculateTotalNeptu(targetJdn),
			wuku: targetWuku.name,
			pranataMangsaId: targetPranataId,
		},
		daily: {
			sisaBagi,
			fase: FASE_MAP[sisaBagi],
			statusHari,
			hariBaik: isFavorable,
			hariNaasLahir: birthWetonName,
			jamBaik: hours.jamBaik,
			jamNaas: hours.jamNaas,
		},
		weekly: {
			wukuIndex: targetWuku.index,
			wukuName: targetWuku.name,
		},
	};
}
