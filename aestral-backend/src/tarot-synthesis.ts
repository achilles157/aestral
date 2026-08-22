/**
 * Tarot synthesis template engine — Phase 2C 3-layer AI caching.
 *
 * Layer 1 (Flutter local): Card names, meanings, keywords — in deck assets.
 * Layer 2 (KV templates): Pre-generated synthesis frames per card-element combo.
 * Layer 3 (Gemini assembly): Compact prompt with template + cards only.
 *
 * The template key is built from stable card metadata so that identical
 * draws hitting the same spread format will return a cached synthesis
 * without calling Gemini, saving ~65% tokens and the full quota overhead.
 */

// ─── Types ─────────────────────────────────────────────────────────────────

export interface SynthesisCardInput {
	cardIndex: number;
	isReversed: boolean;
	label: string; // 'energy' | 'guidance' | 'past' | 'present' | 'future'
	nameId?: string; // identitas kartu stabil untuk cache key
}

export interface SynthesisTemplate {
	/** Human-readable summary of what this template covers */
	label: string;
	/** Template text with {{PLACEHOLDER}} slots for Gemini to fill */
	frame: string;
	/** Stable hash seed used to build the KV key */
	seedKey: string;
}

export interface SynthesisCacheEntry {
	/** Gemini response, pre-parsed into narrative + synthesis chunks */
	cardReadings: Array<{ label: string; narrative: string }>;
	synthesis: string;
	/** Unix timestamp ms when this cache entry was created */
	cachedAt: number;
}

// ─── Element & Archetype Encoding ─────────────────────────────────────────

/** Returns the Tarot element for a card index */
function cardElement(idx: number): string {
	if (idx <= 21) return 'major';      // Major Arcana
	if (idx <= 35) return 'cups';       // Water
	if (idx <= 49) return 'wands';      // Fire
	if (idx <= 63) return 'swords';     // Air
	return 'pentacles';                 // Earth
}

/**
 * Builds a deterministic template key from card structure.
 *
 * Key format:  v3:spread:{kind}:{elem_seq}:reversed_mask
 * Example:     v3:spread:mangsa:cups-wands:01
 *
 * v3: label-aware narratives (per-label cardReadings) — invalidates v2 entries
 * yang menyimpan duplikat konklusi untuk spread tematik.
 * This key is stable across redeploys — same cards + orientation = same template.
 * The generated KV key adds a version prefix so templates can be invalidated.
 */
export function buildTemplateKey(cards: SynthesisCardInput[], area?: string): string {
	const elements = cards.map((c) => cardElement(c.cardIndex)).join('-');
	const reversedMask = cards.map((c) => (c.isReversed ? '1' : '0')).join('');
	const kind = cards.map((c) => c.label).sort().join('-'); // stable regardless of array order
	const ids = cards.map((c) => c.nameId ?? `idx${c.cardIndex}`).join('|');
	const areaPart = area ? `:${area}` : '';
	return `v4:template:${kind}:${elements}:${reversedMask}:${ids}${areaPart}`;
}

/**
 * Constructs a lightweight prompt for Gemini that uses ~65% fewer tokens
 * than the full tarot_reading_prompt approach. Relies on pre-cached
 * system instruction in the Gemini model's context.
 */
export function buildSynthesisPrompt(
	cards: SynthesisCardInput[],
	template: SynthesisTemplate,
): string {
	const cardLines = cards.map((c, i) => {
		const orientation = c.isReversed ? 'TERBALIK' : 'TEGAK';
		return `Kartu ${i + 1} (label:${c.label}, idx:${c.cardIndex}, ${orientation})`;
	});

	return [
		`[TEMPLATE]: ${template.frame}`,
		'',
		`[KARTU]:`,
		...cardLines,
		'',
		'[INSTRUKSI]:',
		'Isi placeholder di template dengan narasi 1-2 paragraf hangat per kartu.',
		'Kembalikan JSON: {"cardReadings":[{"label":"...","narrative":"..."}],"synthesis":"..."}',
		'Bahasa Indonesia, gaya personal, Barnum light. JANGAN tulis "masa_lalu/masa_kini/masa_depan" sebagai key — pakai label asli dari Kartu.',
	].join('\n');
}

/**
 * Determines whether two card arrays are structurally equivalent for caching.
 * Cares only about: card elements + reversed mask + label set.
 */
export function isSameStructure(
	a: SynthesisCardInput[],
	b: SynthesisCardInput[],
): boolean {
	if (a.length !== b.length) return false;
	return buildTemplateKey(a) === buildTemplateKey(b);
}

/**
 * Generates a seed key for a card spread. Used by the build script
 * to pre-compute template KV entries for common combinations.
 */
export function generateSeedKey(cards: SynthesisCardInput[]): string {
	return buildTemplateKey(cards);
}

// ─── Template Generator (used by build script) ────────────────────────────

const ELEMENTS = ['major', 'cups', 'wands', 'swords', 'pentacles'] as const;

const MANGSA_TEMPLATE_FRAME = [
	'Kartu Energi ({energy_elem}) menunjukkan suasana periode ini.',
	'Maknanya untuk {{label_energy}}: {{energy_meaning}}.',
	'Kartu Panduan ({guidance_elem}) menunjukkan arah yang perlu diperhatikan.',
	'Maknanya: {{guidance_meaning}}.',
	'Kesimpulan: {{synthesis}}',
].join(' ');

const BIRTH_TEMPLATE_FRAME = [
	'Masa Lalu ({past_elem}) menunjukkan pola yang membentukmu: {{meaning_past}}.',
	'Masa Kini ({present_elem}) menunjukkan apa yang sedang kamu hadapi: {{meaning_present}}.',
	'Masa Depan ({future_elem}) menunjukkan kemungkinan yang bisa kamu pilih: {{meaning_future}}.',
	'Konklusi: {{synthesis}}',
].join(' ');

export interface TemplateGenInput {
	kind: 'mangsa' | 'birth' | 'custom';
	labels: string[];
	elements: string[];
}

export function generateTemplate(input: TemplateGenInput): SynthesisTemplate {
	const elemParts = input.labels.map((l, i) => `{${l}_elem}`).join('-');

	let frame: string;
	let label: string;

	if (input.kind === 'mangsa') {
		frame = MANGSA_TEMPLATE_FRAME;
		label = `Mangsa ${elemParts}`;
	} else if (input.kind === 'birth') {
		frame = BIRTH_TEMPLATE_FRAME;
		label = `Birth ${elemParts}`;
	} else {
		frame = input.labels
			.map((l) => `${l} ({{${l}_elem}}): {{meaning_${l}}}`)
			.join(' | ') + ' | Konklusi: {{synthesis}}';
		label = `Custom ${elemParts}`;
	}

	const seedKey = `v3:template:${input.kind}:${input.elements.join('-')}:00`;

	return { label, frame, seedKey };
}

/**
 * Pre-generate the most common templates for build-time KV population.
 * Returns a Map of KV key → value (JSON string).
 */
export function generateAllTemplates(): Map<string, string> {
	const entries = new Map<string, string>();

	// Mangsa: energy + guidance (2 cards, 5×5 = 25 combos)
	for (const e of ELEMENTS) {
		for (const g of ELEMENTS) {
			const tpl = generateTemplate({
				kind: 'mangsa',
				labels: ['energy', 'guidance'],
				elements: [e, g],
			});
			entries.set(tpl.seedKey, JSON.stringify(tpl));
		}
	}

	// Birth: past + present + future (3 cards, 5×5×5 = 125 combos)
	for (const p of ELEMENTS) {
		for (const pr of ELEMENTS) {
			for (const f of ELEMENTS) {
				const tpl = generateTemplate({
					kind: 'birth',
					labels: ['past', 'present', 'future'],
					elements: [p, pr, f],
				});
				entries.set(tpl.seedKey, JSON.stringify(tpl));
			}
		}
	}

	return entries;
}
