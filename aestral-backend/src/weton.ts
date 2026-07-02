/**
 * Weton (Javanese calendar) calculation engine.
 *
 * Provides Saptawara (7-day), Pancawara (5-day), and Wuku (30-week)
 * cycle lookups, plus neptu-based daily insight calculations.
 */

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
 */
export function getJamInsight(saptawaraName: string): { jamBaik: string[]; jamNaas: string[] } {
	switch (saptawaraName) {
		case 'Minggu':
			return {
				jamBaik: ['06:00 - 08:24 (Saat Rezeki)', '10:48 - 13:12 (Saat Gedhong)'],
				jamNaas: ['08:24 - 10:48 (Saat Loro)', '13:12 - 15:36 (Saat Pati)'],
			};
		case 'Senin':
			return {
				jamBaik: ['08:24 - 10:48 (Saat Rezeki)', '13:12 - 15:36 (Saat Gedhong)'],
				jamNaas: ['06:00 - 08:24 (Saat Loro)', '10:48 - 13:12 (Saat Pati)'],
			};
		case 'Selasa':
			return {
				jamBaik: ['10:48 - 13:12 (Saat Rezeki)', '15:36 - 18:00 (Saat Gedhong)'],
				jamNaas: ['08:24 - 10:48 (Saat Loro)', '13:12 - 15:36 (Saat Pati)'],
			};
		case 'Rabu':
			return {
				jamBaik: ['06:00 - 08:24 (Saat Rezeki)', '13:12 - 15:36 (Saat Gedhong)'],
				jamNaas: ['10:48 - 13:12 (Saat Loro)', '15:36 - 18:00 (Saat Pati)'],
			};
		case 'Kamis':
			return {
				jamBaik: ['08:24 - 10:48 (Saat Rezeki)', '15:36 - 18:00 (Saat Gedhong)'],
				jamNaas: ['06:00 - 08:24 (Saat Loro)', '13:12 - 15:36 (Saat Pati)'],
			};
		case 'Jumat':
			return {
				jamBaik: ['06:00 - 08:24 (Saat Rezeki)', '10:48 - 13:12 (Saat Gedhong)'],
				jamNaas: ['08:24 - 10:48 (Saat Loro)', '15:36 - 18:00 (Saat Pati)'],
			};
		case 'Sabtu':
			return {
				jamBaik: ['08:24 - 10:48 (Saat Rezeki)', '13:12 - 15:36 (Saat Gedhong)'],
				jamNaas: ['06:00 - 08:24 (Saat Loro)', '10:48 - 13:12 (Saat Pati)'],
			};
		default:
			return { jamBaik: [], jamNaas: [] };
	}
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
	};
	targetWeton: {
		saptawara: string;
		pancawara: string;
		totalNeptu: number;
		wuku: string;
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

	return {
		birthWeton: {
			saptawara: birthSapta.name,
			pancawara: birthPanca.name,
			totalNeptu: calculateTotalNeptu(birthJdn),
			wuku: birthWuku.name,
		},
		targetWeton: {
			saptawara: targetSapta.name,
			pancawara: targetPanca.name,
			totalNeptu: calculateTotalNeptu(targetJdn),
			wuku: targetWuku.name,
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
