/**
 * Tarot card drawing logic.
 *
 * Provides deterministic (soul card) and weighted-random (daily draw)
 * card selection for the Aestral app.
 *
 * Deck layout (78 cards):
 *   0-21  = Major Arcana
 *  22-35  = Cups      (Water)
 *  36-49  = Wands     (Fire)
 *  50-63  = Swords    (Air)
 *  64-77  = Pentacles (Earth)
 */

const DECK_SIZE = 78;

// --- Deterministic Soul Card ---

/**
 * Returns a deterministic card index (0-77) for a given birthDate string.
 *
 * Uses a simple hash: for each character, `hash = charCode + ((hash << 5) - hash)`.
 * The same birthDate always produces the same card.
 */
export function getDeterministicCard(birthDate: string, pangarasan?: string): number {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);

	if (pangarasan) {
		const userElement = pangarasanToElement(pangarasan);
		if (userElement) {
			const [start, end] = getRemedialRange(userElement);
			for (let i = start; i <= end; i++) {
				weights[i] += 0.15;
			}
		}
	}

	let totalWeight = 0;
	for (let i = 0; i < DECK_SIZE; i++) {
		totalWeight += weights[i];
	}

	// Deterministic seed based on birthDate
	let hash = 0;
	const seedStr = birthDate + '-soulcard';
	for (let i = 0; i < seedStr.length; i++) {
		hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
	}
	
	const randVal = (Math.abs(hash) % 10000) / 10000;
	let pick = randVal * totalWeight;

	for (let i = 0; i < DECK_SIZE; i++) {
		pick -= weights[i];
		if (pick <= 0) return i;
	}
	return DECK_SIZE - 1;
}

/**
 * Returns a deterministic reversal state (true = reversed, false = upright)
 * for a given birthDate string.
 */
export function getDeterministicReversed(birthDate: string): boolean {
	let hash = 0;
	for (let i = 0; i < birthDate.length; i++) {
		hash = birthDate.charCodeAt(i) + ((hash << 5) - hash) + 13; // offset slightly
	}
	return Math.abs(hash) % 2 === 0;
}

// --- Weighted Random Draw ---

type Element = 'fire' | 'water' | 'air' | 'earth';

/**
 * Maps a Pangarasan (Weton element name) to one of the four classical elements.
 * Returns `null` when no mapping is found.
 */
function pangarasanToElement(pangarasan: string): Element | null {
	const lower = pangarasan.toLowerCase();
	if (lower.includes('geni') || lower.includes('lintang')) return 'fire';
	if (lower.includes('banyu') || lower.includes('rembulan')) return 'water';
	if (lower.includes('angin')) return 'air';
	if (lower.includes('bumi') || lower.includes('kembang')) return 'earth';
	return null;
}

/**
 * Homeostasis: returns the suit index-range that should be boosted
 * for a given user element (the *opposite* element).
 *
 *   Fire  → boost Water  (Cups 22-35)
 *   Water → boost Fire   (Wands 36-49)
 *   Air   → boost Earth  (Pentacles 64-77)
 *   Earth → boost Air    (Swords 50-63)
 */
function getRemedialRange(el: Element): [start: number, end: number] {
	switch (el) {
		case 'fire':
			return [22, 35];
		case 'water':
			return [36, 49];
		case 'air':
			return [64, 77];
		case 'earth':
			return [50, 63];
	}
}

/**
 * Maps a Wuku name to one of the four elements.
 * Returns `null` when no mapping is found.
 */
function wukuToElement(wuku: string): Element | null {
	const lower = wuku.toLowerCase();
	// Standard Javanese deity/nature elements mapping for the 30 Wukus:
	const waterWukus = ['landhep', 'gumbreg', 'galungan', 'kuruwelut', 'wayang', 'kulawu', 'prangbakat', 'bala'];
	const fireWukus = ['sinta', 'kurantil', 'mandasia', 'pahang', 'maktal', 'dhukut'];
	const earthWukus = ['wukir', 'tolu', 'warigagung', 'kuningan', 'marakeh', 'medangkungan', 'manahil', 'watugunung'];
	const airWukus = ['warigalit', 'julungwangi', 'sungsang', 'langkir', 'julungpujut', 'tambir', 'wuye', 'wugu'];

	if (waterWukus.includes(lower)) return 'water';
	if (fireWukus.includes(lower)) return 'fire';
	if (earthWukus.includes(lower)) return 'earth';
	if (airWukus.includes(lower)) return 'air';
	return null;
}

/**
 * Returns the card index range [start, end] for a given element.
 */
function getElementRange(el: Element): [start: number, end: number] {
	switch (el) {
		case 'water':
			return [22, 35]; // Cups (Water)
		case 'fire':
			return [36, 49]; // Wands (Fire)
		case 'air':
			return [50, 63]; // Swords (Air/Metal)
		case 'earth':
			return [64, 77]; // Pentacles (Earth)
	}
}

/**
 * Returns a weighted-random card index (0-77).
 *
 * The user's Pangarasan determines their element; the complementary
 * suit receives a +0.15 weight boost (homeostasis principle).
 * The current Wuku name determines the weekly resonance element;
 * its suit receives a +0.10 weight boost.
 */
export function getWeightedRandomCard(pangarasan: string, wuku: string): number {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);

	// 1. Homeostasis / Compensation: boost complementary element of user by +0.15
	const userElement = pangarasanToElement(pangarasan);
	if (userElement) {
		const [start, end] = getRemedialRange(userElement);
		for (let i = start; i <= end; i++) {
			weights[i] += 0.15;
		}
	}

	// 2. Resonance: boost current Wuku element by +0.10
	if (wuku) {
		const wukuElement = wukuToElement(wuku);
		if (wukuElement) {
			const [start, end] = getElementRange(wukuElement);
			for (let i = start; i <= end; i++) {
				weights[i] += 0.10;
			}
		}
	}

	// Sum weights
	let totalWeight = 0;
	for (let i = 0; i < DECK_SIZE; i++) {
		totalWeight += weights[i];
	}

	// Weighted pick
	let pick = Math.random() * totalWeight;
	for (let i = 0; i < DECK_SIZE; i++) {
		pick -= weights[i];
		if (pick <= 0) return i;
	}

	// Fallback (should never reach here)
	return DECK_SIZE - 1;
}

/**
 * Returns a weekly-deterministic card index (0-77) based on birthdate,
 * wuku (weekly cycle), and user pangarasan (elements).
 * It applies elements weighting but yields the same card for the same week.
 */
export function getWeeklyDeterministicCard(birthDate: string, wuku: string, pangarasan: string): number {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);

	const userElement = pangarasanToElement(pangarasan);
	if (userElement) {
		const [start, end] = getRemedialRange(userElement);
		for (let i = start; i <= end; i++) {
			weights[i] += 0.15;
		}
	}

	if (wuku) {
		const wukuElement = wukuToElement(wuku);
		if (wukuElement) {
			const [start, end] = getElementRange(wukuElement);
			for (let i = start; i <= end; i++) {
				weights[i] += 0.10;
			}
		}
	}

	let totalWeight = 0;
	for (let i = 0; i < DECK_SIZE; i++) {
		totalWeight += weights[i];
	}

	// Create a deterministic hash from birthDate + wuku
	let hash = 0;
	const seedStr = birthDate + wuku;
	for (let i = 0; i < seedStr.length; i++) {
		hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
	}
	
	const randVal = (Math.abs(hash) % 10000) / 10000;
	let pick = randVal * totalWeight;

	for (let i = 0; i < DECK_SIZE; i++) {
		pick -= weights[i];
		if (pick <= 0) return i;
	}
	return DECK_SIZE - 1;
}

/**
 * Returns a weekly-deterministic reversal state based on birthdate and wuku.
 */
export function getWeeklyDeterministicReversed(birthDate: string, wuku: string): boolean {
	let hash = 0;
	const seedStr = birthDate + wuku + 'reversed-seed';
	for (let i = 0; i < seedStr.length; i++) {
		hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
	}
	return Math.abs(hash) % 2 === 0;
}

// --- Unique Three-Card Spread ---

export interface DrawnCardInfo {
	cardIndex: number;
	isReversed: boolean;
	label: 'past' | 'present' | 'future';
}

function drawSingleDeterministicCard(seedStr: string, weights: Float64Array): number {
	let totalWeight = 0;
	for (let i = 0; i < DECK_SIZE; i++) {
		totalWeight += weights[i];
	}
	
	let hash = 0;
	for (let i = 0; i < seedStr.length; i++) {
		hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
	}
	
	const randVal = (Math.abs(hash) % 10000) / 10000;
	let pick = randVal * totalWeight;
	
	for (let i = 0; i < DECK_SIZE; i++) {
		if (weights[i] > 0) {
			pick -= weights[i];
			if (pick <= 0) {
				weights[i] = 0; // prevent redraw
				return i;
			}
		}
	}
	// Fallback if weights are somehow all 0
	for (let i = 0; i < DECK_SIZE; i++) {
		if (weights[i] > 0) {
			weights[i] = 0;
			return i;
		}
	}
	return DECK_SIZE - 1;
}

function getIsReversedDeterministic(seedStr: string): boolean {
	let hash = 0;
	for (let i = 0; i < seedStr.length; i++) {
		hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
	}
	return Math.abs(hash) % 2 === 0;
}

/**
 * Returns 3 unique deterministic cards representing Past, Present, and Future for Guest onboarding.
 */
export function getDeterministicThreeCards(birthDate: string, pangarasan?: string): DrawnCardInfo[] {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);

	if (pangarasan) {
		const userElement = pangarasanToElement(pangarasan);
		if (userElement) {
			const [start, end] = getRemedialRange(userElement);
			for (let i = start; i <= end; i++) {
				weights[i] += 0.15;
			}
		}
	}

	const pastIndex = drawSingleDeterministicCard(birthDate + '-past', weights);
	const pastReversed = getIsReversedDeterministic(birthDate + '-past-reversed');

	const presentIndex = drawSingleDeterministicCard(birthDate + '-present', weights);
	const presentReversed = getIsReversedDeterministic(birthDate + '-present-reversed');

	const futureIndex = drawSingleDeterministicCard(birthDate + '-future', weights);
	const futureReversed = getIsReversedDeterministic(birthDate + '-future-reversed');

	return [
		{ cardIndex: pastIndex, isReversed: pastReversed, label: 'past' },
		{ cardIndex: presentIndex, isReversed: presentReversed, label: 'present' },
		{ cardIndex: futureIndex, isReversed: futureReversed, label: 'future' }
	];
}

/**
 * Returns 3 unique deterministic cards for the current week's cycle (weekly dynamic).
 */
export function getWeeklyDeterministicThreeCards(birthDate: string, wuku: string, pangarasan: string): DrawnCardInfo[] {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);

	const userElement = pangarasanToElement(pangarasan);
	if (userElement) {
		const [start, end] = getRemedialRange(userElement);
		for (let i = start; i <= end; i++) {
			weights[i] += 0.15;
		}
	}

	if (wuku) {
		const wukuElement = wukuToElement(wuku);
		if (wukuElement) {
			const [start, end] = getElementRange(wukuElement);
			for (let i = start; i <= end; i++) {
				weights[i] += 0.10;
			}
		}
	}

	const pastIndex = drawSingleDeterministicCard(birthDate + wuku + '-past', weights);
	const pastReversed = getIsReversedDeterministic(birthDate + wuku + '-past-reversed');

	const presentIndex = drawSingleDeterministicCard(birthDate + wuku + '-present', weights);
	const presentReversed = getIsReversedDeterministic(birthDate + wuku + '-present-reversed');

	const futureIndex = drawSingleDeterministicCard(birthDate + wuku + '-future', weights);
	const futureReversed = getIsReversedDeterministic(birthDate + wuku + '-future-reversed');

	return [
		{ cardIndex: pastIndex, isReversed: pastReversed, label: 'past' },
		{ cardIndex: presentIndex, isReversed: presentReversed, label: 'present' },
		{ cardIndex: futureIndex, isReversed: futureReversed, label: 'future' }
	];
}
