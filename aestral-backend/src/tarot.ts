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
export function getDeterministicCard(birthDate: string): number {
	let hash = 0;
	for (let i = 0; i < birthDate.length; i++) {
		hash = birthDate.charCodeAt(i) + ((hash << 5) - hash);
	}
	return Math.abs(hash) % DECK_SIZE;
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
 * Returns a weighted-random card index (0-77).
 *
 * The user's Pangarasan determines their element; the complementary
 * suit receives a +0.15 weight boost (homeostasis principle).
 * Wuku is accepted for future use but does not affect weights yet.
 */
export function getWeightedRandomCard(pangarasan: string, _wuku: string): number {
	const weights = new Float64Array(DECK_SIZE).fill(1.0);

	const userElement = pangarasanToElement(pangarasan);
	if (userElement) {
		const [start, end] = getRemedialRange(userElement);
		for (let i = start; i <= end; i++) {
			weights[i] += 0.15;
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
