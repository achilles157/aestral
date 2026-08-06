import { SELF } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';
import {
	getMangsaTwoCards,
	getMomentCard,
	getThematicThreeCards,
	type BaziWeightingContext,
} from '../src/tarot';
import {
	buildTemplateKey,
	buildSynthesisPrompt,
	generateAllTemplates,
	generateTemplate,
	isSameStructure,
} from '../src/tarot-synthesis';

// ─── Phase 2B: Tarot Mangsa 2-kartu ──────────────────────────────────────────

describe('getMangsaTwoCards', () => {
	it('returns exactly 2 cards with energy & guidance labels', () => {
		const cards = getMangsaTwoCards('1995-10-25', 5, 'Geni Jaya');
		expect(cards).toHaveLength(2);
		expect(cards[0].label).toBe('energy');
		expect(cards[1].label).toBe('guidance');
	});

	it('is deterministic for the same input', () => {
		const a = getMangsaTwoCards('1995-10-25', 5, 'Geni Jaya');
		const b = getMangsaTwoCards('1995-10-25', 5, 'Geni Jaya');
		expect(a).toEqual(b);
	});

	it('returns unique card indexes within valid deck range', () => {
		const cards = getMangsaTwoCards('1995-10-25', 8);
		const idxs = cards.map((c) => c.cardIndex);
		expect(new Set(idxs).size).toBe(2);
		for (const card of cards) {
			expect(card.cardIndex).toBeGreaterThanOrEqual(0);
			expect(card.cardIndex).toBeLessThanOrEqual(77);
			expect(card.isReversed).toBeTypeOf('boolean');
		}
	});

	it('varies by mangsaId', () => {
		const a = getMangsaTwoCards('1995-10-25', 1);
		const b = getMangsaTwoCards('1995-10-25', 7);
		expect(a).not.toEqual(b);
	});
});

// ─── Phase 3A: Tarot Momen Kosmis ────────────────────────────────────────────

describe('getMomentCard', () => {
	const BAZI: BaziWeightingContext = {
		dayMasterElement: 'logam',
		dayMasterPolarity: 'yang',
		yongShen: ['air'],
		wuXingDominant: 'logam',
	};

	it('accepts all 4 event types and returns a single valid card', () => {
		for (const eventType of ['hari_weton', 'dino_was', 'bazi_clash', 'yong_shen'] as const) {
			const result = getMomentCard('1995-10-25', eventType, BAZI);
			expect(result.cardIndex).toBeGreaterThanOrEqual(0);
			expect(result.cardIndex).toBeLessThanOrEqual(77);
			expect(result.isReversed).toBeTypeOf('boolean');
			expect(result.eventType).toBe(eventType);
			expect(result.reasoning.length).toBeGreaterThan(0);
		}
	});

	it('returns different cards for different event types (weighted pools)', () => {
		const seen = new Set<string>();
		for (const eventType of ['hari_weton', 'dino_was', 'bazi_clash', 'yong_shen'] as const) {
			const result = getMomentCard('1995-10-25', eventType, BAZI);
			seen.add(`${eventType}:${result.cardIndex}`);
		}
		// Semua 4 event menghasilkan kombinasi yang berbeda (setidaknya beda index)
		expect(seen.size).toBe(4);
	});

	it('dino_was is deterministic and carries reflective reasoning', () => {
		const a = getMomentCard('1995-10-25', 'dino_was', BAZI);
		const b = getMomentCard('1995-10-25', 'dino_was', BAZI);
		expect(a).toEqual(b);
		expect(a.reasoning.some((r) => r.toLowerCase().includes('reflektif'))).toBe(true);
	});

	it('yong_shen carries yong shen reasoning and stays in valid range', () => {
		const result = getMomentCard('1995-10-25', 'yong_shen', BAZI);
		expect(result.cardIndex).toBeGreaterThanOrEqual(0);
		expect(result.cardIndex).toBeLessThanOrEqual(77);
		expect(result.reasoning.some((r) => r.toLowerCase().includes('yong shen'))).toBe(true);
	});
});

// ─── Phase 3B: Tarot Tematik ─────────────────────────────────────────────────

describe('getThematicThreeCards', () => {
	const BAZI: BaziWeightingContext = {
		dayMasterElement: 'kayu',
		dayMasterPolarity: 'yin',
		yongShen: ['air'],
		wuXingDominant: 'kayu',
	};

	it('supports all 5 areas with 3 unique cards each', () => {
		for (const area of ['karir', 'asmara', 'keuangan', 'spiritual', 'kesehatan'] as const) {
			const cards = getThematicThreeCards('1995-10-25', area, 'Geni Jaya', BAZI);
			expect(cards).toHaveLength(3);
			const idxs = cards.map((c) => c.cardIndex);
			expect(new Set(idxs).size).toBe(3);
			for (const card of cards) {
				expect(card.cardIndex).toBeGreaterThanOrEqual(0);
				expect(card.cardIndex).toBeLessThanOrEqual(77);
			}
		}
	});

	it('uses area-specific position labels', () => {
		const cards = getThematicThreeCards('1995-10-25', 'karir');
		expect(cards.map((c) => c.label)).toEqual(['potensi', 'tantangan', 'arah']);
	});

	it('is deterministic per day (same birthDate+area → same cards)', () => {
		const a = getThematicThreeCards('1995-10-25', 'asmara');
		const b = getThematicThreeCards('1995-10-25', 'asmara');
		expect(a).toEqual(b);
	});

	it('differs across areas for the same birthDate', () => {
		const karir = getThematicThreeCards('1995-10-25', 'karir');
		const kesehatan = getThematicThreeCards('1995-10-25', 'kesehatan');
		expect(karir).not.toEqual(kesehatan);
	});
});

// ─── Phase 2C: 3-layer AI caching (tarot-synthesis) ──────────────────────────

describe('buildTemplateKey', () => {
	it('normalizes card structure into a stable v2 key', () => {
		const cards = [
			{ cardIndex: 3, isReversed: false, label: 'past' },
			{ cardIndex: 22, isReversed: true, label: 'present' },
			{ cardIndex: 44, isReversed: false, label: 'future' },
		];
		const key = buildTemplateKey(cards);
		expect(key).toMatch(/^v2:template:/);
		expect(key).toContain('major');
		expect(key).toContain('cups');
		expect(key).toContain('wands');
	});

	it('produces same key for identical card arrays', () => {
		const a = [
			{ cardIndex: 1, isReversed: false, label: 'past' },
			{ cardIndex: 2, isReversed: true, label: 'present' },
		];
		const b = [
			{ cardIndex: 1, isReversed: false, label: 'past' },
			{ cardIndex: 2, isReversed: true, label: 'present' },
		];
		expect(buildTemplateKey(a)).toBe(buildTemplateKey(b));
	});

	it('key changes when reversed mask changes', () => {
		const a = [
			{ cardIndex: 1, isReversed: false, label: 'past' },
			{ cardIndex: 2, isReversed: true, label: 'present' },
		];
		const b = [
			{ cardIndex: 1, isReversed: false, label: 'past' },
			{ cardIndex: 2, isReversed: false, label: 'present' },
		];
		expect(buildTemplateKey(a)).not.toBe(buildTemplateKey(b));
	});
});

describe('buildSynthesisPrompt', () => {
	it('builds a compact prompt containing card labels', () => {
		const cards = [
			{ cardIndex: 3, isReversed: false, label: 'past' },
			{ cardIndex: 22, isReversed: true, label: 'present' },
			{ cardIndex: 44, isReversed: false, label: 'future' },
		];
		const template = generateTemplate({
			kind: 'birth',
			labels: ['past', 'present', 'future'],
			elements: ['major', 'cups', 'wands'],
		});
		const prompt = buildSynthesisPrompt(cards, template);
		expect(prompt).toContain('past');
		expect(prompt).toContain('present');
		expect(prompt).toContain('future');
		expect(prompt).toContain('[TEMPLATE]');
		expect(prompt.length).toBeLessThan(1200); // hemat token vs prompt penuh
	});
});

describe('isSameStructure', () => {
	it('detects equivalent structures (same key)', () => {
		const a = [
			{ cardIndex: 1, isReversed: false, label: 'past' },
			{ cardIndex: 2, isReversed: true, label: 'present' },
		];
		const b = [
			{ cardIndex: 1, isReversed: false, label: 'past' },
			{ cardIndex: 2, isReversed: true, label: 'present' },
		];
		expect(isSameStructure(a, b)).toBe(true);
	});

	it('detects different structures (different elements)', () => {
		const a = [
			{ cardIndex: 1, isReversed: false, label: 'past' },   // major
			{ cardIndex: 22, isReversed: true, label: 'present' }, // cups
		];
		const b = [
			{ cardIndex: 1, isReversed: false, label: 'past' },   // major
			{ cardIndex: 44, isReversed: true, label: 'present' }, // wands
		];
		expect(isSameStructure(a, b)).toBe(false);
	});
});

describe('generateTemplate & generateAllTemplates', () => {
	it('generates a template entry with all fields', () => {
		const tpl = generateTemplate({
			kind: 'birth',
			labels: ['past', 'present', 'future'],
			elements: ['major', 'cups', 'wands'],
		});
		expect(tpl.seedKey).toMatch(/^v2:template:/);
		expect(tpl.frame).toContain('{{synthesis}}');
		expect(tpl.label).toBeTypeOf('string');
	});

	it('generateAllTemplates returns the full pre-computed set', () => {
		const templates = generateAllTemplates();
		// 25 mangsa (5×5) + 125 birth (5×5×5) = 150
		expect(templates.size).toBe(150);
		for (const [key, value] of templates) {
			expect(key).toMatch(/^v2:template:/);
			const parsed = JSON.parse(value);
			expect(parsed.seedKey).toBe(key);
		}
	});
});

// ─── Integration: handler endpoints baru ─────────────────────────────────────

describe('POST /api/tarot/mangsa', () => {
	it('returns 2-card energy/guidance draw for valid input', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/mangsa', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				mangsaId: 5,
				pangarasan: 'Geni Jaya',
			}),
		});
		expect(res.status).toBe(200);
		const body = await res.json<{
			success: boolean;
			format: string;
			cards: Array<{ label: string; cardIndex: number }>;
		}>();
		expect(body.success).toBe(true);
		expect(body.format).toBe('energy_guidance');
		expect(body.cards).toHaveLength(2);
		expect(body.cards[0].label).toBe('energy');
		expect(body.cards[1].label).toBe('guidance');
	});

	it('returns 400 for invalid mangsaId', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/mangsa', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
			},
			body: JSON.stringify({ birthDate: '1995-10-25', mangsaId: 99 }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('mangsaId');
	});

	it('returns 400 without auth', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/mangsa', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ birthDate: '1995-10-25', mangsaId: 5 }),
		});
		expect(res.status).toBe(400);
	});
});

describe('POST /api/tarot/moment', () => {
	it('returns a single moment card for each event type', async () => {
		for (const eventType of ['hari_weton', 'dino_was', 'bazi_clash', 'yong_shen']) {
			const res = await SELF.fetch('http://localhost/api/tarot/moment', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: 'Guest test-user-123',
				},
				body: JSON.stringify({ birthDate: '1995-10-25', eventType }),
			});
			expect(res.status).toBe(200);
			const body = await res.json<{
				success: boolean;
				eventType: string;
				eventLabel: string;
				card: { cardIndex: number };
				reasoning: string[];
			}>();
			expect(body.success).toBe(true);
			expect(body.eventType).toBe(eventType);
			expect(body.eventLabel).toBeTruthy();
			expect(body.card.cardIndex).toBeGreaterThanOrEqual(0);
			expect(body.card.cardIndex).toBeLessThanOrEqual(77);
			// hari_weton & dino_was selalu punya reasoning tanpa bazi context;
			// bazi_clash & yong_shen butuh bazi context (bearer) untuk reasoning
			if (eventType === 'hari_weton' || eventType === 'dino_was') {
				expect(body.reasoning.length).toBeGreaterThan(0);
			}
		}
	});

	it('returns 400 for invalid eventType', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/moment', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
			},
			body: JSON.stringify({ birthDate: '1995-10-25', eventType: 'invalid_event' }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('eventType');
	});
});

describe('POST /api/tarot/thematic', () => {
	it('returns 3 cards with area labels for each area', async () => {
		for (const area of ['karir', 'asmara', 'keuangan', 'spiritual', 'kesehatan']) {
			const res = await SELF.fetch('http://localhost/api/tarot/thematic', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: 'Guest test-user-123',
				},
				body: JSON.stringify({ birthDate: '1995-10-25', area }),
			});
			expect(res.status).toBe(200);
			const body = await res.json<{
				success: boolean;
				area: string;
				areaLabel: string;
				cards: Array<{ cardIndex: number }>;
			}>();
			expect(body.success).toBe(true);
			expect(body.area).toBe(area);
			expect(body.areaLabel).toBeTruthy();
			expect(body.cards).toHaveLength(3);
		}
	});

	it('returns 400 for invalid area', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/thematic', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
			},
			body: JSON.stringify({ birthDate: '1995-10-25', area: 'harta' }),
		});
		expect(res.status).toBe(400);
	});

	it('returns 400 for userQuestion > 200 chars', async () => {
		const res = await SELF.fetch('http://localhost/api/tarot/thematic', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
			},
			body: JSON.stringify({
				birthDate: '1995-10-25',
				area: 'karir',
				userQuestion: 'x'.repeat(201),
			}),
		});
		expect(res.status).toBe(400);
	});
});

// ─── Integration: /api/chat prompt length (bug fix regression) ──────────────

describe('POST /api/chat prompt length', () => {
	it('accepts prompts up to 4000 chars (SeasonalSynthesisCard regression)', async () => {
		// SeasonalSynthesisCard mengirim prompt panjang ~1500-3000 char
		const longPrompt = 'Sintesis kosmis musiman.\n\n'.repeat(60); // ~1800 chars
		const res = await SELF.fetch('http://localhost/api/chat', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
				'CF-Connecting-IP': '203.0.113.77', // unique IP — avoid rate limit
			},
			body: JSON.stringify({ prompt: longPrompt }),
		});
		// Kalau GEMINI_API_KEY belum diset di test env, harusnya 503 (AI not configured),
		// BUKAN 400 (prompt too long) — itu yang membuktikan limit sudah naik.
		expect([200, 503, 500]).toContain(res.status);
	}, 45_000);

	it('rejects prompts over 4000 chars', async () => {
		const res = await SELF.fetch('http://localhost/api/chat', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				Authorization: 'Guest test-user-123',
				'CF-Connecting-IP': '203.0.113.78',
			},
			body: JSON.stringify({ prompt: 'x'.repeat(4001) }),
		});
		expect(res.status).toBe(400);
		const body = await res.json<{ error: string }>();
		expect(body.error).toContain('4000');
	});
});
