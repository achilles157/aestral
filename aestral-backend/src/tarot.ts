/**
 * Tarot card drawing logic with Ba Zi Wu Xing weighting.
 *
 * Provides deterministic card selection weighted by:
 *   - Weton: pangarasan element → remedial element boost
 *   - Ba Zi: Day Master resonance + Wu Xing compensation + yin/yang polarity
 *   - Konteks: Mangsa/Wuku seasonal energy
 *
 * Deck layout (78 cards):
 *   0-21  = Major Arcana (Kayu / Spirit)
 *  22-35  = Cups      (Air / Water)
 *  36-49  = Wands     (Api / Fire)
 *  50-63  = Swords    (Logam / Metal)
 *  64-77  = Pentacles (Tanah / Earth)
 */

import {
	STEM_ELEMENTS,
	BRANCH_ELEMENTS,
	CONTROLS,
	GENERATES,
	calculateBaziChart,
	type BaziChartResult,
} from './bazi';

const DECK_SIZE = 78;

// ─── Types ─────────────────────────────────────────────────────────────────

type Element = 'fire' | 'water' | 'air' | 'earth';

export interface DrawnCardInfo {
	cardIndex: number;
	isReversed: boolean;
	label: string;
	/** Why this card was drawn (for AI synthesis / transparency) */
	reasoning?: string[];
}

/** Ba Zi context passed from client for weighting */
export interface BaziWeightingContext {
	dayMasterElement?: string;
	dayMasterPolarity?: 'yin' | 'yang';
	yongShen?: string[];
	wuXingDominant?: string;
}

// ─── Element Mapping ──────────────────────────────────────────────────────

/** Tarot suit → Wu Xing element */
const SUIT_WUXING: Record<string, string> = {
	water: 'air',   // Cups     → Air (matches existing backend convention)
	fire:  'api',   // Wands    → Api
	air:   'logam', // Swords   → Logam
	earth: 'tanah', // Pentacles→ Tanah
};

/** Wu Xing → Tarot suit element */
const WUXING_TO_TAROT: Record<string, string> = {
	kayu:  'neutral',
	api:   'fire',
	tanah: 'earth',
	logam: 'air',
	air:   'water',
};

/** Card index ranges per Tarot element */
function getElementRange(el: string): [number, number] {
	switch (el) {
		case 'water':     return [22, 35]; // Cups
		case 'fire':      return [36, 49]; // Wands
		case 'air':       return [50, 63]; // Swords
		case 'earth':     return [64, 77]; // Pentacles
		case 'neutral':   return [0,  21]; // Major Arcana
		default:          return [0,  DECK_SIZE - 1];
	}
}

// ─── Pangarasan → Element ────────────────────────────────────────────────

function pangarasanToElement(pangarasan: string): Element | null {
	const lower = pangarasan.toLowerCase();
	if (lower.includes('geni') || lower.includes('lintang')) return 'fire';
	if (lower.includes('banyu') || lower.includes('rembulan')) return 'water';
	if (lower.includes('angin')) return 'air';
	if (lower.includes('bumi') || lower.includes('kembang')) return 'earth';
	return null;
}

/** Opposite element for remedial weighting (homeostasis principle) */
function getRemedialRange(el: Element): [number, number] {
	switch (el) {
		case 'fire':  return [22, 35]; // boost Water
		case 'water': return [36, 49]; // boost Fire
		case 'air':   return [64, 77]; // boost Earth
		case 'earth': return [50, 63]; // boost Air
	}
}

// ─── Mangsa → Element ────────────────────────────────────────────────────

function mangsaToTarotElement(id: number): string {
	switch (id) {
		case 1:  return 'neutral';
		case 2:  return 'water';
		case 3:  return 'air';
		case 4:  return 'water';
		case 5:  return 'earth';
		case 6:  return 'neutral';
		case 7:  return 'air';
		case 8:  return 'fire';
		case 9:  return 'fire';
		case 10: return 'earth';
		case 11: return 'water';
		case 12: return 'neutral';
		default: return 'neutral';
	}
}

function wukuToTarotElement(wuku: string): string {
	const lower = wuku.toLowerCase().trim();
	const wukus = [
		'sinta','landep','wukir','kurantil','tolu','gumbreg',
		'warigalit','warigagung','julungwangi','sungsang',
		'galungan','kuningan','langkir','mandasiya','julungpujut',
		'pahang','kuruwelut','marakeh','tambir','medangkungan',
		'maktal','wuye','manahil','prangbakat','bala',
		'wugu','wayang','kulawu','dukut','watugunung',
	];
	const idx = wukus.indexOf(lower);
	if (idx === -1) return 'neutral';
	const mapping = ['neutral','fire','water','air','earth','neutral'];
	return mapping[idx % 6] ?? 'neutral';
}

// ─── Ba Zi Weighting Engine ───────────────────────────────────────────────

/**
 * Applies Wu Xing resonance & compensation to card weights.
 *
 * Resonance (生): Cards whose Tarot element generates or matches the
 *   Day Master element get +0.5 weight.
 *
 * Compensation (克): Cards whose Tarot element controls the dominant
 *   Wu Xing element get +0.4 weight.
 *
 * Yong Shen bonus: Cards matching yongShen elements get +0.6 weight.
 */
function applyBaziWeights(
	weights: Float64Array,
	bazi: BaziWeightingContext,
	reasons: string[],
): void {
	if (!bazi.dayMasterElement) return;

	const dm = bazi.dayMasterElement.toLowerCase();

	// Resonance: card element === Day Master element or card element
	// generates Day Master → +0.5
	const resonanceTarot = WUXING_TO_TAROT[dm];
	const generatedBy = Object.entries(GENERATES).find(([, v]) => v === dm)?.[0];

	for (let i = 0; i < DECK_SIZE; i++) {
		const cardEl = getCardElement(i);

		if (resonanceTarot === cardEl) {
			weights[i] += 0.5;
		}

		if (generatedBy && WUXING_TO_TAROT[generatedBy] === cardEl) {
			weights[i] += 0.3;
		}
	}
	if (resonanceTarot || generatedBy) {
		reasons.push(
			`Day Master ${dm} beresonansi dengan kartu beraliran ${resonanceTarot ?? WUXING_TO_TAROT[generatedBy!]}`,
		);
	}

	// Compensation: cards that control the dominant element → +0.4
	if (bazi.wuXingDominant) {
		const dom = bazi.wuXingDominant.toLowerCase();
		const controllerTarot = WUXING_TO_TAROT[CONTROLS[dom]] ?? WUXING_TO_TAROT[dom];
		const [cs, ce] = getElementRange(controllerTarot);
		for (let i = cs; i <= ce; i++) {
			weights[i] += 0.4;
		}
		reasons.push(`Wu Xing dominan ${dom} dikompensasi kartu ${controllerTarot}`);
	}

	// Yong Shen bonus: highest priority → +0.6
	if (bazi.yongShen && bazi.yongShen.length > 0) {
		for (const ys of bazi.yongShen) {
			const ysTarot = WUXING_TO_TAROT[ys.toLowerCase()];
			if (!ysTarot) continue;
			const [ysStart, ysEnd] = getElementRange(ysTarot);
			for (let i = ysStart; i <= ysEnd; i++) {
				weights[i] += 0.6;
			}
		}
		reasons.push(`Yong Shen [${bazi.yongShen.join(', ')}] memperkuat kartu terkait`);
	}
}

/** Returns which Tarot element a card index belongs to */
function getCardElement(cardIndex: number): string {
	if (cardIndex <= 21) return 'neutral';    // Major Arcana
	if (cardIndex <= 35) return 'water';      // Cups
	if (cardIndex <= 49) return 'fire';        // Wands
	if (cardIndex <= 63) return 'air';         // Swords
	return 'earth';                            // Pentacles
}

// ─── Core Drawing Functions ───────────────────────────────────────────────

function hashSeed(seedStr: string): number {
	let hash = 0;
	for (let i = 0; i < seedStr.length; i++) {
		hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
	}
	return Math.abs(hash);
}

function drawSingleDeterministicCard(seedStr: string, weights: Float64Array): number {
	let totalWeight = 0;
	for (let i = 0; i < DECK_SIZE; i++) totalWeight += weights[i];

	const h = hashSeed(seedStr);
	const randVal = (h % 10000) / 10000;
	let pick = randVal * totalWeight;

	for (let i = 0; i < DECK_SIZE; i++) {
		if (weights[i] > 0) {
			pick -= weights[i];
			if (pick <= 0) { weights[i] = 0; return i; }
		}
	}
	for (let i = 0; i < DECK_SIZE; i++) {
		if (weights[i] > 0) { weights[i] = 0; return i; }
	}
	return DECK_SIZE - 1;
}

function getIsReversedDeterministic(seedStr: string): boolean {
	return hashSeed(seedStr) % 2 === 0;
}

// ─── Public API ───────────────────────────────────────────────────────────

/** Soul blueprint: 1 kartu seumur hidup */
export function getDeterministicCard(
	birthDate: string,
	pangarasan?: string,
	bazi?: BaziWeightingContext,
): { cardIndex: number; isReversed: boolean; reasoning: string[] } {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);
	const reasons: string[] = [];

	if (pangarasan) {
		const userEl = pangarasanToElement(pangarasan);
		if (userEl) {
			const [s, e] = getRemedialRange(userEl);
			for (let i = s; i <= e; i++) weights[i] += 0.15;
			reasons.push(`Pangarasan ${pangarasan} → kartu ${userEl} remedial`);
		}
	}

	if (bazi) applyBaziWeights(weights, bazi, reasons);

	const seed = birthDate + '-soul-' + (bazi?.dayMasterElement ?? '');
	const cardIndex = drawSingleDeterministicCard(seed, weights);

	// Yin polarity → reversed more likely (respecting birth chart nature)
	const reversedSeed = birthDate + '-rev-' + (bazi?.dayMasterPolarity ?? '');
	const isReversed = bazi?.dayMasterPolarity === 'yin'
		? getIsReversedDeterministic(reversedSeed)
		: false;

	return { cardIndex, isReversed, reasoning: reasons };
}

/** Birth tarot: 3 kartu Past/Present/Future — guest & registered */
export function getDeterministicThreeCards(
	birthDate: string,
	pangarasan?: string,
	bazi?: BaziWeightingContext,
): DrawnCardInfo[] {
	function buildWeights(): Float64Array {
		const w = new Float64Array(DECK_SIZE).fill(1.0);
		if (pangarasan) {
			const userEl = pangarasanToElement(pangarasan);
			if (userEl) {
				const [s, e] = getRemedialRange(userEl);
				for (let i = s; i <= e; i++) w[i] += 0.15;
			}
		}
		if (bazi) applyBaziWeights(w, bazi, []);
		return w;
	}

	const w = buildWeights();
	const pastIdx = drawSingleDeterministicCard(birthDate + '-past', new Float64Array(w));
	const pastRev = getIsReversedDeterministic(birthDate + '-past-rev');

	const w2 = buildWeights(); w2[pastIdx] = 0;
	const presIdx = drawSingleDeterministicCard(birthDate + '-present', w2);
	const presRev = getIsReversedDeterministic(birthDate + '-present-rev');

	const w3 = buildWeights(); w3[pastIdx] = 0; w3[presIdx] = 0;
	const futIdx = drawSingleDeterministicCard(birthDate + '-future', w3);
	const futRev = getIsReversedDeterministic(birthDate + '-future-rev');

	return [
		{ cardIndex: pastIdx,  isReversed: pastRev,  label: 'past' },
		{ cardIndex: presIdx,  isReversed: presRev,  label: 'present' },
		{ cardIndex: futIdx,   isReversed: futRev,   label: 'future' },
	];
}

/** Mangsa tarot: 2 kartu Energi + Panduan (rebrand dari "Kosmis") */
export function getMangsaTwoCards(
	birthDate: string,
	mangsaId: number,
	pangarasan?: string,
	bazi?: BaziWeightingContext,
): DrawnCardInfo[] {
	const id = Math.max(1, Math.min(12, Math.round(mangsaId)));
	const baseSeed = birthDate + '-mangsa-' + id;

	function buildWeights(bias: string): Float64Array {
		const w = new Float64Array(DECK_SIZE).fill(1.0);
		if (pangarasan) {
			const userEl = pangarasanToElement(pangarasan);
			if (userEl) {
				const [s, e] = getRemedialRange(userEl);
				for (let i = s; i <= e; i++) w[i] += 0.15;
			}
		}
		if (bazi) applyBaziWeights(w, bazi, []);
		// Mangsa theme boost
		const mangsaEl = mangsaToTarotElement(id);
		if (mangsaEl === 'neutral') {
			for (let i = 0; i <= 21; i++) w[i] += 0.18;
		} else {
			const [ms, me] = getElementRange(mangsaEl);
			for (let i = ms; i <= me; i++) w[i] += 0.18;
		}
		// Extra bias for specific slot
		if (bias === 'energy') {
			for (let i = 36; i <= 49; i++) w[i] += 0.10; // Wands for energy
		} else if (bias === 'guidance') {
			for (let i = 0; i <= 21; i++) w[i] += 0.10;  // Major Arcana for guidance
		}
		return w;
	}

	const eWeights = buildWeights('energy');
	const eIdx = drawSingleDeterministicCard(baseSeed + '-energy', eWeights);
	const eRev = getIsReversedDeterministic(baseSeed + '-energy-rev');

	const gWeights = buildWeights('guidance'); gWeights[eIdx] = 0;
	const gIdx = drawSingleDeterministicCard(baseSeed + '-guidance', gWeights);
	const gRev = getIsReversedDeterministic(baseSeed + '-guidance-rev');

	return [
		{ cardIndex: eIdx, isReversed: eRev, label: 'energy' },
		{ cardIndex: gIdx, isReversed: gRev, label: 'guidance' },
	];
}

/** Original 3-card mangsa spread kept for backward compat */
export function getMangsaDeterministicThreeCards(
	birthDate: string,
	currentCycleId: number,
	pangarasan?: string,
	bazi?: BaziWeightingContext,
): DrawnCardInfo[] {
	const id = Math.max(1, Math.min(12, Math.round(currentCycleId)));
	const prevId = id === 1 ? 12 : id - 1;
	const nextId = id === 12 ? 1 : id + 1;
	const baseSeed = birthDate + '-cosmic-' + id;

	function buildWeights(cId: number, exclude: number[]): Float64Array {
		const w = new Float64Array(DECK_SIZE).fill(1.0);
		if (pangarasan) {
			const userEl = pangarasanToElement(pangarasan);
			if (userEl) {
				const [s, e] = getRemedialRange(userEl);
				for (let i = s; i <= e; i++) w[i] += 0.15;
			}
		}
		if (bazi) applyBaziWeights(w, bazi, []);
		const el = mangsaToTarotElement(cId);
		if (el === 'neutral') {
			for (let i = 0; i <= 21; i++) w[i] += 0.18;
		} else {
			const [ms, me] = getElementRange(el);
			for (let i = ms; i <= me; i++) w[i] += 0.18;
		}
		for (const idx of exclude) w[idx] = 0;
		return w;
	}

	const pw = buildWeights(prevId, []);
	const pastIdx = drawSingleDeterministicCard(baseSeed + '-past', pw);
	const pastRev = getIsReversedDeterministic(baseSeed + '-past-rev');

	const cw = buildWeights(id, [pastIdx]);
	const presIdx = drawSingleDeterministicCard(baseSeed + '-present', cw);
	const presRev = getIsReversedDeterministic(baseSeed + '-present-rev');

	const nw = buildWeights(nextId, [pastIdx, presIdx]);
	const futIdx = drawSingleDeterministicCard(baseSeed + '-future', nw);
	const futRev = getIsReversedDeterministic(baseSeed + '-future-rev');

	return [
		{ cardIndex: pastIdx, isReversed: pastRev, label: 'past' },
		{ cardIndex: presIdx, isReversed: presRev, label: 'present' },
		{ cardIndex: futIdx,  isReversed: futRev,  label: 'future' },
	];
}

// ─── Tarot Momen Kosmis (Phase 3A) ────────────────────────────────────────

/** Event types for Momen Kosmis trigger */
export type MomentEventType = 'hari_weton' | 'dino_was' | 'bazi_clash' | 'yong_shen';

const REFLECTIVE_CARD_INDICES = [
	9,   // The Hermit
	2,   // The High Priestess
	18,  // The Moon
	12,  // The Hanged Man
	13,  // Death
	20,  // Judgement
];

/**
 * Single-card draw for Momen Kosmis — event-driven, 2-4x/month.
 *
 * Weighting per event type:
 *   - hari_weton: Major Arcana +0.5 (hari sakral)
 *   - dino_was:   Reflective cards +0.6 (Hermit, High Priestess, Moon, etc.)
 *   - bazi_clash: Elemental opposite +0.4 (kartu yang elemennya mengontrol DM)
 *   - yong_shen:  Yong Shen element +0.7 (harmoni maksimal)
 */
export function getMomentCard(
	birthDate: string,
	eventType: MomentEventType,
	bazi?: BaziWeightingContext,
): { cardIndex: number; isReversed: boolean; eventType: string; reasoning: string[] } {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);
	const reasons: string[] = [];

	switch (eventType) {
		case 'hari_weton': {
			// Hari Weton = hari sakral, Major Arcana lebih mungkin muncul
			for (let i = 0; i <= 21; i++) weights[i] += 0.5;
			reasons.push('Hari Weton — Major Arcana diperkuat sebagai cerminan sakral');
			break;
		}
		case 'dino_was': {
			// Dino Was = hari reflektif, kartu kontemplatif lebih mungkin
			for (const idx of REFLECTIVE_CARD_INDICES) weights[idx] += 0.6;
			reasons.push('Dino Was — kartu reflektif diperkuat untuk kontemplasi diri');
			break;
		}
		case 'bazi_clash': {
			// Ba Zi Clash = elemen yang mengontrol Day Master
			if (bazi?.dayMasterElement && bazi.wuXingDominant) {
				const dm = bazi.dayMasterElement.toLowerCase();
				const controller = CONTROLS[dm] ?? CONTROLS[bazi.wuXingDominant.toLowerCase()];
				if (controller) {
					const tarotEl = WUXING_TO_TAROT[controller];
					const [cs, ce] = getElementRange(tarotEl);
					for (let i = cs; i <= ce; i++) weights[i] += 0.4;
					reasons.push(`Ba Zi Clash — elemen ${controller} (${tarotEl}) mengontrol Day Master ${dm}`);
				}
			}
			break;
		}
		case 'yong_shen': {
			// Yong Shen Day = elemen harmonis diperkuat
			if (bazi?.yongShen && bazi.yongShen.length > 0) {
				for (const ys of bazi.yongShen) {
					const ysTarot = WUXING_TO_TAROT[ys.toLowerCase()];
					if (!ysTarot) continue;
					const [ysStart, ysEnd] = getElementRange(ysTarot);
					for (let i = ysStart; i <= ysEnd; i++) weights[i] += 0.7;
				}
				reasons.push(`Yong Shen [${bazi.yongShen.join(', ')}] — harmoni maksimal, kartu resonan diperkuat`);
			}
			break;
		}
	}

	// Always apply Ba Zi resonance for additional personalization
	if (bazi) applyBaziWeights(weights, bazi, reasons);

	const seed = `${birthDate}-moment-${eventType}-${new Date().toISOString().split('T')[0]}`;
	const cardIndex = drawSingleDeterministicCard(seed, weights);
	const isReversed = getIsReversedDeterministic(seed + '-rev');

	return { cardIndex, isReversed, eventType, reasoning: reasons };
}

// ─── Tarot Tematik (Phase 3B) ─────────────────────────────────────────────

/** Life areas for thematic tarot */
export type ThematicArea = 'karir' | 'asmara' | 'keuangan' | 'spiritual' | 'kesehatan';

/** Area → dominant/support element mapping (from blueprint 3.3) */
const AREA_ELEMENTS: Record<ThematicArea, { dominant: string; support: string }> = {
	karir:     { dominant: 'fire',  support: 'air'   }, // Wands + Swords
	asmara:    { dominant: 'water', support: 'earth' }, // Cups + Pentacles
	keuangan:  { dominant: 'earth', support: 'air'   }, // Pentacles + Swords
	spiritual: { dominant: 'major', support: 'water' }, // Major Arcana + Cups
	kesehatan: { dominant: 'major', support: 'earth' }, // Major Arcana + Pentacles
};

/** Position labels per area (from blueprint 3.3) */
const AREA_POSITIONS: Record<ThematicArea, [string, string, string]> = {
	karir:     ['potensi', 'tantangan', 'arah'],
	asmara:    ['daya_tarik', 'bayangan', 'langkah'],
	keuangan:  ['sumber', 'kebocoran', 'strategi'],
	spiritual: ['panggilan', 'rintangan', 'pesan'],
	kesehatan: ['vitalitas', 'kelemahan', 'ritme'],
};

/**
 * Thematic tarot: 3 kartu dengan bias area hidup spesifik.
 *
 * Bobot: Weton + Ba Zi + Area (dominant +0.35, support +0.20).
 * Seed per slot: birthDate + area + slot + day (deterministic per hari).
 */
export function getThematicThreeCards(
	birthDate: string,
	area: ThematicArea,
	pangarasan?: string,
	bazi?: BaziWeightingContext,
): DrawnCardInfo[] {
	const areaCfg = AREA_ELEMENTS[area];
	const positions = AREA_POSITIONS[area];

	function buildWeights(exclude: number[]): Float64Array {
		const w = new Float64Array(DECK_SIZE).fill(1.0);

		if (pangarasan) {
			const userEl = pangarasanToElement(pangarasan);
			if (userEl) {
				const [s, e] = getRemedialRange(userEl);
				for (let i = s; i <= e; i++) w[i] += 0.15;
			}
		}

		if (bazi) applyBaziWeights(w, bazi, []);

		// Area bias — dominant +0.35, support +0.20
		const [dStart, dEnd] = getElementRange(areaCfg.dominant);
		for (let i = dStart; i <= dEnd; i++) w[i] += 0.35;
		const [sStart, sEnd] = getElementRange(areaCfg.support);
		for (let i = sStart; i <= sEnd; i++) w[i] += 0.20;

		for (const idx of exclude) w[idx] = 0;
		return w;
	}

	// Deterministic per hari — reseed setiap hari agar user bisa draw ulang besok
	const day = new Date().toISOString().split('T')[0];
	const baseSeed = `${birthDate}-${area}-${day}`;

	const w1 = buildWeights([]);
	const idx1 = drawSingleDeterministicCard(baseSeed + '-1', w1);
	const rev1 = getIsReversedDeterministic(baseSeed + '-1-rev');

	const w2 = buildWeights([idx1]);
	const idx2 = drawSingleDeterministicCard(baseSeed + '-2', w2);
	const rev2 = getIsReversedDeterministic(baseSeed + '-2-rev');

	const w3 = buildWeights([idx1, idx2]);
	const idx3 = drawSingleDeterministicCard(baseSeed + '-3', w3);
	const rev3 = getIsReversedDeterministic(baseSeed + '-3-rev');

	return [
		{ cardIndex: idx1, isReversed: rev1, label: positions[0] },
		{ cardIndex: idx2, isReversed: rev2, label: positions[1] },
		{ cardIndex: idx3, isReversed: rev3, label: positions[2] },
	];
}

/** Weekly Wuku tarot */
export function getWeeklyDeterministicThreeCards(
	birthDate: string,
	wuku: string,
	pangarasan?: string,
	bazi?: BaziWeightingContext,
): DrawnCardInfo[] {
	const baseSeed = birthDate + '-weekly-' + wuku.toLowerCase();

	function buildWeights(exclude: number[]): Float64Array {
		const w = new Float64Array(DECK_SIZE).fill(1.0);
		if (pangarasan) {
			const userEl = pangarasanToElement(pangarasan);
			if (userEl) {
				const [s, e] = getRemedialRange(userEl);
				for (let i = s; i <= e; i++) w[i] += 0.15;
			}
		}
		if (bazi) applyBaziWeights(w, bazi, []);
		const el = wukuToTarotElement(wuku);
		if (el === 'neutral') {
			for (let i = 0; i <= 21; i++) w[i] += 0.20;
		} else {
			const [ms, me] = getElementRange(el);
			for (let i = ms; i <= me; i++) w[i] += 0.20;
		}
		for (const idx of exclude) w[idx] = 0;
		return w;
	}

	const pw = buildWeights([]);
	const pastIdx = drawSingleDeterministicCard(baseSeed + '-past', pw);
	const pastRev = getIsReversedDeterministic(baseSeed + '-past-rev');

	const cw = buildWeights([pastIdx]);
	const presIdx = drawSingleDeterministicCard(baseSeed + '-present', cw);
	const presRev = getIsReversedDeterministic(baseSeed + '-present-rev');

	const nw = buildWeights([pastIdx, presIdx]);
	const futIdx = drawSingleDeterministicCard(baseSeed + '-future', nw);
	const futRev = getIsReversedDeterministic(baseSeed + '-future-rev');

	return [
		{ cardIndex: pastIdx, isReversed: pastRev, label: 'past' },
		{ cardIndex: presIdx, isReversed: presRev, label: 'present' },
		{ cardIndex: futIdx,  isReversed: futRev,  label: 'future' },
	];
}
